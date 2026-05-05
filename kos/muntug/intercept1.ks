// intercept.ks
CLEARSCREEN.

// 1. Target Validation
IF NOT (HAGT) { 
    PRINT "CRITICAL: No target found in flight computer.".
    EXIT. 
}

SET t_obj TO TARGET.
SET mu TO BODY:MU.
SET r_ship TO SHIP:OBT:SEMIMAJORAXIS.
SET r_target TO t_obj:OBT:SEMIMAJORAXIS.

// 2. Math for the Transfer
SET sma_trans TO (r_ship + r_target) / 2.
SET t_trans TO CONSTANT:PI * SQRT(sma_trans^3 / mu).
SET target_omega TO SQRT(mu / r_target^3).

// Calculate the lead angle the target will cover during our flight
SET target_dist TO (target_omega * t_trans) * (180 / CONSTANT:PI).
SET phase_angle_goal TO 180 - target_dist.

PRINT "Targeting: " + t_obj:NAME.
PRINT "Target Phase Angle: " + ROUND(phase_angle_goal, 2).

// 3. Phase Angle Function
FUNCTION get_phase {
    SET s_long TO SHIP:ORBIT:LAN + SHIP:ORBIT:ARGUMENTOFPERIAPSIS + SHIP:ORBIT:TRUEANOMALY.
    SET t_long TO t_obj:ORBIT:LAN + t_obj:ORBIT:ARGUMENTOFPERIAPSIS + t_obj:ORBIT:TRUEANOMALY.
    SET p_angle TO t_long - s_long.
    IF p_angle < 0 { SET p_angle TO p_angle + 360. }
    RETURN p_angle.
}

// 4. Wait for Window
PRINT "Waiting for alignment...".
SET WARP TO 3.
UNTIL ABS(get_phase() - phase_angle_goal) < 1.0 {
    IF ABS(get_phase() - phase_angle_goal) < 10 { SET WARP TO 0. }
}
SET WARP TO 0.

// 5. Execute Burn
SET v_start TO SQRT(mu / r_ship).
SET v_trans TO SQRT(mu * (2/r_ship - 1/sma_trans)).
SET dv TO v_trans - v_start.

LOCK STEERING TO PROGRADE.
WAIT UNTIL VANG(SHIP:FACING:VECTOR, PROGRADE:VECTOR) < 1.
PRINT "Executing Intercept Burn: " + ROUND(dv, 1) + " m/s".

SET v_limit TO SHIP:VELOCITY:ORBIT:MAG + dv.
LOCK THROTTLE TO 1.0.
WAIT UNTIL SHIP:VELOCITY:ORBIT:MAG >= v_limit.
LOCK THROTTLE TO 0.

UNLOCK STEERING.
PRINT "Trajectory Set. Prepare for Rendezvous.".

