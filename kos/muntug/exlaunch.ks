CLEARSCREEN.

LOCK THROTTLE TO 1.0.

PRINT "Counting down:".
FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1.
}

// UNTIL SHIP:MAXTHRUST > 0 {
WHEN MAXTHRUST = 0 THEN {
//WHEN SHIP:MAXTHRUST = 0 THEN {
    PRINT "Staging.".
    STAGE.
    PRESERVE.  // keeps trigger active
}.

SET MYSTEER TO HEADING(90,90). // 'UP'
LOCK STEERING TO MYSTEER.
//UNTIL SHIP:APOAPSIS > 100000 OR SHIP:MAXTHRUST = 0 { 
UNTIL SHIP:APOAPSIS > 100000 { 

   IF SHIP:VELOCITY:SURFACE:MAG < 100 OR SHIP:ALTITUDE < 30000 {
      SET MYSTEER TO HEADING(90,90).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 200 {
     SET MYSTEER TO HEADING(90,80).
     PRINT "Pitching to 80 degrees at 100m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 300 {
     SET MYSTEER TO HEADING(90,70).
     PRINT "Pitching to 70 degrees at 200m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 400 {
     SET MYSTEER TO HEADING(90,60).
     PRINT "Pitching to 60 degrees at 300m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 500 {
     SET MYSTEER TO HEADING(90,50).
     PRINT "Pitching to 50 degrees at 400m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 600 {
     SET MYSTEER TO HEADING(90,40).
     PRINT "Pitching to 40 degrees at 500m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 700 {
     SET MYSTEER TO HEADING(90,30).
     PRINT "Pitching to 30 degrees at 600m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 800 {
     SET MYSTEER TO HEADING(90,20).
     PRINT "Pitching to 20 degrees at 700m/s" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
   } ELSE {
     SET MYSTEER TO HEADING(90,10).
     PRINT "Pitching to 10 degree until apoasis" AT (0,15). 
     PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
  }.
}.

PRINT "100km apoasis reached, cuttin throttle".
LOCK THROTTLE TO 0.


// thuis sets users throttle setting to 0 to prevent
// throttle from returning to position earlier set
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

