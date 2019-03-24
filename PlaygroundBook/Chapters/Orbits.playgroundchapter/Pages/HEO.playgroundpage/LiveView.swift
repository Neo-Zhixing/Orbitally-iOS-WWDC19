import PlaygroundSupport

let view = instantiateLiveView("heo")
view.accelerate = 10000
view.alwaysShowOrbits = true
view.dotSize = 3.0
PlaygroundPage.current.liveView = view
