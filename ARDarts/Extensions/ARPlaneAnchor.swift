//
//  ARPlaneAnchor.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 6/19/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

extension ARPlaneAnchor {
    
    @discardableResult
    func addPlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        material.diffuse.contents = contents
        
        let planeNode = SCNNode(geometry: geometry)
        
        node.addChildNode(planeNode)
        
        return planeNode
    }
    
    @discardableResult
    func updatePlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        material.diffuse.contents = contents
        
        node.geometry = geometry
        
        return node
    }
    
    func addPlaneNode(on node: SCNNode, contents: Any) {
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        let planeNode = addPlaneNode(on: node, geometry: geometry, contents: contents)
        planeNode.position = SCNVector3(self.center.x, 0, self.center.z)
        planeNode.eulerAngles = SCNVector3(-1 * Float.pi / 2, 0, 0)
    }
    
    func updatePlaneNode(on node: SCNNode, contents: Any) {
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        let planeNode = updatePlaneNode(on: node, geometry: geometry, contents: contents)
        planeNode.position = SCNVector3(self.center.x, 0, self.center.z)
        planeNode.eulerAngles = SCNVector3(-1 * Float.pi / 2, 0, 0)
    }
}
