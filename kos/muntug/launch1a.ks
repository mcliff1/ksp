// KSP kOS Script: Launch to 100km Orbit
CLEARSCREEN.

// 1. Initial Parameters
SET target_altitude TO 100000.
SET target_direction TO 90. // Heading East for rotation bonus
LOCK THROTTLE TO 1.0.
LOCK STEERING TO UP.

PRINT "Counting down...".
FROM {local count is 3.} UNTIL count = 0 STEP {SET count to count - 1.} DO {
    PRINT count.
    WAIT 1.
}

// 2. Liftoff
UNTIL SHIP:MAXTHRUST > 0 { STAGE. }
PRINT "Liftoff!".

// 3. Ascent Profile (The Gravity Turn)
UNTIL SHIP:APOAPSIS > target_altitude {
    
    // Gradual pitch based on altitude
    IF SHIP:ALTITUDE < 11000 {
        PRINT "Vertical Ascent " + STEERING AT (0, 10).
        LOCK STEERING TO HEADING(target_direction, 90).
    } ELSE IF SHIP:ALTITUDE < 45000 {
        // Linear pitch-over from 90 to 0 degrees
        SET pitch TO 90 * (1 - SHIP:ALTITUDE / 45000).
        LOCK STEERING TO HEADING(target_direction, pitch).
        PRINT "Gravity Arc " + STEERING AT (0, 10).
    } ELSE {
        PRINT "Gravity Turn " + STEERING AT (0, 10).
        LOCK STEERING TO HEADING(target_direction, 0).
    }
    PRINT SHIP:APOAPSIS AT (0, 11).
    PRINT SHIP:ALTITUDE AT (0,12).
    // Auto-Staging logic
    //  if we need multiple stages to launch
    LIST ENGINES IN eng_list.
    FOR eng IN eng_list {
        IF eng:FLAMEOUT {
            STAGE.
            PRINT "Stage Separated.".
            BREAK.
        }
    }
}

// 4. Coasting to Space
LOCK THROTTLE TO 0.
PRINT "Apoapsis reached. Coasting to 100km altitude." AT (0, 10).
LOCK STEERING TO PROGRADE.
PRINT "altitude " + SHIP:ALTITUDE AT (0, 11).
//WAIT UNTIL SHIP:ALTITUDE > 70000. // Wait until out of atmosphere
//PRINT "Atmosphere cleared. Deploying fairings.".
// STAGE. 

// 5. Circularization Burn
WAIT UNTIL (ETA:APOAPSIS < 20). // Start burn 20s before peak
PRINT "Executing Circularization Burn.".
LOCK THROTTLE TO 1.0.

UNTIL SHIP:PERIAPSIS > (target_altitude - 2000) {
    LIST ENGINES in eng_list.
    FOR eng IN eng_list {
        IF eng:FLAMEOUT {
            STAGE.
            PRINT "mid-burn stage".
            WAIT 0.5. // pause to fire
            BREAK.
        }
    }

    // Fine-tune throttle as orbit rounds out
    IF SHIP:APOAPSIS > (target_altitude + 5000) {
        LOCK THROTTLE TO 0.1.
    }
}

LOCK THROTTLE TO 0.
PRINT "Orbit Established at 100km.".
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
UNLOCK STEERING.

