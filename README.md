#  Orbitally Playground Book #

[YouTube](https://www.youtube.com/watch?v=LrvdOtkK2WA)

To Download the playground book file, navigate to the "Release" tab.

## Overview ##

This is my 2019 WWDC Scholarship submission.

Orbitally is an earth satellite simulator. Based on the TLE records obtained from [Space-Track.org](https://www.space-track.org) I'm able to simulate and visualize the movement of tens of thousands of satellites *simultaneously*.

The core of the project is an implementation of SGP4 algorithm in *Metal Shading Language*. With tens of thousands of satellites and debris orbiting around the earth, it's nearly impossible to simulate all of their movements in real time with CPU. To help solving this problem, a custom *Metal shader* was developed. It takes in a group of 8 orbital parameters and directly render the position of the satellite to the screen. This significantly improved the simulation efficiency. With the help of Metal, it's possible to render and simulate all satellites, rocket body and manmade large debris currently in space in real time.

Other parts of the program was constructed using SceneKit. Then, the custom shader was loaded into the scene with SCNProgram.

Other features include:
- Adjustable color palette
- Adjustable satellite dot size
- Display orbit trace
- Adjustable simulation speed multiplier

