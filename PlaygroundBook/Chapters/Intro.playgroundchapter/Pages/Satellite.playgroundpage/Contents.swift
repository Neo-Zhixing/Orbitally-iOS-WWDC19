//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
typealias Satellite = LiveViewController.TLE
//#-end-hidden-code
/*:
 # Satellites
 
 ![Satellite](astranis.jpg)
 
 Once an object gets enough speed, it'll orbit the earth in the vacuum of space, forever.
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


let tle = sat.mapValues{
        value in
        return PlaygroundValue.floatingPoint(value)
}
earthView?.send(.dictionary([
    "tle": .dictionary(tle),
    "speed": .floatingPoint(simulationSpeed),
    "trace": .boolean(trace)
    ]))
