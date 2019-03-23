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
    public var light: SCNLight!
    public var lightNode: SCNNode!

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
        
        self.loadSats()
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
    
    public func compileShaders(vertices: [SCNVector3]) {
        let program = SCNProgram()
        program.fragmentFunctionName = "dot_fragment"
        program.vertexFunctionName = "dot_vertex"
        program.library = self.getShaders()
        
        let indices: [UInt32] = [UInt32](0 ..< UInt32(vertices.count))
        let testgeo = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices)], elements:
            [SCNGeometryElement(indices: indices, primitiveType: .point)]
        )
        let material = SCNMaterial()
        material.program = program
        material.blendMode = .add
        
        testgeo.firstMaterial = material

        let testnode = SCNNode(geometry: testgeo)
        self.scene.rootNode.addChildNode(testnode)
    }
    
    let satelliteManager = ZeitSatTrackManager.sharedInstance
    
    public func loadSats () {
        guard let url = Bundle.main.url(forResource: "Iridium", withExtension: "txt"),
            let tle = try? String(contentsOf: url) else {
            return
        }
        satelliteManager.addSatellitesFromTLEData(tleString: tle)
        let locations = satelliteManager.locationsForSatellites()
        let coords = locations.map { (name, location) -> SCNVector3 in
            let r = location.altitude / 6370.0
            let latitude = Double.pi * (location.latitude / 180)
            let longitude = Double.pi * (location.longitude / 180)
            let latCos = cos(latitude)
            let x = r * latCos * cos(longitude)
            let y = r * latCos * sin(longitude)
            let z = r * sin(latitude)
            return SCNVector3(x, y, z)
        }
        compileShaders(vertices: coords)
    }
}
