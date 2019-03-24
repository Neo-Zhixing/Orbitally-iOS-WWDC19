//
//  ARViewController.swift
//  Book_Sources
//
//  Created by 张之行 on 3/24/19.
//

import Foundation
import ARKit
import UIKit

@available(iOS 11.0, *)
public class ARViewController: LiveViewController {
    public var arSceneView: ARSCNView!
    public override func loadView() {
        let view = ARSCNView()
        self.view = view
        self.arSceneView = view
        self.sceneView = view
        self.scene = view.scene
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.earthNode.position = SCNVector3(0, 0, 0)
        self.satNode?.position = SCNVector3(0, 0, 0)
        self.orbitNode?.position = SCNVector3(0, 0, 0)
        self.scene.background.contents = nil
        self.sceneView.allowsCameraControl = false
        
        self.lightNode.removeFromParentNode()
        self.light = nil
        self.lightNode = nil
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.arSceneView.anchor(for: self.earthNode)
        let config = ARWorldTrackingConfiguration()
        self.arSceneView.session.run(config, options: [])
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arSceneView.session.pause()
    }
}
