//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport

@available(iOS 11.0, *)
public func instantiateLiveView(_ name: String) -> LiveViewController {
    let vc = LiveViewController(name)
    return vc
}

@available(iOS 11.0, *)
public func instantiateLiveView() -> LiveViewController {
    let vc = LiveViewController()
    return vc
}

@available(iOS 11.0, *)
public func instantiateARLiveView() -> ARViewController {
    let vc = ARViewController()
    return vc
}

@available(iOS 11.0, *)
public func instantiateARLiveView(_ name: String) -> ARViewController {
    let vc = ARViewController(name)
    return vc
}
