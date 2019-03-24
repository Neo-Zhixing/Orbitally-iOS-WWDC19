//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # The Iridium

 ![Iridium Logo](images.png)
 
 Iridium has replaced its existing constellation by sending 75 Iridium NEXT satellites into space on a SpaceX Falcon 9 rocket over 8 different launches.
 
In order for a handheld phone to communicate with them, the Iridium satellites are closer to the Earth,
 in low Earth orbit, about 485 miles (781 km) above the surface.
 With an orbital period of about 100 minutes a satellite can only be in view of a phone
 for about 7 minutes, so the call is automatically "handed off" to another satellite when
 one passes beyond the local horizon. This requires a large number of satellites, carefully
 spaced out in polar orbits (see animated image of coverage) to ensure that at least one
 satellite is continually in view from every point on the Earth's surface.
 At least 66 satellites are required, in 6 polar orbits containing 11 satellites each,
 for seamless coverage.
 
 ## Click "Run" to turn on orbit tracing.
*/

let trace: Bool = /*#-editable-code*/true/*#-end-editable-code*/

let simulationSpeed: Double = /*#-editable-code*/100/*#-end-editable-code*/

//#-hidden-code
earthView?.send(.dictionary([
    "speed": .floatingPoint(simulationSpeed),
    "trace": .boolean(trace)
    ]))

if trace {
    PlaygroundPage.current.assessmentStatus = .pass(message: "Well done!")
}
//#-end-hidden-code
