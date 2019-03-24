//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # LEO
 ### Low Earth Orbit
 
 A *Low Earth Orbit* is an orbit with an altitude of 2,000 km or less.
 Most of the manmade objects in space are in LEO.
 
 The International Space Station conducts operations in LEO.
 All crewed space stations to date, as well as the majority of satellites, have been in LEO.
 
 # SSO
 ### Sun-Synchronous Orbit
 
 A *Sun-synchronous orbit* is a nearly polar orbit around earth,
 in which the satellite passes over any given point of the earth's
 surface at the same local time. Look closely at the simulation on your right,
 and you can recognize this orbit by its extraordinary satellite density.
 */

let simulationSpeed: Double = /*#-editable-code*/100/*#-end-editable-code*/

//#-hidden-code
earthView?.send(.dictionary([
    "speed": .floatingPoint(simulationSpeed)
    ]))
PlaygroundPage.current.assessmentStatus = .pass(message: "Did you notice the many satellites on SSO?")
//#-end-hidden-code

