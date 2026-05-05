// match_velocity.ks
CLEARSCREEN.

// 1. Check for Target
IF NOT (DEFINED TARGET) {
    PRINT "CRITICAL: No target selected.".
    EXIT.
}

SET t_obj TO TARGET.
PRINT "Matching velocity with: " + t_obj:NAME.

// 2. Wait for Closest Approach
// This loop waits until you are within 5km or the distance starts increasing
PRINT "Waiting for closest approach...".
SET last_dist TO (t_obj:POSITION - SHIP:POSITION):MAG.

UNTIL last_dist < 5000 {
    SET current_dist TO (t_obj:POSITION - SHIP:POSITION):MAG.
    IF current_dist > last_dist { 
        PRINT "Distance increasing. Starting match now.".
        BREAK. 
    }
    SET last_dist TO current_dist.
    WAIT 0.1.
}

// 3. Orient to Relative Retrograde
// Relative velocity = Ship Velocity - Target Velocity
LOCK rel_vel TO SHIP:VELOCITY:ORBIT - t_obj:VELOCITY:ORBIT.
LOCK STEERING TO LOOKDIRUP(-rel_vel, SHIP:UP:VECTOR).

PRINT "Aligning to Relative Retrograde...".
WAIT UNTIL VANG(SHIP:FACING:VECTOR, -rel_vel) < 2.

// 4. Execute the Burn
PRINT "Zeroing relative velocity...".
UNTIL rel_vel:MAG < 0.1 {
    
    // Throttle scaling: The slower we get, the less juice we use
    // This prevents overshooting and oscillating
    IF rel_vel:MAG > 50 {
        LOCK THROTTLE TO 1.0.
    } ELSE IF rel_vel:MAG > 5 {
        LOCK THROTTLE TO 0.2.
    } ELSE {
        LOCK THROTTLE TO 0.05.
    }
    
    PRINT "Relative Speed: " + ROUND(rel_vel:MAG, 2) + " m/s   " AT (0,10).
}

LOCK THROTTLE TO 0.
UNLOCK STEERING.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT "Orbits Matched. Relative velocity is zero.".

