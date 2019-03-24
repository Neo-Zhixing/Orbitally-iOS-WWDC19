import PlaygroundSupport

let view = instantiateLiveView("Iridium")
view.accelerate = 100
view.alwaysShowOrbits = true
view.dotSize = 5.0
PlaygroundPage.current.liveView = view
