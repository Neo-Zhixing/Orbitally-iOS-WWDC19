//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport

public func instantiateLiveView(_ name: String) -> LiveViewController {
    let vc = LiveViewController(name)
    return vc
}

public func instantiateLiveView() -> LiveViewController {
    let vc = LiveViewController()
    return vc
}
