// circularize.ks
// A robust script to circularize at Apoapsis or Periapsis
CLEARSCREEN.

// 1. CONFIGURATION
// Set to "APO" to circularize at the top, or "PERI" at the bottom
DECLARE PARAMETER target_point IS "APO". 

PRINT "Initializing Circularization Logic...".

// 2. DATA ACQUISITION
SET mu TO BODY:MU.
SET ship_radius TO 0.
SET node_time TO 0.

IF target_point = "APO" {
    SET ship_radius TO SHIP:APOAPSIS + BODY:RADIUS.
    SET node_time TO TIME:SECONDS + ETA:APOAPSIS.
    PRINT "Targeting: APOAPSIS".
} ELSE {
    SET ship_radius TO SHIP:PERIAPSIS + BODY:RADIUS.
    SET node_time TO TIME:SECONDS + ETA:PERIAPSIS.
    PRINT "Targeting: PERIAPSIS".
}

// 3. MATH: VIS-VIVA CALCULATION
// v_circ = sqrt(mu / r)
// v_current = sqrt(mu * (2/r - 1/a))
SET v_curr TO SQRT(mu * (2/ship_radius - 1/SHIP:OBT:SEMIMAJORAXIS)).
SET v_tgt TO SQRT(mu / ship_radius).
SET dv_needed TO v_tgt - v_curr.

// 4. CREATE MANEUVER NODE
SET circ_node TO NODE(node_time, 0, 0, dv_needed).
ADD circ_node.
PRINT "Node Created. Delta-V: " + ROUND(dv_needed, 2) + "m/s".

// 5. PREPARATION
LOCK STEERING TO circ_node:BURNVECTOR.
PRINT "Aligning to Burn Vector...".
WAIT UNTIL VANG(SHIP:FACING:VECTOR, circ_node:BURNVECTOR) < 1.
PRINT "Alignment Confirmed.".

// 6. EXECUTION
// Calculate burn time using current max acceleration (F/m)
SET max_accel TO SHIP:MAXTHRUST / SHIP:MASS.
SET burn_time TO dv_needed / max_accel.

PRINT "Waiting for Burn Window...".
WAIT UNTIL circ_node:ETA <= (burn_time / 2).

PRINT "Executing Burn...".
UNTIL circ_node:DELTAV:MAG < 0.1 {
    
    // Automatic Throttle Scaling
    // Full power until the end, then taper off for precision
    SET thrust_pct TO MIN(circ_node:DELTAV:MAG / (max_accel + 0.1), 1.0).
    LOCK THROTTLE TO thrust_pct.

    // Mid-burn Staging Logic
    LIST ENGINES IN eng_list.
    FOR eng IN eng_list {
        IF eng:FLAMEOUT {
            STAGE.
            PRINT "Stage Separation Confirmed.".
            WAIT 0.5. // Separation clearance
            BREAK.
        }
    }
}

// 7. CLEANUP
LOCK THROTTLE TO 0.
UNLOCK STEERING.
REMOVE circ_node.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

PRINT "Orbit Circularized.".
PRINT "Final Periapsis: " + ROUND(SHIP:PERIAPSIS / 1000, 2) + "km".
PRINT "Final Apoapsis: " + ROUND(SHIP:APOAPSIS / 1000, 2) + "km".

