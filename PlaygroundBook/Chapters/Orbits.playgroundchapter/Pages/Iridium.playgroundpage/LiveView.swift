import PlaygroundSupport

let view = instantiateLiveView("Iridium")
view.accelerate = 100
view.alwaysShowOrbits = true
view.initialCameraPosition = 2.0
view.dotSize = 3.0
PlaygroundPage.current.liveView = view
