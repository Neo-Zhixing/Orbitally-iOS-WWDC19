//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # HEO
 ### Highly Elliptical Orbit
 
 A highly elliptical orbit (HEO) is an elliptic orbit with high eccentricity.
 
 Examples of inclined HEO orbits include Molniya orbits,
 named after the Molniya Soviet communication satellites which used them, and tundra orbits.
 Such extremely elongated orbits have the advantage of long dwell times at a
 point in the sky during the approach to, and descent from, apogee.
 
 ------------
 
 Increase the simulation speed multiplier and observe how the speed of the satellite decreases
 as it approaches the apogee.
*/

let trace: Bool = /*#-editable-code*/false/*#-end-editable-code*/

let simulationSpeed: Double = /*#-editable-code*/5000/*#-end-editable-code*/

//#-hidden-code
earthView?.send(.dictionary([
    "speed": .floatingPoint(simulationSpeed),
    "trace": .boolean(trace)
    ]))

if simulationSpeed >= 10000 {
    PlaygroundPage.current.assessmentStatus = .pass(message: "Drizzling, isn't it?")
} else {
    PlaygroundPage.current.assessmentStatus = .fail(hints: [
        "\(simulationSpeed) is not big enough for you to see the change in speed for HEO satellites.",
        "Set 'simulationSpeed' to 10000",
        ], solution: "let simulationSpeed: Double = 10000")
}
//#-end-hidden-code
