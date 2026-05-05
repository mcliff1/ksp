// intercept.ks
CLEARSCREEN.

// 1. UNIVERSAL TARGET CHECK
IF NOT (DEFINED TARGET) OR TARGET = "None" { 
    PRINT "CRITICAL: No target found.".
    PRINT "Please select a target in Map View.".
    EXIT. 
}

SET t_body TO TARGET:BODY.
SET mu TO t_body:MU.
SET r1 TO SHIP:OBT:SEMIMAJORAXIS.
SET r2 TO TARGET:OBT:SEMIMAJORAXIS.

// 2. CALCULATE TRANSFER DATA
// Transfer time (half an orbital period of the transfer ellipse)
SET transfer_sma TO (r1 + r2) / 2.
SET transfer_time TO CONSTANT:PI * SQRT(transfer_sma^3 / mu).

// Target's angular velocity (rad/s)
SET target_ang_vel TO SQRT(mu / r2^3).

// Calculate the required Phase Angle (in degrees)
// How much the target will move during our flight
SET target_movement TO target_ang_vel * transfer_time * (180 / CONSTANT:PI).
SET req_phase_angle TO 180 - target_movement.

PRINT "Target: " + TARGET:NAME.
PRINT "Required Phase Angle: " + ROUND(req_phase_angle, 2).

// 3. WAIT FOR WINDOW
LOCK phase_angle TO {
    SET p1 TO SHIP:ORBIT:LAN + SHIP:ORBIT:ARGUMENTOFPERIAPSIS + SHIP:ORBIT:TRUEANOMALY.
    SET p2 TO TARGET:ORBIT:LAN + TARGET:ORBIT:ARGUMENTOFPERIAPSIS + TARGET:ORBIT:TRUEANOMALY.
    SET res TO p2 - p1.
    IF res < 0 { SET res TO res + 360. }
    RETURN res.
}.

PRINT "Waiting for phase angle window...".
UNTIL ABS(phase_angle() - req_phase_angle) < 0.5 {
    // Warp time if far away (optional KSP feature)
    IF ABS(phase_angle() - req_phase_angle) > 5 { SET WARP TO 3. }
    ELSE { SET WARP TO 0. }
}
SET WARP TO 0.

// 4. EXECUTE TRANSFER BURN
// v_transfer = sqrt(mu * (2/r1 - 1/sma))
SET v_initial TO SQRT(mu / r1).
SET v_transfer TO SQRT(mu * (2/r1 - 1/transfer_sma)).
SET dv_burn TO v_transfer - v_initial.

PRINT "Window Reached! Executing Intercept Burn: " + ROUND(dv_burn, 2) + "m/s".

LOCK STEERING TO PROGRADE.
WAIT 5. // Stabilize
LOCK THROTTLE TO 1.0.
SET v_final TO SHIP:VELOCITY:ORBIT:MAG + dv_burn.
WAIT UNTIL SHIP:VELOCITY:ORBIT:MAG >= v_final.
LOCK THROTTLE TO 0.

PRINT "Intercept Trajectory Established.".
UNLOCK STEERING.
