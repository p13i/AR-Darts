//
//  SCNMatrix4Extensions.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 4/21/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import SceneKit

extension SCNMatrix4 {
    var position: SCNVector3 {
        get {
            let node = SCNNode()
            node.transform = self
            return node.position
        }
    }
    
    var orientation: SCNQuaternion {
        get {
            let node = SCNNode()
            node.transform = self
            return node.orientation
        }
    }
    
    var rotation: SCNVector4 {
        get {
            let node = SCNNode()
            node.transform = self
            return node.rotation
        }
    }
}
