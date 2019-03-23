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
        
        
        let earthGeometry = SCNSphere(radius: 6378.0)
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
    
    func compileShaders(_ tles: [TLE]) {
        print(tles)
        let program = SCNProgram()
        program.fragmentFunctionName = "dot_fragment"
        program.vertexFunctionName = "dot_vertex"
        program.library = self.getShaders()
        
        let indices: [UInt32] = [UInt32](0 ..< UInt32(tles.count))
        
        let data = Data(bytes: tles, count: tles.count * MemoryLayout<TLE>.size)
        
        let positionGeometry = SCNGeometrySource(
            data: data,
            semantic: .vertex,
            vectorCount: tles.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<TLE>.size
        )
        let normalGeometry = SCNGeometrySource(
            data: data,
            semantic: .normal,
            vectorCount: tles.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.stride * 3,
            dataStride: MemoryLayout<TLE>.size
        )
        let testgeo = SCNGeometry(sources: [
                positionGeometry,
                normalGeometry,
            ], elements:
            [SCNGeometryElement(indices: indices, primitiveType: .point)]
        )
        let material = SCNMaterial()
        material.program = program
        material.blendMode = .add
        
        testgeo.firstMaterial = material

        let testnode = SCNNode(geometry: testgeo)
        self.scene.rootNode.addChildNode(testnode)
        
        program.handleBinding(ofBufferNamed: "orbitally_frame", frequency: .perFrame) { (stream, node, shadable, renderer) in
            let fov: simd_float1
            if #available(iOS 11.0, *) {
                fov = Float(renderer.pointOfView?.camera?.fieldOfView ?? 1)
            } else {
                fov = Float(renderer.pointOfView?.camera?.xFov ?? 1)
            }
            
            let currentDate = JulianMath.secondsSinceReferenceDate(Date())
            let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)
            let rotationFromGeocentric = JulianMath.rotationFromGeocentricforJulianDate(julianDate: currentJulianDate)
            var data: [simd_float1] = [
                fov,
                simd_float1(currentJulianDate),
                simd_float1(rotationFromGeocentric),
            ]
            let count = MemoryLayout<simd_float1>.stride
            stream.writeBytes(&data, count: count)
        }
    }
    
    public func loadOrbits(satellite: Satellite) {
        let currentDate = JulianMath.secondsSinceReferenceDate(Date())
        let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)
        
        let range:Range<UInt8> = 0..<45
        let vertices = range.map{
            (degree: UInt8)  -> SCNVector3 in
            let anomaly: Double = Double(degree) * 8.0
            let pos = satellite.satelliteCartesianPosition(eccentricAnomaly: anomaly, julianDate: currentJulianDate)
            return SCNVector3(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z))
        }
        
        
        var indices: [UInt32] = (0 ..< UInt32(vertices.count) * 2).map{
            index in
            return (index + 1) / 2
        }
        indices[indices.count-1] = 0
        let testgeo = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices)], elements:
            [SCNGeometryElement(indices: indices, primitiveType: .line)]
        )
        let material = SCNMaterial()
        material.emission.contents = UIColor.white
        
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
        
        let currentDate = JulianMath.secondsSinceReferenceDate(Date())
        let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)

        let tles = self.satelliteManager.satellites.map { (satellite) -> TLE in
            let tle = satellite.twoLineElementSet!
            let currentMeanAnomaly = tle.meanAnomalyForJulianDate(julianDate: currentJulianDate)
            let currentEccentricAnomaly = tle.eccentricAnomalyForMeanAnomaly(meanAnomaly: currentMeanAnomaly)
            return TLE(
                eccentricAnomaly: Float(currentEccentricAnomaly),
                semimajorAxis: Float(tle.semimajorAxis()),
                eccentricity: Float(tle.eccentricity),
                inclination: Float(tle.inclination),
                argumentOfPerigee: Float(tle.argumentOfPerigee),
                rightAscensionOfTheAscendingNode: Float(tle.rightAscensionOfTheAscendingNode)
            )
        }
        compileShaders(tles)
        for sat in satelliteManager.satellites {
            loadOrbits(satellite: sat)
        }
    }
    struct TLE {
        var eccentricAnomaly: Float
        var semimajorAxis: Float
        var eccentricity: Float
        var inclination: Float
        var argumentOfPerigee: Float
        var rightAscensionOfTheAscendingNode: Float
    }
}
