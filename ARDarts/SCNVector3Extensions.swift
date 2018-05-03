//
//  SCNVector3Extensions.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 4/21/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3 {
    static func * (left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3Make(left.x * right, left.x * right, left.x * right)
    }
    
    static func == (left: SCNVector3, right: SCNVector3) -> Bool {
        return left.x == right.x && left.y == right.y && left.z == right.z
    }
}
