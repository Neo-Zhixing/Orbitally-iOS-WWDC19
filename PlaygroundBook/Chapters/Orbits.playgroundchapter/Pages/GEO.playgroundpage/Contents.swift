//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # GEO
 ### Geosynchronous Earth Orbit
 
 A *geosynchronous orbit* is an orbit around Earth of a satellite with an orbital period that matches Earth's rotation on its axis.
 
 A special case for geosynchronous orbit is an *geostationary orbit*. Satellites around this orbit
 looks stationary for an observer on earth. **Observe the simulation on your right** and observe how
 these satellites matches the earth's rotation.
 
 Because of this, the density of satellites directly above continents is very high.
 **Observe the orbit above the Pacific Ocean**, where the number of satellites is
 noticeably lower than other regions.
 
 -------------------
 
 Strictly speaking, a GEO satellites only appears to be stationary when it has an
 orbit inclination of 0. Due to their inherent instability, geostationary orbits
 will eventually become inclined if they are not corrected using thrusters.
 **Turn on orbit trace** and observe the pattern of those orbits.
*/

let trace: Bool = /*#-editable-code*/false/*#-end-editable-code*/

let simulationSpeed: Double = /*#-editable-code*/100/*#-end-editable-code*/

//#-hidden-code
earthView?.send(.dictionary([
    "speed": .floatingPoint(simulationSpeed),
    "trace": .boolean(trace)
    ]))

if trace {
    PlaygroundPage.current.assessmentStatus = .pass(message: "Those orbit tracings are stunning!")
} else {
    PlaygroundPage.current.assessmentStatus = .fail(hints: [
        "Enable orbit tracing",
        "Set 'trace' to true",
        ], solution: "let trace: Bool = true")
}
//#-end-hidden-code
