// Space Station One launch automation profile.
// Default mode parks in Kerbin orbit for station assembly.
// Set targetMode to "MUN" to continue to a Mun intercept transfer.

set targetMode to "KERBIN".

set parkingApoapsis to 85000.
set parkingPeriapsis to 82000.
set turnStartAltitude to 1200.
set turnEndAltitude to 52000.
set pitchChangeAmount to 70.

set munTransferPhaseAngle to 44.
set munPhaseTolerance to 2.
set munTransferApoapsis to body("Mun"):orbit:semimajoraxis - 50000.
set munCaptureApoapsis to 25000.
set maxTransferWait to 21600.
set maxMunCoastTime to 259200.
set captureMode to false.

set minStageInterval to 3.
set lastStageTime to -999.

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

function mun_phase_angle {
    return vang(ship:position, body("Mun"):position).
}.

function stage_with_note {
    parameter stageMessage.
    print stageMessage.
    stage.
    set lastStageTime to time:seconds.
    wait 0.6.
}.

function maybe_autostage {
    if time:seconds - lastStageTime < minStageInterval {
        return.
    }.

    // When thrust drops to zero during powered ascent, advance staging.
    if ship:availablethrust < 0.1 {
        stage_with_note("Auto-staging: no available thrust.").
    }.
}.

function burn_until_apoapsis {
    parameter targetApoapsis, reducedThrottle.
    lock steering to prograde.
    lock throttle to 1.

    until ship:apoapsis >= targetApoapsis {
        maybe_autostage().

        if ship:apoapsis > targetApoapsis * 0.92 {
            lock throttle to reducedThrottle.
        }.

        wait 0.1.
    }.

    lock throttle to 0.
}.

function launch_to_parking_orbit {
    set frac to 0.
    set pitch to 90.

    print "Launching Space Station One...".
    stage_with_note("Ignition / release.").

    lock throttle to 1.

    until ship:apoapsis >= parkingApoapsis {
        maybe_autostage().

        set frac to clamp((ship:altitude - turnStartAltitude) / (turnEndAltitude - turnStartAltitude), 0, 1).
        set pitch to 90 - (pitchChangeAmount * frac).
        lock steering to heading(90, pitch).

        if ship:apoapsis > parkingApoapsis * 0.85 {
            lock throttle to 0.65.
        }.
        if ship:apoapsis > parkingApoapsis * 0.95 {
            lock throttle to 0.3.
        }.

        wait 0.1.
    }.

    lock throttle to 0.

    if ship:availablethrust < 0.1 {
        stage_with_note("Apoapsis reached. Advancing stage.").
    }.

    wait until eta:apoapsis < 35.
    lock steering to prograde.
    lock throttle to 1.

    until ship:periapsis >= parkingPeriapsis {
        maybe_autostage().

        if ship:periapsis > parkingPeriapsis * 0.85 {
            lock throttle to 0.35.
        }.
        wait 0.1.
    }.

    lock throttle to 0.
    print "Parking orbit established.".
}.

function wait_for_transfer_window {
    set transferStart to time:seconds.
    set currentPhaseAngle to mun_phase_angle().

    print "Waiting for Mun transfer window...".
    until abs(currentPhaseAngle - munTransferPhaseAngle) <= munPhaseTolerance {
        if time:seconds - transferStart > maxTransferWait {
            print "Timed out waiting for a Mun transfer window.".
            return false.
        }.

        set currentPhaseAngle to mun_phase_angle().
        print "Current Mun phase angle: " + round(currentPhaseAngle, 2).
        wait 5.
    }.

    print "Mun transfer window reached.".
    return true.
}.

function inject_to_mun {
    print "Executing trans-Mun injection burn...".
    burn_until_apoapsis(munTransferApoapsis, 0.2).
    print "Transfer burn complete.".
}.

function wait_for_mun_soi {
    set coastStart to time:seconds.

    print "Coasting toward Mun encounter...".
    until ship:body:name = "Mun" {
        if time:seconds - coastStart > maxMunCoastTime {
            print "Expected Mun encounter did not occur inside coast timeout.".
            return false.
        }.
        wait 15.
    }.

    print "Entered Mun sphere of influence.".
    return true.
}.

function capture_at_mun {
    print "Preparing Mun capture burn at periapsis...".
    wait until eta:periapsis < 90.
    lock steering to retrograde.
    lock throttle to 1.

    until ship:apoapsis <= munCaptureApoapsis {
        if ship:apoapsis < munCaptureApoapsis * 1.5 {
            lock throttle to 0.25.
        }.
        wait 0.1.
    }.

    lock throttle to 0.
    print "Mun capture burn complete.".
}.

sas off.
rcs off.
lock steering to heading(90, 90).
lock throttle to 1.

launch_to_parking_orbit().

if targetMode = "MUN" {
    if wait_for_transfer_window() {
        inject_to_mun().

        if wait_for_mun_soi() {
            if captureMode {
                capture_at_mun().
            } else {
                print "Free-return Mun intercept mode enabled; no capture burn executed.".
            }.
        } else {
            print "Transfer did not produce a Mun encounter; inspect timing and phase angle.".
        }.
    } else {
        print "Abort: no transfer window found inside configured wait period.".
    }.
} else {
    print "KERBIN mode complete: ready for station assembly operations in LKO.".
}.

lock throttle to 0.
