//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import PlaygroundSupport
import SceneKit

@objc(Book_Sources_LiveViewController)
public class LiveViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    /*
    public func liveViewMessageConnectionOpened() {
        // Implement this method to be notified when the live view message connection is opened.
        // The connection will be opened when the process running Contents.swift starts running and listening for messages.
    }
    */

    /*
    public func liveViewMessageConnectionClosed() {
        // Implement this method to be notified when the live view message connection is closed.
        // The connection will be closed when the process running Contents.swift exits and is no longer listening for messages.
        // This happens when the user's code naturally finishes running, if the user presses Stop, or if there is a crash.
    }
    */

    public func receive(_ message: PlaygroundValue) {
        // Implement this method to receive messages sent from the process running Contents.swift.
        // This method is *required* by the PlaygroundLiveViewMessageHandler protocol.
        // Use this method to decode any messages sent as PlaygroundValue values and respond accordingly.
    }
    
    public var earthNode: SCNNode!
    public var sceneView: SCNView!
    public var scene: SCNScene!
    public var camera: SCNCamera!
    public var light: SCNLight!
    public var lightNode: SCNNode!
    
    public var cloudNode: SCNNode!

    public override func loadView() {
        let view = SCNView()
        if #available(iOS 11.0, *) {
            //view.debugOptions = [.showWireframe]
        }
        self.view = view
        self.sceneView = view
    }
    public override func viewDidLoad() {
        scene = SCNScene()
        
        
        let earthGeometry = SCNSphere(radius: 1)
        earthGeometry.segmentCount = 96
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = UIImage(named: "8k_earth_daymap.jpg")
        earthMaterial.specular.contents = UIImage(named: "2k_earth_specular_map.tiff")
        earthMaterial.normal.contents = UIImage(named: "2k_earth_normal_map.tiff")
        earthMaterial.selfIllumination.contents = UIImage(named: "2k_earth_nightmap.jpg")
        earthGeometry.insertMaterial(earthMaterial, at: 0)
        
        earthNode = SCNNode(geometry: earthGeometry)
        earthNode.eulerAngles = SCNVector3(0, 0, -0.4)
        scene.rootNode.addChildNode(earthNode)
        
        self.camera = SCNCamera()
        
        self.sceneView.scene = scene
        self.sceneView.allowsCameraControl = true
        
        //self.sceneView.backgroundColor = UIColor.black
        
        self.light = SCNLight()
        lightNode = SCNNode()
        lightNode.light = self.light
        self.scene.rootNode.addChildNode(lightNode)
        self.light.type = .directional
        
        self.scene.background.contents = UIImage(named: "2k_stars_milky_way.jpg")
        
        self.startAnimate()
        self.compileShaders()
    }
    
    public func startAnimate() {
        earthNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: 0.4, z: 0, duration: 1)))
        lightNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: 0.1, z: 0, duration: 1)))
    }
    
    private func getShaders() -> MTLLibrary? {
        guard let device = self.sceneView.device else {
            return nil
        }
        if let lib = device.makeDefaultLibrary() {
            return lib
        }
        return nil
    }
    
    public func compileShaders() {
        let program = SCNProgram()
        program.fragmentFunctionName = "dot_fragment"
        program.vertexFunctionName = "dot_vertex"
        program.library = self.getShaders()
        
        let testgeo = SCNGeometry(sources: [SCNGeometrySource(vertices: [
            SCNVector3(x: 0, y: 2, z: 0),
            SCNVector3(x: 0, y: 0, z: -2),
            SCNVector3(x: 2, y: 0, z: 0)
            ])], elements:
            [SCNGeometryElement(indices: [1, 0, 2], primitiveType: SCNGeometryPrimitiveType.point)]
        )
        let material = SCNMaterial()
        material.program = program
        material.blendMode = .add
        
        testgeo.firstMaterial = material

        let testnode = SCNNode(geometry: testgeo)
        self.scene.rootNode.addChildNode(testnode)
        self.scene.rootNode.addChildNode(testnode)
    }
}
