// Docking-first intercept workflow for Space Station One - all burns via maneuver nodes.
// Sequence: plane align -> phase align -> transfer burn -> encounter trim -> velocity match.

parameter interceptMode is "DOCK".

clearscreen.

set maxWaitTime to 21600.
set phaseMaxWaitTime to 43200.
set maxCommandWarp to 4.
set statusSlowInterval to 1.
set statusFastInterval to 0.2.
set alignTolerance to 1.
set alignSettleTime to 0.6.
set maxAlignWaitTime to 120.

set planeToleranceDeg to 0.2.
set nodeWarpExitEta to 120.
set nodeBurnLeadTime to 12.
set nodeImmediateLead to 30.
set minPlaneDv to 0.2.
set maxPlaneDv to 120.

set phaseTolerance to 0.35.
set finePhaseTolerance to 0.08.
set slowWarpPhaseError to 4.
set phaseLockMaxWait to 180.
set phaseHugeEta to 1800.
set phaseNudgeDv to 8.
set phaseNudgeMinError to 2.
set phaseNudgeCooldown to 120.
set phaseMaxNudges to 4.
set phaseVerySlowRate to 0.0002.

// Fixed display row assignments.
set rowBurnCountdown to 8.
set rowBurnStatus to 9.
set phaseStatusRow to 11.
set phaseNudgeRow to 12.
set rowNodeWarp to 14.
set rowBurnLead to 15.
set rowCoastStatus to 17.
set rowEncounterTrim to 18.
set rowVelocityMatchWait to 20.
set rowVelocityMatchBurn to 21.

set burnScale to 1.06.
set coarseThrottleDelta to 5.
set fineThrottleDelta to 1.

set encounterWarpExitDistance to 100000.
set encounterTrimDistance to 80000.
set encounterTrimScale to 0.45.
set encounterTrimMaxDv to 10.

set doVelocityMatch to true.
set matchCloseApproachDistance to 5000.
set matchHighSpeedThreshold to 50.
set matchMediumSpeedThreshold to 5.
set matchHighSpeedThrottle to 1.
set matchMediumSpeedThrottle to 0.2.
set matchLowSpeedThrottle to 0.05.
set matchTargetRelativeSpeed to 0.05.
set matchAlignTolerance to 2.
set matchFreezeSteeringSpeed to 2.

set abortRequested to false.
set abortReason to "".

if interceptMode = "INTERCEPT" or interceptMode = "intercept" {
    set doVelocityMatch to false.
    set phaseTolerance to 0.6.
    set finePhaseTolerance to 0.2.
    set burnScale to 1.0.
    set encounterTrimScale to 0.3.
    set encounterTrimMaxDv to 6.
    set matchTargetRelativeSpeed to 0.1.
}.

function normalize_angle {
    parameter angleDeg.
    until angleDeg >= 0 { set angleDeg to angleDeg + 360. }.
    until angleDeg < 360 { set angleDeg to angleDeg - 360. }.
    return angleDeg.
}.

function shortest_angle_diff {
    parameter fromDeg, toDeg.
    local delta is normalize_angle(toDeg - fromDeg).
    if delta > 180 { set delta to delta - 360. }.
    return delta.
}.

function clamp {
    parameter value, minValue, maxValue.
    if value < minValue { return minValue. }.
    if value > maxValue { return maxValue. }.
    return value.
}.

function set_warp_limited {
    parameter requestedWarp.
    set warp to clamp(requestedWarp, 0, maxCommandWarp).
}.

function force_warp_idle {
    set_warp_limited(0).
    wait 0.1.
    set_warp_limited(1).
}.

function current_longitude {
    return normalize_angle(ship:orbit:lan + ship:orbit:argumentofperiapsis + ship:orbit:trueanomaly).
}.

function current_phase_angle {
    local shipLongitude is current_longitude().
    local targetLongitude is normalize_angle(target:orbit:lan + target:orbit:argumentofperiapsis + target:orbit:trueanomaly).
    return normalize_angle(targetLongitude - shipLongitude).
}.

function eta_to_longitude {
    parameter targetLongitude.
    local aheadAngle is normalize_angle(targetLongitude - current_longitude()).
    return ship:orbit:period * (aheadAngle / 360).
}.

function phase_relative_rate {
    local shipRate is 360 / ship:orbit:period.
    local targetRate is 360 / target:orbit:period.
    return targetRate - shipRate.
}.

function eta_to_phase_window {
    parameter phaseError, relativeRate.
    local absRate is abs(relativeRate).
    if absRate < 0.000001 { return -1. }.
    if abs(phaseError) < 0.0001 { return 0. }.
    if phaseError * relativeRate > 0 { return abs(phaseError) / absRate. }.
    return (360 - abs(phaseError)) / absRate.
}.

function cleanup_and_exit {
    parameter message.
    if not abortRequested { set abortReason to message. }.
    set abortRequested to true.
    print message.
    force_warp_idle().
    lock throttle to 0.
    unlock steering.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
    print "intercept3 abort cleanup complete.".
    return.
}.

// Unified maneuver node executor.
// dvAxis: "PROGRADE", "RETROGRADE", "NORMAL", "ANTINORMAL"
// nd must already be created with add() before calling.
// Warp to burn window, align using fresh direction computed at burn position, burn for timed duration.
function execute_burn_node {
    parameter nd, dvAxis.

    local plannedDv is nd:deltav:mag.

    local accel is ship:availablethrust / ship:mass.
    if accel < 0.05 {
        remove nd.
        cleanup_and_exit("Insufficient thrust to execute " + dvAxis + " burn node.").
        return.
    }.
    local estBurnTime is plannedDv / accel.

    // Warp toward burn midpoint if node is far away.
    if nd:eta - estBurnTime / 2 > nodeWarpExitEta {
        set_warp_limited(4).
    }.
    until nd:eta - estBurnTime / 2 <= nodeWarpExitEta {
        print "Node warp | " + dvAxis + " | ETA: " + round(nd:eta, 1) + " s   " at (0, rowNodeWarp).
        wait statusSlowInterval.
    }.
    set_warp_limited(0).
    print "Warp exit | " + dvAxis + " node ETA: " + round(nd:eta, 1) + " s".

    // Recompute accel and burn time fresh at burn position.
    set accel to ship:availablethrust / ship:mass.
    local burnTime is plannedDv / accel.

    // Compute burn steering direction from fresh orbital state — no bare identifiers.
    local proDir is ship:velocity:orbit:normalized.
    local hVec is vcrs(ship:position - ship:body:position, ship:velocity:orbit).
    local normDir is hVec:normalized.

    local burnDir is proDir.
    if dvAxis = "RETROGRADE" {
        set burnDir to proDir * (-1).
    } else if dvAxis = "NORMAL" {
        set burnDir to normDir.
    } else if dvAxis = "ANTINORMAL" {
        set burnDir to normDir * (-1).
    }.

    // Align to burn vector.
    lock steering to burnDir.
    until nd:eta <= burnTime / 2 + nodeBurnLeadTime {
        print "Burn lead | " + dvAxis + " | ETA: " + round(nd:eta, 1) + " s   " at (0, rowBurnLead).
        wait 0.1.
    }.

    // Require stable pointing before ignition so each maneuver starts with correct orientation.
    local alignStart is time:seconds.
    local alignedSince is -1.
    until false {
        local alignError is vang(ship:facing:vector, burnDir).
        print "Align | " + dvAxis + " | Error: " + round(alignError, 2) + " deg   " at (0, rowBurnLead).

        if alignError < alignTolerance {
            if alignedSince < 0 {
                set alignedSince to time:seconds.
            }.

            if time:seconds - alignedSince >= alignSettleTime {
                break.
            }.
        } else {
            set alignedSince to -1.
        }.

        if time:seconds - alignStart > maxAlignWaitTime {
            remove nd.
            cleanup_and_exit("Alignment timeout before " + dvAxis + " maneuver burn.").
            return.
        }.

        wait 0.1.
    }.

    // Timed burn with throttle taper.
    print "Burning | " + dvAxis + " | " + round(plannedDv, 2) + " m/s est " + round(burnTime, 1) + " s      " at (0, rowBurnStatus).
    local burnStart is time:seconds.
    lock throttle to 1.
    until time:seconds - burnStart >= burnTime {
        local remain is burnTime - (time:seconds - burnStart).
        if remain < coarseThrottleDelta / accel {
            lock throttle to 0.2.
        }.
        if remain < fineThrottleDelta / accel {
            lock throttle to 0.05.
        }.
        print "Burn progress | Remaining: " + round(remain, 1) + " s   " at (0, rowBurnCountdown).
        wait 0.1.
    }.
    lock throttle to 0.
    unlock steering.
    remove nd.
}.

// Schedule and immediately execute a prograde/retrograde burn at current time + nodeImmediateLead.
function execute_immediate_proretro {
    parameter dvCommand.

    if abs(dvCommand) < 0.05 {
        print "Burn skipped: dV too small.".
        return.
    }.

    local dvAxis is "PROGRADE".
    local ndDv is dvCommand.
    if dvCommand < 0 {
        set dvAxis to "RETROGRADE".
        set ndDv to abs(dvCommand).
    }.

    local nd is node(time:seconds + nodeImmediateLead, 0, 0, ndDv).
    add nd.
    execute_burn_node(nd, dvAxis).
}.

function wait_for_phase_window {
    parameter targetPhase.
    set waitStart to time:seconds.
    set phaseError to shortest_angle_diff(current_phase_angle(), targetPhase).
    set phaseRate to phase_relative_rate().
    set etaToWindow to eta_to_phase_window(phaseError, phaseRate).
    set lastNudgeTime to -999.
    set nudgeCount to 0.

    print "Step: Phase align".
    unlock steering.

    set_warp_limited(3).
    until abs(phaseError) <= phaseTolerance {
        if time:seconds - waitStart > phaseMaxWaitTime {
            cleanup_and_exit("Timed out waiting for phase window.").
            return.
        }.

        if etaToWindow > 3600 {
            set_warp_limited(6).
        } else if etaToWindow > 1800 {
            set_warp_limited(5).
        } else if etaToWindow > 600 {
            set_warp_limited(4).
        } else if etaToWindow > 180 {
            set_warp_limited(3).
        } else if etaToWindow > 60 {
            set_warp_limited(2).
        } else if abs(phaseError) < slowWarpPhaseError {
            set_warp_limited(0).
        } else {
            set_warp_limited(1).
        }.

        if (etaToWindow < 0 or etaToWindow > phaseHugeEta or abs(phaseRate) < phaseVerySlowRate) and abs(phaseError) > phaseNudgeMinError and nudgeCount < phaseMaxNudges and time:seconds - lastNudgeTime > phaseNudgeCooldown {
            local nudgeDv is phaseNudgeDv.
            if phaseError < 0 { set nudgeDv to -phaseNudgeDv. }.
            set_warp_limited(0).
            print "Phase nudge " + (nudgeCount + 1) + "/" + phaseMaxNudges + ": " + round(nudgeDv, 2) + " m/s | Error: " + round(phaseError, 2) + " deg      " at (0, phaseNudgeRow).
            execute_immediate_proretro(nudgeDv).
            set nudgeCount to nudgeCount + 1.
            set lastNudgeTime to time:seconds.
            wait 1.
        }.

        if etaToWindow >= 0 {
            print "Waiting phase window | Error: " + round(phaseError, 2) + " deg | Drift: " + round(phaseRate, 4) + " deg/s | ETA: " + round(etaToWindow / 60, 1) + " min | Warp: " + warp + "      " at (0, phaseStatusRow).
        } else {
            print "Waiting phase window | Error: " + round(phaseError, 2) + " deg | Drift: " + round(phaseRate, 6) + " deg/s | ETA: estimating... | Warp: " + warp + "      " at (0, phaseStatusRow).
        }.

        wait statusSlowInterval.
        set phaseError to shortest_angle_diff(current_phase_angle(), targetPhase).
        set phaseRate to phase_relative_rate().
        set etaToWindow to eta_to_phase_window(phaseError, phaseRate).
    }.

    set_warp_limited(0).
    print "Coarse phase window reached.".

    set lockStart to time:seconds.
    until abs(phaseError) <= finePhaseTolerance {
        if time:seconds - lockStart > phaseLockMaxWait {
            print "Fine phase lock timed out; continuing with error " + round(phaseError, 3) + " deg".
            break.
        }.
        wait statusFastInterval.
        set phaseError to shortest_angle_diff(current_phase_angle(), targetPhase).
        print "Fine phase lock | Error: " + round(phaseError, 3) + " deg | Warp: " + warp + "      " at (0, phaseStatusRow).
    }.

    print "Phase lock complete | Error: " + round(phaseError, 3) + " deg".
}.

function do_plane_alignment {
    local relativeInclination is abs(shortest_angle_diff(ship:orbit:inclination, target:orbit:inclination)).

    print "Step: Plane align".
    print "Current relative inclination: " + round(relativeInclination, 3) + " deg".

    if relativeInclination <= planeToleranceDeg {
        print "Plane alignment already within tolerance.".
        return.
    }.

    local ascNodeLongitude is normalize_angle(target:orbit:lan).
    local descNodeLongitude is normalize_angle(target:orbit:lan + 180).
    local etaToAsc is eta_to_longitude(ascNodeLongitude).
    local etaToDesc is eta_to_longitude(descNodeLongitude).

    local chosenNode is "AN".
    local nodeEta is etaToAsc.
    if etaToDesc < etaToAsc {
        set chosenNode to "DN".
        set nodeEta to etaToDesc.
    }.

    local burnDirection is "NORMAL".
    if chosenNode = "AN" {
        if ship:orbit:inclination > target:orbit:inclination {
            set burnDirection to "ANTINORMAL".
        } else {
            set burnDirection to "NORMAL".
        }.
    } else {
        if ship:orbit:inclination > target:orbit:inclination {
            set burnDirection to "NORMAL".
        } else {
            set burnDirection to "ANTINORMAL".
        }.
    }.

    local relIncRad is relativeInclination * constant:pi / 180.
    local planeDv is 2 * ship:velocity:orbit:mag * sin(relIncRad / 2).
    set planeDv to clamp(planeDv, minPlaneDv, maxPlaneDv).

    print "Planned node: " + chosenNode + " | Eta: " + round(nodeEta, 1) + " s | Dir: " + burnDirection + " | dV: " + round(planeDv, 2) + " m/s".

    local normalDv is planeDv.
    if burnDirection = "ANTINORMAL" { set normalDv to -planeDv. }.
    local planeNode is node(time:seconds + nodeEta, 0, normalDv, 0).
    add planeNode.

    execute_burn_node(planeNode, burnDirection).
    if abortRequested { return. }.
    wait 2.

    set relativeInclination to abs(shortest_angle_diff(ship:orbit:inclination, target:orbit:inclination)).
    print "Plane alignment complete | Residual inclination: " + round(relativeInclination, 3) + " deg".
}.

function coast_to_intercept_and_trim {
    parameter targetPhase.

    print "Step: Coast and encounter trim".
    set_warp_limited(4).
    set coastStart to time:seconds.
    set lastDistance to (target:position - ship:position):mag.
    set currentDistance to lastDistance.
    set warpExitReason to "UNKNOWN".

    until false {
        if target:body:name <> ship:body:name {
            cleanup_and_exit("Target changed body during coast.").
            return.
        }.

        if time:seconds - coastStart > maxWaitTime {
            cleanup_and_exit("Timed out while coasting to encounter.").
            return.
        }.

        if currentDistance <= encounterWarpExitDistance {
            set warpExitReason to "RANGE_THRESHOLD".
            break.
        }.

        if currentDistance > lastDistance {
            set warpExitReason to "PASSED_CLOSEST_APPROACH".
            break.
        }.

        print "Coast status | Range: " + round(currentDistance, 0) + " m   " at (0, rowCoastStatus).
        wait statusSlowInterval.
        set lastDistance to currentDistance.
        set currentDistance to (target:position - ship:position):mag.
    }.

    set currentDistance to (target:position - ship:position):mag.
    set_warp_limited(0).
    print "Warp exit | Reason: " + warpExitReason + " | Range: " + round(currentDistance, 0) + " m".

    set trimWaitStart to time:seconds.
    set lastDistance to currentDistance.
    until currentDistance <= encounterTrimDistance or currentDistance > lastDistance {
        if time:seconds - trimWaitStart > maxWaitTime { break. }.
        wait 0.5.
        set lastDistance to currentDistance.
        set currentDistance to (target:position - ship:position):mag.
        print "Encounter trim wait | Range: " + round(currentDistance, 0) + " m   " at (0, rowEncounterTrim).
    }.

    set trimPhaseError to shortest_angle_diff(current_phase_angle(), targetPhase).
    set trimDv to clamp(-trimPhaseError * encounterTrimScale, -encounterTrimMaxDv, encounterTrimMaxDv).

    print "Encounter trim planned | Phase error: " + round(trimPhaseError, 3) + " deg | dV: " + round(trimDv, 2) + " m/s".
    execute_immediate_proretro(trimDv).
}.

function match_velocity_with_target {
    if ship:availablethrust <= 0 {
        cleanup_and_exit("No available thrust for velocity match.").
        return.
    }.

    print "Step: Velocity match".
    set targetVessel to target.
    set waitStart to time:seconds.
    set lastDistance to (targetVessel:position - ship:position):mag.

    until lastDistance < matchCloseApproachDistance {
        if time:seconds - waitStart > maxWaitTime {
            cleanup_and_exit("Timed out waiting for closest approach for match.").
            return.
        }.

        set currentDistance to (targetVessel:position - ship:position):mag.

        if currentDistance > lastDistance {
            print "Closest approach passed; starting match now.".
            break.
        }.

        print "Velocity match wait | Range: " + round(currentDistance, 0) + " m   " at (0, rowVelocityMatchWait).
        set lastDistance to currentDistance.
        wait 0.1.
    }.

    // Velocity match is a real-time feedback loop: relative retrograde varies during the burn.
    lock relativeVelocity to ship:velocity:orbit - targetVessel:velocity:orbit.
    lock steering to lookdirup(relativeVelocity * (-1), ship:up:vector).

    // Require orientation lock before starting the velocity-match burn.
    local matchAlignStart is time:seconds.
    until vang(ship:facing:vector, relativeVelocity * (-1)) < matchAlignTolerance {
        print "Match align | Error: " + round(vang(ship:facing:vector, relativeVelocity * (-1)), 2) + " deg   " at (0, rowVelocityMatchBurn).

        if time:seconds - matchAlignStart > maxAlignWaitTime {
            cleanup_and_exit("Alignment timeout before velocity match burn.").
            return.
        }.

        wait 0.1.
    }.

    local steeringFrozen to false.
    until relativeVelocity:mag < matchTargetRelativeSpeed {
        if relativeVelocity:mag > matchFreezeSteeringSpeed {
            if steeringFrozen {
                lock steering to lookdirup(relativeVelocity * (-1), ship:up:vector).
                set steeringFrozen to false.
            }.
        } else {
            if not steeringFrozen {
                local frozenDir is ship:facing.
                lock steering to frozenDir.
                set steeringFrozen to true.
            }.
        }.

        if relativeVelocity:mag > matchHighSpeedThreshold {
            lock throttle to matchHighSpeedThrottle.
        } else if relativeVelocity:mag > matchMediumSpeedThreshold {
            lock throttle to matchMediumSpeedThrottle.
        } else {
            lock throttle to matchLowSpeedThrottle.
        }.

        print "Velocity match | Relative speed: " + round(relativeVelocity:mag, 2) + " m/s   " at (0, rowVelocityMatchBurn).
        wait 0.1.
    }.

    lock throttle to 0.
    unlock steering.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
    print "Velocity match complete.".
}.

function run_intercept3_workflow {
    // Compute transfer geometry first so we can compare AN/DN timing against the phase window.
    set mu to ship:body:mu.
    set shipRadius to ship:orbit:semimajoraxis.
    set targetRadius to target:orbit:semimajoraxis.

    set transferSemiMajorAxis to (shipRadius + targetRadius) / 2.
    set transferTime to constant:pi * sqrt(transferSemiMajorAxis^3 / mu).
    set targetAngularVelocity to sqrt(mu / targetRadius^3).
    set targetDegreesDuringTransfer to (targetAngularVelocity * transferTime) * (180 / constant:pi).
    set targetPhaseGoal to normalize_angle(180 - targetDegreesDuringTransfer).

    print "Step: Transfer planning".
    print "Transfer time: " + round(transferTime, 1) + " s | Target phase: " + round(targetPhaseGoal, 3) + " deg".

    // Plane alignment decision: only correct plane if the nearest AN/DN arrives before the phase window.
    local relativeInclination is abs(shortest_angle_diff(ship:orbit:inclination, target:orbit:inclination)).
    if relativeInclination > planeToleranceDeg {
        local initPhaseError is shortest_angle_diff(current_phase_angle(), targetPhaseGoal).
        local initPhaseRate is phase_relative_rate().
        local etaPhaseWindow is eta_to_phase_window(initPhaseError, initPhaseRate).
        local etaToAsc is eta_to_longitude(normalize_angle(target:orbit:lan)).
        local etaToDesc is eta_to_longitude(normalize_angle(target:orbit:lan + 180)).
        local etaNode is min(etaToAsc, etaToDesc).

        if etaPhaseWindow > 0 and etaNode >= etaPhaseWindow {
            print "Plane align deferred: phase window in " + round(etaPhaseWindow / 60, 1) + " min arrives before nearest node in " + round(etaNode / 60, 1) + " min.".
            print "Residual inclination: " + round(relativeInclination, 3) + " deg (will correct on a later pass if needed).".
        } else {
            print "Plane align: nearest node in " + round(etaNode / 60, 1) + " min, phase window in " + round(etaPhaseWindow / 60, 1) + " min -> correcting now.".
            do_plane_alignment().
            if abortRequested { return. }.
        }.
    }.

    wait_for_phase_window(targetPhaseGoal).
    if abortRequested { return. }.

    set circularVelocity to sqrt(mu / shipRadius).
    set transferVelocity to sqrt(mu * (2 / shipRadius - 1 / transferSemiMajorAxis)).
    set transferDv to (transferVelocity - circularVelocity) * burnScale.

    print "Step: Transfer burn".
    print "Planned transfer dV: " + round(transferDv, 2) + " m/s".
    execute_immediate_proretro(transferDv).
    if abortRequested { return. }.

    coast_to_intercept_and_trim(targetPhaseGoal).
    if abortRequested { return. }.

    if doVelocityMatch {
        match_velocity_with_target().
    } else {
        print "INTERCEPT mode: skipping velocity match.".
    }.
}.

sas off.

if not hastarget {
    cleanup_and_exit("CRITICAL: No target selected.").
}.

if target:body:name <> ship:body:name {
    cleanup_and_exit("CRITICAL: Target is not around the same body.").
}.

print "intercept3 start | Mode: " + interceptMode.
print "Target: " + target:name + " | Body: " + ship:body:name.
if ship:availablethrust <= 0 {
    print "Startup note: available thrust is currently zero; script will continue and validate thrust at burn steps.".
}.

if not abortRequested {
    run_intercept3_workflow().
}.

lock throttle to 0.
unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.
force_warp_idle().
if abortRequested {
    print "intercept3 aborted: " + abortReason.
} else {
    print "intercept3 workflow complete.".
}.
