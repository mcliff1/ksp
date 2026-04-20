// Mun orbital intercept test script for the Mun tug launcher.

set parkingApoapsis to 80000.
set parkingPeriapsis to 78000.
set turnStartAltitude to 1000.
set turnEndAltitude to 50000.
set pitchChangeAmount to 72.
set munTransferPhaseAngle to 44.
set munPhaseTolerance to 2.
set munTransferApoapsis to body("Mun"):orbit:radius - 50000.
set munCaptureApoapsis to 25000.
set maxTransferWait to 21600.
set maxMunCoastTime to 259200.
set captureMode to false.

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

function burn_until_apoapsis {
    parameter targetApoapsis, reducedThrottle.
    lock steering to prograde.
    lock throttle to 1.
    until ship:apoapsis >= targetApoapsis {
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

    print "Launching to parking orbit...".
    stage.
    wait 2.

    until ship:apoapsis >= parkingApoapsis {
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
    print "Apoapsis target reached; staging launcher.".
    stage.

    wait until eta:apoapsis < 35.
    lock steering to prograde.
    lock throttle to 1.

    until ship:periapsis >= parkingPeriapsis {
        if ship:periapsis > parkingPeriapsis * 0.85 {
            lock throttle to 0.35.
        }.
        wait 0.1.
    }.

    lock throttle to 0.
    print "Parking orbit established near 80 km.".
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
    print "Transfer burn complete. Kerbin apoapsis set near Mun orbit.".
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

function print_return_guidance {
    print "Return guidance:".
    if captureMode {
        print "Burn prograde at low Mun periapsis until Kerbin periapsis is 35 km.".
    } else {
        print "Stay on free-return and trim Kerbin periapsis into the 30 km to 40 km band.".
    }.
}.

sas off.
rcs off.
lock throttle to 1.
lock steering to heading(90, 90).

launch_to_parking_orbit().

if wait_for_transfer_window() {
    inject_to_mun().

    if wait_for_mun_soi() {
        if captureMode {
            capture_at_mun().
        } else {
            print "Free-return Mun intercept mode enabled; no capture burn executed.".
        }.

        print_return_guidance().
    } else {
        print "Transfer did not produce a Mun encounter; inspect launch timing and phase angle.".
    }.
} else {
    print "Abort: no transfer window found inside the configured wait period.".
}.

lock throttle to 0.
