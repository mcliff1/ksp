// Very simple kOS script for launching and controlling a poket-sized NASA Mun Tug.

lock throttle to 1.
stage.
wait until ship:rocketry:stage:0:thrust:SHOULD be 0.

// Circularize your orbit at 100km after launch
set targetOrbit to orbit:equatorial +:p(0, 100000, 0).

lock targetVelocity to targetOrbit:velocity.
wait until ship:orbit:apoapsis >= targetOrbit:apoapsis - 1000.

lock throttle to 0.2.
wait until ship:timeToApoapsis < 60.

lock throttle to 0.
