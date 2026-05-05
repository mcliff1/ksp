// Creates a transfer-orbit maneuver node toward the currently selected target.
// Assumes a target is already selected.
// This script sets up and executes an intercepting transfer maneuver.

set clearExistingNodes to true.
set minDvThreshold to 0.5.
set executeManeuver to true.
set coarseBurnThreshold to 5.
set fineBurnThreshold to 0.5.
set safePeriapsisAltitude to 75000.
set maxWindowOrbits to 10.
set phaseWindowTolerance to 3.
set enableRefinement to true.
set refineDvPerDegree to 0.6.
set maxRefineDv to 20.
set minRefineDv to 0.5.
set enablePlaneMatch to false.
set minPlaneMatchInc to 0.2.
set maxPlaneMatchDv to 10.
set maxRefinementPasses to 4.
set minRefineWait to 60.
set finalCoastSampleStep to 10.
set interceptDistanceThreshold to 20000.
set maxTransferDv to 1200.
set maxBurnFractionOfEscape to 0.95.

set interceptAtApoapsis to true.

function clamp {
    parameter value, low, high.
    if value < low {
        return low.
    }.
    if value > high {
        return high.
    }.
    return value.
}.

function ensure_target {
    if not hastarget {
        print "No target selected. Set a target and run again.".
        return false.
    }.
    return true.
}.

function clear_nodes {
    until not hasnode {
        remove nextnode.
        wait 0.
    }.
}.

function normalize_angle {
    parameter angleDeg.

    until angleDeg >= 0 {
        set angleDeg to angleDeg + 360.
    }.

    until angleDeg < 360 {
        set angleDeg to angleDeg - 360.
    }.

    return angleDeg.
}.

function shortest_angle_diff {
    parameter fromDeg, toDeg.
    local d is normalize_angle(toDeg - fromDeg).

    if d > 180 {
        set d to d - 360.
    }.

    return d.
}.

function execute_directional_burn {
    parameter directionName, dvCommand, burnLabel.
    local accel is 0.
    local burnTime is 0.
    local orbitalNormal is vcrs(ship:velocity:orbit, ship:position):normalized.
    local orbitalAntiNormal is orbitalNormal * -1.

    if abs(dvCommand) < 0.01 {
        print burnLabel + ": dV too small, skipping.".
        return false.
    }.

    if directionName = "PROGRADE" {
        lock steering to prograde.
    } else if directionName = "RETROGRADE" {
        lock steering to retrograde.
    } else if directionName = "NORMAL" {
        lock steering to orbitalNormal.
    } else {
        lock steering to orbitalAntiNormal.
    }.

    set accel to ship:availablethrust / max(ship:mass, 0.01).
    set burnTime to abs(dvCommand) / max(accel, 0.01).

    print burnLabel + ": " + directionName + " burn for " + round(abs(dvCommand), 2) + " m/s (" + round(burnTime, 2) + " s).".

    lock throttle to 1.
    wait burnTime.
    lock throttle to 0.

    unlock steering.
    unlock throttle.
    return true.
}.

function match_planes {
    local relInc is abs(ship:orbit:inclination - target:orbit:inclination).
    local mu is ship:body:mu.
    local shipA is ship:orbit:semimajoraxis.
    local currentRadius is ship:body:radius + ship:altitude.
    local vNow is 0.
    local dvPlane is 0.
    local directionName is "NORMAL".

    if not enablePlaneMatch {
        return false.
    }.

    print "Relative inclination: " + round(relInc, 3) + " deg".

    if relInc < minPlaneMatchInc {
        print "Plane match not required.".
        return true.
    }.

    set vNow to sqrt(mu * (2 / currentRadius - 1 / shipA)).
    // Small-angle approximation for inexpensive pre-transfer plane trim.
    set dvPlane to vNow * relInc * 0.01745329252.
    set dvPlane to clamp(dvPlane, 0, maxPlaneMatchDv).

    if ship:orbit:inclination > target:orbit:inclination {
        set directionName to "ANTINORMAL".
    }.

    print "Executing pre-transfer plane match.".
    execute_directional_burn(directionName, dvPlane, "Plane match").
    return true.
}.

function build_intercept_node {
    local mu is ship:body:mu.
    local shipA is ship:orbit:semimajoraxis.
    local targetA is target:orbit:semimajoraxis.
    local plannedTargetA is targetA.
    local safeRadius is 0.
    local burnRadius is 0.
    local burnBaseEta is 0.
    local burnUT is 0.
    local transferA is 0.
    local transferTime is 0.
    local targetMeanMotion is 0.
    local shipMeanMotion is 0.
    local relativeRate is 0.
    local requiredAhead is 0.
    local currentAhead is 0.
    local candidateEta is 0.
    local predictedAhead is 0.
    local phaseError is 0.
    local bestEta is -1.
    local bestError is 999.
    local bestK is 0.
    local k is 0.
    local vNow is 0.
    local vTransfer is 0.
    local vEscape is 0.
    local vPostBurn is 0.
    local dv is 0.

    if target:body:name <> ship:body:name {
        print "Target is not orbiting the same body. Current body: " + ship:body:name + ".".
        return false.
    }.

    if abs(targetA - shipA) < 1000 {
        print "Target orbit is already very close to current orbit.".
        print "Use a phasing or plane-match script for final rendezvous.".
        return false.
    }.

    set safeRadius to ship:body:radius + safePeriapsisAltitude.

    // If target orbit is higher, burn prograde at periapsis to raise apoapsis.
    if targetA > shipA {
        set interceptAtApoapsis to true.
        set burnRadius to ship:orbit:periapsis.
        set burnBaseEta to eta:periapsis.
    } else {
        // If target orbit is lower, burn retrograde at apoapsis to lower periapsis.
        set interceptAtApoapsis to false.
        set burnRadius to ship:orbit:apoapsis.
        set burnBaseEta to eta:apoapsis.

        if targetA < safeRadius {
            set plannedTargetA to safeRadius.
            print "Target orbit is below safe periapsis altitude.".
            print "Using safe phasing transfer with periapsis altitude " + safePeriapsisAltitude + " m.".
        }.
    }.

    set transferA to (burnRadius + plannedTargetA) / 2.
    set transferTime to 3.14159265359 * sqrt(transferA * transferA * transferA / mu).
    set targetMeanMotion to 360 / target:orbit:period.
    set shipMeanMotion to 360 / ship:orbit:period.
    set relativeRate to targetMeanMotion - shipMeanMotion.
    set requiredAhead to normalize_angle(180 - (targetMeanMotion * transferTime)).
    set currentAhead to normalize_angle(target:orbit:trueanomaly - ship:orbit:trueanomaly).

    if abs(relativeRate) < 0.00001 {
        print "Relative phase rate is too small; cannot solve transfer timing.".
        return false.
    }.

    until k > maxWindowOrbits {
        set candidateEta to burnBaseEta + (k * ship:orbit:period).
        set predictedAhead to normalize_angle(currentAhead + (relativeRate * candidateEta)).
        set phaseError to abs(shortest_angle_diff(predictedAhead, requiredAhead)).

        if phaseError < bestError {
            set bestError to phaseError.
            set bestEta to candidateEta.
            set bestK to k.
        }.

        set k to k + 1.
    }.

    if bestEta < 0 {
        print "Failed to find a valid transfer window candidate.".
        return false.
    }.

    set burnUT to time:seconds + bestEta.

    // Vis-viva equation at burn point.
    set vNow to sqrt(mu * (2 / burnRadius - 1 / shipA)).
    set vTransfer to sqrt(mu * (2 / burnRadius - 1 / transferA)).
    set dv to vTransfer - vNow.

    if abs(dv) > maxTransferDv {
        print "Computed transfer dV (" + round(dv, 1) + " m/s) exceeds safety limit (" + maxTransferDv + " m/s).".
        print "Aborting node creation; adjust target/profile before retry.".
        return false.
    }.

    set vEscape to sqrt(2 * mu / burnRadius).
    set vPostBurn to vNow + dv.
    if vPostBurn >= vEscape * maxBurnFractionOfEscape {
        set dv to (vEscape * maxBurnFractionOfEscape) - vNow.
        print "Safety clamp applied to avoid escape trajectory.".
        print "Clamped transfer dV: " + round(dv, 1) + " m/s".
    }.

    if abs(dv) < minDvThreshold {
        print "Computed dV is too small (" + round(dv, 2) + " m/s). No node created.".
        return false.
    }.

    if clearExistingNodes {
        clear_nodes().
    }.

    add node(burnUT, 0, 0, dv).

    print "Intercept transfer node created.".
    print "Target: " + target:name + " around " + ship:body:name + ".".
    print "Burn in: " + round(bestEta, 1) + " s (apsis pass + " + bestK + " orbit(s)).".
    print "Prograde dV: " + round(dv, 1) + " m/s".
    print "Transfer orbit SMA target: " + round(plannedTargetA, 1) + " m".
    print "Transfer time: " + round(transferTime / 60, 1) + " min".
    print "Phase error at planned burn: " + round(bestError, 2) + " deg".

    if bestError > phaseWindowTolerance {
        print "Warning: phase error is above tolerance (" + phaseWindowTolerance + " deg).".
    }.

    return true.
}.

function execute_next_node {
    local dvMag is 0.
    local burnTime is 0.
    local burnLead is 0.
    local accel is 0.
    local warpUT is 0.

    if not hasnode {
        print "No maneuver node available to execute.".
        return false.
    }.

    set dvMag to nextnode:deltav:mag.
    set accel to ship:availablethrust / max(ship:mass, 0.01).
    set burnTime to dvMag / max(accel, 0.01).
    set burnLead to burnTime / 2.

    print "Preparing maneuver execution.".
    print "Estimated burn time: " + round(burnTime, 1) + " s".

    lock steering to nextnode:burnvector.
    lock throttle to 0.

    if nextnode:eta > burnLead + 45 {
        print "Warping to burn lead-in.".
        set warpUT to time:seconds + nextnode:eta - burnLead - 20.
        warpto(warpUT).
    }.

    wait until nextnode:eta <= burnLead.
    print "Starting maneuver burn.".

    lock throttle to 1.
    until nextnode:deltav:mag <= coarseBurnThreshold {
        wait 0.1.
    }.

    lock throttle to 0.25.
    until nextnode:deltav:mag <= fineBurnThreshold {
        wait 0.1.
    }.

    lock throttle to 0.
    remove nextnode.
    unlock steering.
    unlock throttle.

    print "Maneuver complete.".
    return true.
}.

function refine_intercept {
    local encounterEta is 0.
    local refineEta is 0.
    local remainingEta is 0.
    local targetMeanMotion is 0.
    local requiredAhead is 0.
    local currentAhead is 0.
    local phaseError is 0.
    local refineDv is 0.
    local passCount is 0.
    local directionName is "PROGRADE".
    local closestDistance is target:distance.
    local sampledDistance is 0.

    if not enableRefinement {
        return false.
    }.

    if interceptAtApoapsis {
        set encounterEta to eta:apoapsis.
    } else {
        set encounterEta to eta:periapsis.
    }.

    if encounterEta < 180 {
        print "Refinement skipped: encounter is too soon.".
        return false.
    }.

    print "Starting iterative intercept refinement...".

    until passCount >= maxRefinementPasses {
        if interceptAtApoapsis {
            set remainingEta to eta:apoapsis.
        } else {
            set remainingEta to eta:periapsis.
        }.

        if remainingEta < minRefineWait {
            print "Refinement loop ending: encounter is too close.".
            break.
        }.

        set refineEta to max(minRefineWait, remainingEta * 0.45).
        print "Refinement pass " + (passCount + 1) + " in " + round(refineEta, 1) + " s.".
        wait refineEta.

        if interceptAtApoapsis {
            set remainingEta to eta:apoapsis.
        } else {
            set remainingEta to eta:periapsis.
        }.

        set targetMeanMotion to 360 / target:orbit:period.
        set requiredAhead to normalize_angle(180 - (targetMeanMotion * remainingEta)).
        set currentAhead to normalize_angle(target:orbit:trueanomaly - ship:orbit:trueanomaly).
        set phaseError to shortest_angle_diff(currentAhead, requiredAhead).

        // Negative phase error means target is too far ahead; speed up to catch up.
        set refineDv to clamp(-phaseError * refineDvPerDegree, -maxRefineDv, maxRefineDv).

        print "Pass " + (passCount + 1) + " phase error: " + round(phaseError, 2) + " deg".
        print "Pass " + (passCount + 1) + " dV command: " + round(refineDv, 2) + " m/s".

        if abs(refineDv) >= minRefineDv {
            if refineDv >= 0 {
                set directionName to "PROGRADE".
            } else {
                set directionName to "RETROGRADE".
            }.

            execute_directional_burn(directionName, refineDv, "Refinement pass " + (passCount + 1)).
        } else {
            print "Pass " + (passCount + 1) + ": correction below minimum threshold.".
        }.

        set sampledDistance to target:distance.
        if sampledDistance < closestDistance {
            set closestDistance to sampledDistance.
        }.

        set passCount to passCount + 1.
    }.

    print "Final coast monitoring for closest approach...".
    if interceptAtApoapsis {
        set remainingEta to eta:apoapsis.
    } else {
        set remainingEta to eta:periapsis.
    }.

    until remainingEta < 30 {
        set sampledDistance to target:distance.
        if sampledDistance < closestDistance {
            set closestDistance to sampledDistance.
        }.
        wait finalCoastSampleStep.

        if interceptAtApoapsis {
            set remainingEta to eta:apoapsis.
        } else {
            set remainingEta to eta:periapsis.
        }.
    }.

    print "Closest sampled approach distance: " + round(closestDistance, 1) + " m".
    if closestDistance <= interceptDistanceThreshold {
        print "Intercept success threshold met (<= " + interceptDistanceThreshold + " m).".
    } else {
        print "Intercept threshold not met; recommend another correction pass.".
    }.

    return true.
}.

if ensure_target() {
    if enablePlaneMatch {
        match_planes().
    } else {
        print "Plane match disabled (safer default).".
    }.

    if build_intercept_node() and executeManeuver {
        execute_next_node().
        refine_intercept().
    }.
}.
