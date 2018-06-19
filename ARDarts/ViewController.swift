//
//  ViewController.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 4/20/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    var state: DartsGameState = .searchingForWalls
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Setttings for lighting...
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // Set to true to animate the scene
        self.sceneView.isPlaying = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin,
        ]
        
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.throwDart(withTapGesture: )))
        
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Don't allow screen to rotate (make AR scene look bad for a few moments as it re-renders)
    override var shouldAutorotate: Bool { get { return false } }

    // Maintains the currently selected plane (where the dartboard is placed)
    var selectedPlane: ARPlaneAnchor?
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    enum DartsGameState {
        case searchingForWalls
        case playingDarts
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Only add new nodes to the scene if we are searching for walls
        guard self.state == .searchingForWalls else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Add a new detected plane to the scene
        let newPlaneNode = SCNNode()
        newPlaneNode.geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        newPlaneNode.geometry?.firstMaterial?.diffuse.contents = Materials.detectedPlaneMaterial
        newPlaneNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        newPlaneNode.eulerAngles = SCNVector3(-1 * Float.pi / 2, 0, 0)
        
        node.addChildNode(newPlaneNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
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
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Only updated existing nodes if we are still searching for walls
        guard self.state == .searchingForWalls else { return }
    }
    
    @objc func throwDart(withTapGesture recognizer: UITapGestureRecognizer) {
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
        
        let firstMaterialContents = (hitTestResultNode.geometry?.firstMaterial?.diffuse.contents as? UIColor)
        if firstMaterialContents == Materials.detectedPlaneMaterial {
            hitTestResultNode.geometry?.firstMaterial?.diffuse.contents = Materials.selectedPlaneMaterial
        } else if firstMaterialContents == Materials.selectedPlaneMaterial {
            hitTestResultNode.geometry?.firstMaterial?.diffuse.contents = Materials.dartboardMaterial
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
            x: dartboardPlaneOrientation.x - self.sceneView.pointOfView!.orientation.x,
            y: dartboardPlaneOrientation.y - self.sceneView.pointOfView!.orientation.y,
            z: dartboardPlaneOrientation.z - self.sceneView.pointOfView!.orientation.z,
            w: dartboardPlaneOrientation.w - self.sceneView.pointOfView!.orientation.w)
        
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
