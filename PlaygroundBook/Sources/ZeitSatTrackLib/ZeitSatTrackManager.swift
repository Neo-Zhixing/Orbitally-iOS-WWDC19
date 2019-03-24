//
//  ZeitSatTrackManager.swift
//  ZeitSatTrack
//
//  Created by David Spector on 5/22/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import Foundation
import SceneKit

open class ZeitSatTrackManager: NSObject {
    public static let sharedInstance = ZeitSatTrackManager()
    var satellites              = [Satellite]()
    
    override init() {
        super.init()
        //self.readTLESources()
    }

    open func addSatellitesFromTLEData(tleString:String) {
        let responseArray = tleString.components(separatedBy: "\n")
        let tleCount = responseArray.count / 3
        DispatchQueue.concurrentPerform(iterations: tleCount) {
            i in
            let satName = responseArray[ i * 3].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let lineOne = responseArray[1 + i * 3]
            let lineTwo = responseArray[2 + i * 3]
            if satName.lengthOfBytes(using: .utf8) > 0 {
                //print("\(satName)")
                let twoLineElementSet = TwoLineElementSet(nameOfSatellite: satName, lineOne: lineOne, lineTwo: lineTwo)
                let satellite = Satellite(twoLineElementSet: twoLineElementSet)
                self.satellites.append(satellite)
            } //of name length & duplication check
        }
    }
}
