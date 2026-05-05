// change_orbit.ks
// Usage: run change_orbit(target_altitude).
PARAMETER target_alt. 

CLEARSCREEN.
PRINT "Initiating Orbital Shift to " + (target_alt / 1000) + "km".

SET mu TO BODY:MU.
SET r_initial TO SHIP:ALTITUDE + BODY:RADIUS.
SET r_final TO target_alt + BODY:RADIUS.

// 1. DETERMINE DIRECTION
SET is_raising TO (target_alt > SHIP:APOAPSIS).
IF is_raising {
    PRINT "Phase 1: Raising Apoapsis...".
    LOCK STEERING TO PROGRADE.
} ELSE {
    PRINT "Phase 1: Lowering Periapsis...".
    LOCK STEERING TO RETROGRADE.
}

// 2. INITIAL TRANSFER BURN
// Calculate Delta-V for the transfer ellipse
SET v_curr TO SHIP:VELOCITY:ORBIT:MAG.
SET sma_transfer TO (r_initial + r_final) / 2.
SET v_req TO SQRT(mu * (2/r_initial - 1/sma_transfer)).
SET dv_burn TO ABS(v_req - v_curr).

WAIT UNTIL VANG(SHIP:FACING:VECTOR, STEERING:VECTOR) < 1.
LOCK THROTTLE TO 1.0.

// Burn until the appropriate orbital peak reaches the target
IF is_raising {
    WAIT UNTIL SHIP:APOAPSIS >= target_alt.
} ELSE {
    WAIT UNTIL SHIP:PERIAPSIS <= target_alt.
}

LOCK THROTTLE TO 0.
PRINT "Transfer Ellipse Established.".

// 3. COAST TO NEW ALTITUDE
PRINT "Coasting to " + (target_alt / 1000) + "km...".
IF is_raising {
    WAIT UNTIL ETA:APOAPSIS < 15.
} ELSE {
    WAIT UNTIL ETA:PERIAPSIS < 15.
}

// 4. CIRCULARIZATION BURN
PRINT "Phase 2: Circularizing...".
// Determine circular velocity at target altitude
SET v_circ TO SQRT(mu / r_final).

IF is_raising {
    LOCK STEERING TO PROGRADE.
} ELSE {
    LOCK STEERING TO RETROGRADE.
}

WAIT UNTIL VANG(SHIP:FACING:VECTOR, STEERING:VECTOR) < 1.
LOCK THROTTLE TO 1.0.

// Burn until the orbit is round
UNTIL ABS(SHIP:APOAPSIS - SHIP:PERIAPSIS) < 2000 {
    // Taper throttle for precision as we approach circularity
    IF ABS(SHIP:VELOCITY:ORBIT:MAG - v_circ) < 10 {
        LOCK THROTTLE TO 0.1.
    }
}

LOCK THROTTLE TO 0.
UNLOCK STEERING.
PRINT "Orbit Stable at " + ROUND(SHIP:ALTITUDE / 1000, 2) + "km".

