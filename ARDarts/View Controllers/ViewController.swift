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
    
    // From Apple's ARKitInteraction sample application
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.delegate = self
        
        self.sceneView.showsStatistics = true
        
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.autoenablesDefaultLighting = true
        
        // Set to true to animate the scene
        self.sceneView.isPlaying = true
        
        self.sceneView.scene = SCNScene()
        
        self.sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin,
        ]
        
        sceneView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.handleTap(withTapGesture: ))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
        
        self.state = .searchingForWalls
        self.statusViewController.status = .searchingForWalls
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Don't allow screen to rotate (make AR scene look bad for a few moments as it re-renders)
    override var shouldAutorotate: Bool { get { return false } }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    enum DartsGameState {
        case searchingForWalls
        case confirmingSelectedWall
        case playingDarts
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Only add new nodes to the scene if we are searching for walls
        guard self.state == .searchingForWalls else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Add a new detected plane to the scene
        planeAnchor.addPlaneNode(on: node, contents: Materials.detectedPlaneMaterial)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        // Only updated existing nodes if we are still searching for walls
        guard self.state == .searchingForWalls else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Update the node's geometry and material
        guard let updatedNode = node.childNodes.first else { return }
        // Keep the same material
        planeAnchor.updatePlaneNode(on: updatedNode, contents: Materials.detectedPlaneMaterial)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Only updated existing nodes if we are still searching for walls
        guard self.state == .searchingForWalls else { return }
    }
    
    @objc func handleTap(withTapGesture recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: self.sceneView)
        
        switch self.state {
        case .searchingForWalls:
            self.selectWall(tapLocation)
        case .confirmingSelectedWall:
            self.confirmWall(tapLocation)
        case .playingDarts:
            self.throwDart(tapLocation)
        }
    }
    
    private func selectWall(_ tapLocation: CGPoint) {
        guard self.state == .searchingForWalls else { fatalError() }
        
        let hitTestARResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestARResult = hitTestARResults.first else { return }
        guard let planeAnchor = hitTestARResult.anchor as? ARPlaneAnchor else { return }
        
        let hitTestSCNResults = sceneView.hitTest(tapLocation, options: nil)
        guard let hitTestSCNResult = hitTestSCNResults.first else { return }
        let hitTestSCNNode = hitTestSCNResult.node
        
        NSLog("SCN Hit!")
        
        planeAnchor.updatePlaneNode(on: hitTestSCNNode, contents: Materials.selectedPlaneMaterial)
        
        self.state = .confirmingSelectedWall
        self.statusViewController.status = .searchingForWalls
    }
    
    private func confirmWall(_ tapLocation: CGPoint) {
        let hitTestARResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestARResult = hitTestARResults.first else { return }
        guard let planeAnchor = hitTestARResult.anchor as? ARPlaneAnchor else { return }
        
        let hitTestSCNResults = sceneView.hitTest(tapLocation, options: nil)
        guard let hitTestSCNResult = hitTestSCNResults.first else { return }
        let hitTestSCNNode = hitTestSCNResult.node
        
        planeAnchor.updatePlaneNode(on: hitTestSCNNode, contents: Materials.dartboardMaterial)
        
        self.state = .playingDarts
        self.statusViewController.status = .playingDarts
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
