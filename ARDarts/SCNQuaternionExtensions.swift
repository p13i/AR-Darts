//
//  SCNQuaternionExtensions.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 4/21/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import SceneKit

extension SCNQuaternion {
    static func * (left: SCNQuaternion, right: Float) -> SCNQuaternion {
        return SCNQuaternion(x: left.x * right, y: left.y * right, z: left.z * right, w: left.w * right)
    }
}
