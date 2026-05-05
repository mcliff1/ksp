// circularize.ks
CLEARSCREEN.

// 1. Choose the point of circularization
// Use 'APOAPSIS' to round out at the top, or 'PERIAPSIS' at the bottom
//SET point_to_circ TO APOAPSIS. 

// 2. Calculate necessary Delta-V
//SET mu TO BODY:MU.

// 1. Choose the point of circularization using a STRING
SET mode TO "APO". 

// 2. Calculate necessary Delta-V
SET mu TO BODY:MU.
SET r TO 0.

// Use the string to decide which orbital parameter to pull
IF mode = "APO" {
    SET r TO SHIP:APOAPSIS + BODY:RADIUS.
} ELSE {
    SET r TO SHIP:PERIAPSIS + BODY:RADIUS.
}

SET r TO SHIP:ALTITUDE + BODY:RADIUS.
IF point_to_circ = APOAPSIS {
    SET r TO SHIP:APOAPSIS + BODY:RADIUS.
} ELSE {
    SET r TO SHIP:PERIAPSIS + BODY:RADIUS.
}

SET v_current TO SQRT(mu * (2/r - 1/SHIP:OBT:SEMIMAJORAXIS)).
SET v_target TO SQRT(mu / r).
SET dv_needed TO v_target - v_current.

// 3. Create the Maneuver Node
SET node_time TO TIME:SECONDS + ETA:APOAPSIS.
IF mode = "APO" { 
    SET node_time TO TIME:SECONDS + ETA:APOAPSIS. 
} ELSE {
    SET node_time TO TIME:SECONDS + ETA:PERIAPSIS. 
}

SET my_node TO NODE(node_time, 0, 0, dv_needed).
ADD my_node.

PRINT "Node created. Delta-V: " + ROUND(dv_needed, 2) + " m/s".

// 4. Orient and Prepare
LOCK STEERING TO my_node:BURNVECTOR.
PRINT "Orienting to burn vector...".
WAIT UNTIL VANG(SHIP:FACING:VECTOR, my_node:BURNVECTOR) < 1.

// 5. Execute the Burn
// Calculate burn time (simple F=ma approximation)
SET max_acc TO SHIP:MAXTHRUST / SHIP:MASS.
SET burn_duration TO dv_needed / max_acc.

PRINT "Waiting for burn window...".
WAIT UNTIL my_node:ETA <= (burn_duration / 2).

PRINT "Executing Burn...".
UNTIL my_node:DELTAV:MAG < 0.1 {
    // Auto-throttle: slow down as we get closer for precision
    SET throttle_val TO MIN(my_node:DELTAV:MAG / (max_acc + 0.1), 1.0).
    LOCK THROTTLE TO throttle_val.

    // Mid-burn staging logic
    IF SHIP:MAXTHRUST < 0.1 {
        STAGE.
        PRINT "Staging...".
        WAIT 0.5.
    }
}

LOCK THROTTLE TO 0.
REMOVE my_node.
UNLOCK STEERING.
PRINT "Orbit Circularized.".
