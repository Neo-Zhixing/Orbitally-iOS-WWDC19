//#-hidden-code
import PlaygroundSupport
let earthView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
//#-end-hidden-code
/*:
 # All of these orbits at once.
 
 This is 17887 satellites, rocket bodies and debries in space, today.
 
 Simulating this many objects with complicated algorithms would not be possible without the *Metal Shading Language*.
 With that, we can delegate the calculation to our GPU, who is really good at handling large number of calculations in parallel.
 
 -------------------
 
 And that's the end of our journey. Hope you enjoy it!
*/
