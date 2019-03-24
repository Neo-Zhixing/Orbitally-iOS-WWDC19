//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # Satellites
 
 ![Satellite](astranis.jpg)
 
 Once an object gets enough speed, it'll orbit the earth in the vacuum of space, forever.
 
 The orbit of a salellite was described using a group of 8 parameters.
 Anyone with these 8 numbers can predict the location of the satellite at any given time.
 
 The simulation shown on your right is the orbit of a satellite.
 
 ----------
 Your Task: change inclination to 60. How does the orbit changes in response?
*/

let sat: [String: Double] = [
    "meanAnomaly": 99.2839,
    "semimajorAxis": 7007.356,
    "eccentricity": 0.0136905,
    "inclination": 86.3998,
    "argumentOfPerigee": 259.2943,
    "rightAscensionOfTheAscendingNode": 34.4869,
    "epoch": 1.9402277,
    "meanMotion": 14.800576
]
let trace: Bool = true
let simulationSpeed: Double = 1000

//#-hidden-code
let tle = sat.mapValues{
        value in
        return PlaygroundValue.floatingPoint(value)
}
earthView?.send(.dictionary([
    "tle": .dictionary(tle),
    "speed": .floatingPoint(simulationSpeed),
    "trace": .boolean(trace)
    ]))
//#-end-hidden-code
