//
//  Satellite.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/14/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//
import CoreLocation
import Foundation
import SceneKit

public struct GeoCoordinates {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees
    public var altitude: Double
    
    public func description() -> String {
        return "Location (\(self.latitude), \(self.longitude)); Altitude: \(self.altitude) KM"
    }
}

public struct LookAngle {
    var azimuth: CLLocationDegrees
    var elevation: CLLocationDegrees
}


public class Satellite {
    
    var twoLineElementSet: TwoLineElementSet?
    var name = ""
    var satCatNumber = 0
    var cosparID = ""
    
    convenience init(twoLineElementSet: TwoLineElementSet?) {
        self.init()
        if twoLineElementSet != nil {
            self.twoLineElementSet = twoLineElementSet;
            self.name = twoLineElementSet!.nameOfSatellite
            self.cosparID = twoLineElementSet!.cosparID
            self.satCatNumber = twoLineElementSet!.satcatNumber
        } else {
            self.name = ""
            self.twoLineElementSet = TwoLineElementSet()
        }
    }
    
    func satellitePositionNow() -> GeoCoordinates? {
        return satellitePositionAt(date: Date())
    }
    
    func satelliteCartesianPosition(eccentricAnomaly currentEccentricAnomaly: Double, julianDate: Double) -> (x:Double, y:Double, z:Double, r:Double) {
        let currentTrueAnomaly = self.twoLineElementSet!.trueAnomalyForEccentricAnomaly(eccentricAnomaly: currentEccentricAnomaly)
        let semimajorAxis: Double = self.twoLineElementSet!.semimajorAxis()
        
        // Solve for r0 : the distance from the satellite to the Earth's center
        let currentOrbitalRadius = semimajorAxis - (semimajorAxis * self.twoLineElementSet!.eccentricity) * cos(currentEccentricAnomaly * .pi / 180.0)
        
        // Solve for the x and y position in the orbital plane
        let orbitalX = currentOrbitalRadius * cos(currentTrueAnomaly * .pi / 180.0)
        let orbitalY = currentOrbitalRadius * sin(currentTrueAnomaly * .pi / 180.0)
        
        
        // Rotation math  https://www.csun.edu/~hcmth017/master/node20.html
        // First, rotate around the z''' axis by the Argument of Perigee: ⍵
        let cosArgPerigee = cos(self.twoLineElementSet!.argumentOfPerigee * .pi / 180.0)
        let sinArgPerigee = sin(self.twoLineElementSet!.argumentOfPerigee * .pi / 180.0)
        let orbitalXbyPerigee = cosArgPerigee * orbitalX - sinArgPerigee * orbitalY
        let orbitalYbyPerigee = sinArgPerigee * orbitalX + cosArgPerigee * orbitalY
        let orbitalZbyPerigee = 0.0
        
        // Next, rotate around the x'' axis by inclincation
        let cosInclination = cos(self.twoLineElementSet!.inclination * .pi / 180.0)
        
        let sinInclination = sin(self.twoLineElementSet!.inclination * .pi / 180.0)
        
        let orbitalXbyInclination = orbitalXbyPerigee;
        
        let orbitalYbyInclination = cosInclination * orbitalYbyPerigee - sinInclination * orbitalZbyPerigee
        let orbitalZbyInclination = sinInclination * orbitalYbyPerigee + cosInclination * orbitalZbyPerigee
        
        // Lastly, rotate around the z' axis by RAAN: Ω
        let cosRAAN = cos(self.twoLineElementSet!.rightAscensionOfTheAscendingNode * .pi / 180.0)
        let sinRAAN = sin(self.twoLineElementSet!.rightAscensionOfTheAscendingNode * .pi / 180.0)
        let geocentricX = cosRAAN * orbitalXbyInclination - sinRAAN * orbitalYbyInclination
        let geocentricY = sinRAAN * orbitalXbyInclination + cosRAAN * orbitalYbyInclination
        let geocentricZ = orbitalZbyInclination
        
        // And then around the z axis by the earth's own rotaton
        let rotationFromGeocentric = JulianMath.rotationFromGeocentricforJulianDate(julianDate: julianDate)
        let rotationFromGeocentricRad = -rotationFromGeocentric * .pi / 180.0
        let relativeX = cos(rotationFromGeocentricRad) * geocentricX - sin(rotationFromGeocentricRad) * geocentricY
        let relativeY = sin(rotationFromGeocentricRad) * geocentricX + cos(rotationFromGeocentricRad) * geocentricY
        let relativeZ = geocentricZ
        return (x: relativeX, y: relativeY, z: relativeZ, r: currentOrbitalRadius)
    }
    func satelliteCartesianPositionAt(date: Double) -> SCNVector3 {
        let currentMeanAnomaly = self.twoLineElementSet!.meanAnomalyForJulianDate(julianDate: date)
        let currentEccentricAnomaly = self.twoLineElementSet!.eccentricAnomalyForMeanAnomaly(meanAnomaly: currentMeanAnomaly)
        let coords = self.satelliteCartesianPosition(eccentricAnomaly: currentEccentricAnomaly, julianDate: date)
        return SCNVector3(x: Float(coords.x) / 6378.0, y: Float(coords.y) / 6378.0, z: Float(coords.z) / 6378.0)
    }
    
    func satellitePositionAt(date:Date) -> GeoCoordinates? {
        
 
        let currentDate = JulianMath.secondsSinceReferenceDate(date)
        let currentJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: currentDate)

        let currentMeanAnomaly = self.twoLineElementSet!.meanAnomalyForJulianDate(julianDate: currentJulianDate)
        let currentEccentricAnomaly = self.twoLineElementSet!.eccentricAnomalyForMeanAnomaly(meanAnomaly: currentMeanAnomaly)
        
        // Use the current Mean Anomaly to get the current Eccentric Anomaly
        let coords = self.satelliteCartesianPosition(eccentricAnomaly: currentEccentricAnomaly, julianDate: currentJulianDate)
        let latitude = 90.0 - acos(coords.z / sqrt(coords.x * coords.x + coords.y * coords.y + coords.z * coords.z)) * 180.0 / .pi
        let longitude = atan2(coords.y, coords.x) * 180.0 / .pi
        let altitude = coords.r
        return GeoCoordinates(latitude: latitude, longitude: longitude, altitude: altitude)
        
/*
        // Some useful debugging in case you want to see how things are computed...
        print("\n\n\n\(self.name)")
        print("currentJulianDate: \(currentJulianDate)")
        print("semimajorAxis: \(semimajorAxis)")
        print("meanAnomalyForJulianDate: \(currentMeanAnomaly)")
        print("currentEccentricAnomaly: \(currentEccentricAnomaly)")
        print("currentTrueAnomaly: \(currentTrueAnomaly)")
        print("currentOrbitalRadius: \(currentOrbitalRadius)")
        print("orbitalX: \(orbitalX)")
        print("orbitalY: \(orbitalY)")
        print("cosArgPerigee: \(cosArgPerigee)")
        print("sinArgPerigee: \(sinArgPerigee)")
        print("orbitalXbyPerigee: \(orbitalXbyPerigee)")
        print("orbitalYbyPerigee: \(orbitalYbyPerigee)")
        print("orbitalZbyPerigee: \(orbitalZbyPerigee)")
        print("cosInclination: \(cosInclination)")
        print("sinInclination: \(sinInclination)")
        print("orbitalXbyInclination: \(orbitalXbyInclination)")
        print("orbitalYbyInclination: \(orbitalYbyInclination)")
        print("orbitalZbyInclination: \(orbitalZbyInclination)")
        print("cosRAAN: \(cosRAAN)")
        print("sinRAAN: \(sinRAAN)")
        print("geocentricX: \(geocentricX)")
        print("geocentricY: \(geocentricY)")
        print("geocentricZ: \(geocentricZ)")
        print("rotationFromGeocentric: \(rotationFromGeocentric)")
        print("rotationFromGeocentricRad: \(rotationFromGeocentricRad)")
        print("relativeX: \(relativeX)")
        print("relativeY: \(relativeY)")
        print("relativeZ: \(relativeZ)")
        print("currentSatellitePosition.latitude: \(latitude)")
        print("currentSatellitePosition.longitude: \(longitude)")
        print("currentSatellitePosition.altitude: \(altitude)")
*/
    }

    
    
    
    func orbitalInfoAt(date:Date, location: CLLocation? = nil) -> Dictionary<String, String>? {
        var orbitalInfo: Dictionary<String, String>?
        
        // @FIXME: Need to check the requested date against the TLE launch date -- if the requested date is < lauchDate return empty coordiates
        
        //let currentDate = JulianMath.secondsSinceReferenceDate
        let tagetDate = JulianMath.julianDateFromDate(date: date)
        let targetJulianDate = JulianMath.julianDateFromSecondsSinceReferenceDate(secondsSinceReferenceDate: tagetDate)
        let semimajorAxis: Double = self.twoLineElementSet!.semimajorAxis()     // kilometers
        let currentMeanAnomaly = self.twoLineElementSet!.meanAnomalyForJulianDate(julianDate: targetJulianDate)
        
        // Use the current Mean Anomaly to get the current Eccentric Anomaly
        let currentEccentricAnomaly = self.twoLineElementSet!.eccentricAnomalyForMeanAnomaly(meanAnomaly: currentMeanAnomaly)
        
        // Use the current Eccentric Anomaly to get the currentTrueAnomaly
        let currentTrueAnomaly = self.twoLineElementSet!.trueAnomalyForEccentricAnomaly(eccentricAnomaly: currentEccentricAnomaly)
        
        // Solve for r0 : the distance from the satellite to the Earth's center
        let currentOrbitalRadius = semimajorAxis - (semimajorAxis * self.twoLineElementSet!.eccentricity) * cos(currentEccentricAnomaly * .pi / 180.0)
        
        // Solve for the x and y position in the orbital plane
        let orbitalX = currentOrbitalRadius * cos(currentTrueAnomaly * .pi / 180.0)
        let orbitalY = currentOrbitalRadius * sin(currentTrueAnomaly * .pi / 180.0)
        
        // Rotation math  https://www.csun.edu/~hcmth017/master/node20.html
        // First, rotate around the z''' axis by the Argument of Perigee: ⍵
        let cosArgPerigee = cos(self.twoLineElementSet!.argumentOfPerigee * .pi / 180.0)
        let sinArgPerigee = sin(self.twoLineElementSet!.argumentOfPerigee * .pi / 180.0)
        let orbitalXbyPerigee = cosArgPerigee * orbitalX - sinArgPerigee * orbitalY
        let orbitalYbyPerigee = sinArgPerigee * orbitalX + cosArgPerigee * orbitalY
        let orbitalZbyPerigee = 0.0
        
        // Next, rotate around the x'' axis by inclincation
        let cosInclination = cos(self.twoLineElementSet!.inclination * .pi / 180.0)
        let sinInclination = sin(self.twoLineElementSet!.inclination * .pi / 180.0)
        let orbitalXbyInclination = orbitalXbyPerigee;
        let orbitalYbyInclination = cosInclination * orbitalYbyPerigee - sinInclination * orbitalZbyPerigee
        let orbitalZbyInclination = sinInclination * orbitalYbyPerigee + cosInclination * orbitalZbyPerigee
        
        // Lastly, rotate around the z' axis by RAAN: Ω
        let cosRAAN = cos(self.twoLineElementSet!.rightAscensionOfTheAscendingNode * .pi / 180.0)
        let sinRAAN = sin(self.twoLineElementSet!.rightAscensionOfTheAscendingNode * .pi / 180.0)
        let geocentricX = cosRAAN * orbitalXbyInclination - sinRAAN * orbitalYbyInclination;
        let geocentricY = sinRAAN * orbitalXbyInclination + cosRAAN * orbitalYbyInclination;
        let geocentricZ = orbitalZbyInclination;
        
        // And then around the z axis by the earth's own rotaton
        let rotationFromGeocentric = JulianMath.rotationFromGeocentricforJulianDate(julianDate: targetJulianDate)
        let rotationFromGeocentricRad = -rotationFromGeocentric * .pi / 180.0
        
        let relativeX = cos(rotationFromGeocentricRad) * geocentricX - sin(rotationFromGeocentricRad) * geocentricY
        let relativeY = sin(rotationFromGeocentricRad) * geocentricX + cos(rotationFromGeocentricRad) * geocentricY
        let relativeZ = geocentricZ
        
        
        let latitude = 90.0 - acos(relativeZ / sqrt(relativeX * relativeX + relativeY * relativeY + relativeZ * relativeZ)) * 180.0 / .pi
        let longitude = atan2(relativeY, relativeX) * 180.0 / .pi
        let altitude = currentOrbitalRadius - 6370.0
        
        // Now we need to get the look angle, speed, distance, etc 
        
        
        return orbitalInfo
    }
}
