# Linear_Array_Sensor_Subpixel_Visualizer
A nice data visualizer for photodiode array sensors, with multiple subpixel shadow location, pan, zoom, waterfall. 
It runs in a simulated data mode with no sensor hooked up so you can see it run.
Just download the PDE files into the same destination directory, and run it in Processing. 
This is much more fancy than the basic examples included with the TSL1402R and TSL1410R libraries.
It displays the data and position of multiple shadows falling on the sensor, with subpixel precision.
The subpixel mechanism is graphically represensted to see multiple levels of how it works.
A waterfall history plots changes over time, just for fun.
It runs without a sensor; just run it, it defaults to use simulated sensor data.
To plot real sensor data, change signalSource to 3 in the code and connect Teensy 3.6 running my Arduino library for the sensor(s).
More details to follow...
