import PlaygroundSupport

let view = instantiateLiveView("heo")
view.accelerate = 10000
view.alwaysShowOrbits = false
view.initialCameraPosition = 20.0
view.dotSize = 1.0
PlaygroundPage.current.liveView = view
