//
//  Satellite.swift
//  ZeitSatTrack
//
//  Created by David HM Spector on 5/14/17.
//  Copyright © 2017 Zeitgeist. All rights reserved.
//

import Foundation
import SceneKit

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
}
