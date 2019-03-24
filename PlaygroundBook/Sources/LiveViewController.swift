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
        // This happens when the user's code naturally finishesws running, if the user presses Stop, or if there is a crash.
    }
    */
    public  init() {
        super.init(nibName: nil, bundle: nil)
    }
    public init(_ name: String) {
        self.filename = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard case let .dictionary(dict) = message else {
            return
        }
        if case var .some(.floatingPoint(accelerate)) = dict["speed"] {
            if accelerate > 100000 {
                accelerate = 100000
            } else if accelerate < 1 {
                accelerate = 1
            }
            self.accelerate = Float(accelerate)
            self.startAnimate()
        }
        if case let .some(.boolean(trace)) = dict["trace"] {
            if (trace != self.alwaysShowOrbits) {
                self.alwaysShowOrbits = trace
                if trace {
                    self.loadOrbits()
                } else {
                    self.orbitNode?.geometry = nil
                }
                
            }
        }
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
        scene.rootNode.addChildNode(earthNode)
        
        self.sceneView.scene = scene
        self.sceneView.allowsCameraControl = true
        
        //self.sceneView.backgroundColor = UIColor.black
        
        self.light = SCNLight()
        lightNode = SCNNode()
        lightNode.light = self.light
        lightNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0.4)
        self.scene.rootNode.addChildNode(lightNode)
        self.light.type = .directional
        
        self.scene.background.contents = UIImage(named: "2k_stars_milky_way.jpg")
        
        self.startAnimate()
        
        self.loadSats()
    }
    
    public func startAnimate() {
        let twoPi = CGFloat.pi * 2.0
        earthNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: (twoPi / 86400.0) * CGFloat(self.accelerate), z: 0, duration: 1)))
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
    
    var program: SCNProgram!
    func compileShaders() {
        let program = SCNProgram()
        self.program = program
        program.fragmentFunctionName = "dot_fragment"
        program.vertexFunctionName = "dot_vertex"
        program.library = self.getShaders()
        
        
        
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
                simd_float1(rotationFromGeocentric),
                86400.0 / self.accelerate
            ]
            let count = MemoryLayout<simd_float1>.stride * data.count
            stream.writeBytes(&data, count: count)
        }
    }
    
    var satNode: SCNNode?
    public func loadSatGeometry(_ tles: [TLE]) {
        let indices: [UInt32] = [UInt32](0 ..< UInt32(tles.count))
        
        let data = Data(bytes: tles, count: tles.count * MemoryLayout<TLE>.size)
        
        let positionGeometry = SCNGeometrySource(
            data: data,
            semantic: .vertex,
            vectorCount: tles.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<TLE>.size
        )
        let normalGeometry = SCNGeometrySource(
            data: data,
            semantic: .normal,
            vectorCount: tles.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.stride * 4,
            dataStride: MemoryLayout<TLE>.size
        )
        let testgeo = SCNGeometry(sources: [
            positionGeometry,
            normalGeometry,
            ], elements:
            [SCNGeometryElement(indices: indices, primitiveType: .point)]
        )
        let material = SCNMaterial()
        if (program == nil) {
            self.compileShaders()
        }
        material.program = program
        material.blendMode = .add
        
        testgeo.firstMaterial = material
        
        if let satNode = self.satNode {
            satNode.geometry = testgeo
        } else {
            let node = SCNNode(geometry: testgeo)
            self.scene.rootNode.addChildNode(node)
            self.satNode = node
        }
        
    }
    
    public var accelerate: Float = 100
    
    public var orbitNode: SCNNode?
    public func loadOrbits() {
        if self.orbitNode == nil {
            let node = SCNNode()
            self.scene.rootNode.addChildNode(node)
            self.orbitNode = node
        }
        let orbitNode = self.orbitNode!
        let currentDate = JulianMath.secondsSinceReferenceDate(Date())
        let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)
        
        let range:Range<UInt8> = 0..<45
        
        var vertices = [SCNVector3]()
        vertices.reserveCapacity(self.satelliteManager.satellites.count * 45)
        
        var indices = [UInt32]()
        indices.reserveCapacity(self.satelliteManager.satellites.count * 45 * 2)

        for (satIndex, sat) in self.satelliteManager.satellites.enumerated() {
            for dotIndex in range {
                let anomaly: Double = Double(dotIndex) * 8.0
                let pos = sat.satelliteCartesianPosition(eccentricAnomaly: anomaly, julianDate: currentJulianDate)
                let vector = SCNVector3(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z))
                vertices.append(vector)
                let firstIndex = UInt32(satIndex) * 45
                let index: UInt32 = firstIndex + UInt32(dotIndex)
                indices.append(index)
                indices.append(dotIndex == 44 ? firstIndex : index+1)
            }
        }
        let testgeo = SCNGeometry(sources: [SCNGeometrySource(vertices: vertices)], elements:
            [SCNGeometryElement(indices: indices, primitiveType: .line)]
        )
        let material = SCNMaterial()
        material.emission.contents = UIColor.white
        
        testgeo.firstMaterial = material
        orbitNode.geometry = testgeo
    }
    
    let satelliteManager = ZeitSatTrackManager.sharedInstance
    
    var filename: String?
    
    public func loadSats () {
        guard let filename = self.filename,
            let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
            let tle = try? String(contentsOf: url) else {
            return
        }
        satelliteManager.addSatellitesFromTLEData(tleString: tle)
        let tles = self.satelliteManager.satellites.map { (satellite) -> TLE in
            let tle = satellite.twoLineElementSet!
            let currentDate = JulianMath.secondsSinceReferenceDate(Date())
            let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)
            let epoch = currentJulianDate - tle.epochAsJulianDate()
            return TLE(
                meanAnomaly: Float(tle.meanAnomaly),
                semimajorAxis: Float(tle.semimajorAxis()),
                eccentricity: Float(tle.eccentricity),
                inclination: Float(tle.inclination),
                argumentOfPerigee: Float(tle.argumentOfPerigee),
                rightAscensionOfTheAscendingNode: Float(tle.rightAscensionOfTheAscendingNode),
                epoch: Float(epoch),
                meanMotion: Float(tle.meanMotion)
            )
        }
        loadSatGeometry(tles)
        if alwaysShowOrbits {
            loadOrbits()
        }
    }
    public var alwaysShowOrbits = false
    public struct TLE {
        var meanAnomaly: Float
        var semimajorAxis: Float
        var eccentricity: Float
        var inclination: Float
        var argumentOfPerigee: Float
        var rightAscensionOfTheAscendingNode: Float
        var epoch: Float;
        var meanMotion: Float;
    }
}
