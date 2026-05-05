// intercept.ks
CLEARSCREEN.

// 1. UNIVERSAL TARGET CHECK
IF NOT (DEFINED TARGET) { 
    PRINT "CRITICAL: No target selected in Map View.".
    EXIT. 
}

SET t_obj TO TARGET.
SET mu TO BODY:MU.

// 2. DATA ACQUISITION
// Use Position vectors to calculate radii to handle slightly elliptical orbits
SET r_ship TO SHIP:OBT:SEMIMAJORAXIS.
SET r_target TO t_obj:OBT:SEMIMAJORAXIS.

// 3. MATH: HOHMANN TRANSFER
SET sma_trans TO (r_ship + r_target) / 2.
SET t_trans TO CONSTANT:PI * SQRT(sma_trans^3 / mu).
SET target_ang_vel TO SQRT(mu / r_target^3).

// Degrees the target moves during our transit
SET target_deg TO (target_ang_vel * t_trans) * (180 / CONSTANT:PI).
SET target_phase_goal TO 180 - target_deg.

PRINT "Target: " + t_obj:NAME.
PRINT "Required Phase Angle: " + ROUND(target_phase_goal, 2).

// 4. THE PHASE ANGLE CALCULATION
// This function returns the current angle between you and the target
FUNCTION current_phase {
    SET s_long TO SHIP:ORBIT:LAN + SHIP:ORBIT:ARGUMENTOFPERIAPSIS + SHIP:ORBIT:TRUEANOMALY.
    SET t_long TO t_obj:ORBIT:LAN + t_obj:ORBIT:ARGUMENTOFPERIAPSIS + t_obj:ORBIT:TRUEANOMALY.
    SET p_angle TO t_long - s_long.
    
    // Normalize to 0-360 range
    UNTIL p_angle >= 0 { SET p_angle TO p_angle + 360. }
    UNTIL p_angle < 360 { SET p_angle TO p_angle - 360. }
    
    RETURN p_angle.
}

// 5. WAIT FOR WINDOW
PRINT "Waiting for phase angle window...".
SET WARP TO 3.
// We use the function call current_phase() here correctly
UNTIL ABS(current_phase() - target_phase_goal) < 1.0 {
    IF ABS(current_phase() - target_phase_goal) < 10 { SET WARP TO 0. }
    
    PRINT "Current Phase: " + ROUND(current_phase(), 1) + " / Goal: " + ROUND(target_phase_goal, 1) + "   " AT (0,12).
}
SET WARP TO 0.

// 6. EXECUTE BURN
SET v_start TO SQRT(mu / r_ship).
SET v_trans TO SQRT(mu * (2/r_ship - 1/sma_trans)).
SET dv TO v_trans - v_start.

LOCK STEERING TO PROGRADE.
PRINT "Aligning for burn...".
WAIT UNTIL VANG(SHIP:FACING:VECTOR, PROGRADE:VECTOR) < 1.

PRINT "Executing Burn: " + ROUND(dv, 2) + " m/s".
SET v_final TO SHIP:VELOCITY:ORBIT:MAG + dv.
LOCK THROTTLE TO 1.0.

UNTIL SHIP:VELOCITY:ORBIT:MAG >= v_final {
    // Taper throttle for precision
    IF (v_final - SHIP:VELOCITY:ORBIT:MAG) < 5 {
        LOCK THROTTLE TO 0.1.
    }
}

LOCK THROTTLE TO 0.
UNLOCK STEERING.
PRINT "Intercept trajectory established!".


