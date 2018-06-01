//
//  DartsGameStateManager.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 5/3/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class DartsGameStateManager {
    
    enum DartsGameState {
        case searchingForWalls
        case playingDarts
    }
    
    let sceneView: ARSCNView
    var state: DartsGameState
    // Maintains all the added anchors and nodes
    var allDetectedPlaneNodes: [(anchor: ARPlaneAnchor, node: SCNNode)]
    // Maintains the currently selected plane (where the dartboard is placed)
    var selectedPlane: ARPlaneAnchor?
    
    // The different materials used in the scene
    let detectedPlaneMaterial = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
    let selectedPlaneMaterial = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
    let dartboardMaterial = UIImage(named: "dartboard.png")
    
    init(for sceneView: ARSCNView) {
        self.sceneView = sceneView
        self.state = .searchingForWalls
        self.allDetectedPlaneNodes = []
    }
    
    func handle(added node: SCNNode, for anchor: ARAnchor) {
        
        // Only add new nodes to the scene if we are searching for walls
        guard self.state == .searchingForWalls else { return }

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Add a new detected plane to the scene
        let newPlaneNode = SCNNode()
        newPlaneNode.geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        newPlaneNode.geometry?.firstMaterial?.diffuse.contents = self.detectedPlaneMaterial
        newPlaneNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        newPlaneNode.eulerAngles = SCNVector3(-1 * Float.pi / 2, 0, 0)
        
        node.addChildNode(newPlaneNode)
        self.allDetectedPlaneNodes.append((anchor: planeAnchor, node: newPlaneNode))
    }
    
    func handle(updated node: SCNNode, for anchor: ARAnchor) {
        
        // Only updated existing nodes if we are still searching for walls
        guard self.state == .searchingForWalls else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Update the node's geometry and material
        guard let updatedNode = node.childNodes.first else { return }
        // Keep the same material
        let updatedGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        updatedGeometry.firstMaterial?.diffuse.contents = updatedNode.geometry?.firstMaterial?.diffuse.contents
        updatedNode.geometry = updatedGeometry
        updatedNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
    
    func handle(removed node: SCNNode, for anchor: ARAnchor) {
        
        // Only updated existing nodes if we are still searching for walls
        guard self.state == .searchingForWalls else { return }
        
        guard let indexToRemove = self.allDetectedPlaneNodes.index(where: { (tuple) -> Bool in
            return tuple.anchor == anchor
        }) else { return }
        
        self.allDetectedPlaneNodes.remove(at: indexToRemove)
    }
    
    func handle(tapWithRecognizer recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: self.sceneView)
        
        switch self.state {
        case .searchingForWalls:
            self.hitTestWall(tapLocation)
        case .playingDarts:
            self.throwDart(tapLocation)
        }
    }
    
    private func hitTestWall(_ tapLocation: CGPoint) {
        // Search the scene and not the world (https://stackoverflow.com/a/46189006/5071723)
        let hitTestResults = sceneView.hitTest(tapLocation, options: nil)
        guard let hitTestResult = hitTestResults.first else { return }
        
        let hitTestResultNode = hitTestResult.node
        
        if (hitTestResultNode.geometry?.firstMaterial?.diffuse.contents as? UIColor) == self.detectedPlaneMaterial {
            hitTestResultNode.geometry?.firstMaterial?.diffuse.contents = self.selectedPlaneMaterial
        } else if (hitTestResultNode.geometry?.firstMaterial?.diffuse.contents as? UIColor) == self.selectedPlaneMaterial {
            hitTestResultNode.geometry?.firstMaterial?.diffuse.contents = self.dartboardMaterial
            self.state = .playingDarts
        }
    }
    
    private func throwDart(_ tapLocation: CGPoint) {
        
        guard self.state == .playingDarts else { return }
        
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else { return }
        
        // Start at the camera's point-of-view
        let startPosition = self.sceneView.pointOfView!.position
        // End on the plane
        let endPosition = SCNMatrix4(hitTestResult.worldTransform).position
        
        // Setup the dart cone
        let dartGeometry = SCNCone(topRadius: 0.0, bottomRadius: 0.01, height: 0.1)
        // Make the cone red
        dartGeometry.firstMaterial!.diffuse.contents = UIColor.red
        // Add a white sheen
        dartGeometry.firstMaterial!.specular.contents = UIColor.white
        // Place the dart in the scene
        let dartNode = SCNNode(geometry: dartGeometry)
        let dartboardPlaneOrientation = SCNMatrix4(hitTestResult.worldTransform).orientation
        dartNode.orientation = SCNQuaternion(
            x: dartboardPlaneOrientation.x,
            y: dartboardPlaneOrientation.y,
            z: dartboardPlaneOrientation.z,
            w: dartboardPlaneOrientation.w * -1.0)
        
        // Animate the motion from the camera to the plane
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = startPosition
        animation.toValue = endPosition
        animation.duration = 0.5  // seconds
        CATransaction.setCompletionBlock {
            dartNode.position = endPosition
        }
        CATransaction.commit()
        
        // Animate the dart's node
        dartNode.addAnimation(animation, forKey: "throwDart")
        
        // Add the dart to the scene
        self.sceneView.scene.rootNode.addChildNode(dartNode)
    }
}
