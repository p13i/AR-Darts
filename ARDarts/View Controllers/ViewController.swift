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
    
    var text: SCNText?
    var textUpdateTimer: Timer?
    var planeAnchor: ARPlaneAnchor?
    
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
//            ARSCNDebugOptions.showWorldOrigin,
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
        case presentingCaptions
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
        case .presentingCaptions:
            self.presentCaptions(tapLocation)
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
        
        planeAnchor.updatePlaneNode(on: hitTestSCNNode, contents: Materials.planeMaterial)
        
        self.planeAnchor = planeAnchor
        
        self.state = .presentingCaptions
        self.statusViewController.status = .presentingCaptions
    }
    
    private func presentCaptions(_ tapLocation: CGPoint) {
        
        guard self.state == .presentingCaptions else { return }
        
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else { return }
        
        if self.text != nil {
            return
        }
        
        guard let planeNode = self.sceneView.node(for: self.planeAnchor!) else { return }
        
        let scale = 0.002 as Float
        
        let rotationX = Double(planeNode.rotation.x)
        let rotationY = Double(planeNode.rotation.y)
        let rotationZ = Double(planeNode.rotation.z)
        let rotationW = 0.0
        
        let positionX = hitTestResult.worldTransform.columns.3.x
        let positionY = hitTestResult.worldTransform.columns.3.y
        let positionZ = hitTestResult.worldTransform.columns.3.z
        
        let width = 300.0 as Float
        let height = 20.0 as Float
        let length = 5.0 as Float
        
        let text = SCNText(string: "This is a sample caption.", extrusionDepth: 1.0)
        text.firstMaterial!.diffuse.contents = UIColor.white
        let textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(scale, scale, scale)
        textNode.rotation = SCNVector4(rotationX, rotationY, rotationZ, rotationW)
        textNode.position = SCNVector3Make(positionX, positionY, positionZ + 15.0 * length * scale)
        
        let background = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(length), chamferRadius: 0.0)
        background.firstMaterial!.diffuse.contents = UIColor.black
        let backgroundNode = SCNNode(geometry: background)
        backgroundNode.scale = SCNVector3(scale, scale, scale)
        backgroundNode.rotation = SCNVector4(rotationX, rotationY, rotationZ, rotationW)
        backgroundNode.position = SCNVector3Make(positionX + 135.0 * scale, positionY + 15.0 * scale / 2.0, positionZ + 12.0 * length * scale)
        
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 10.0, height: 30)
        cone.firstMaterial!.diffuse.contents = UIColor.red
        let coneNode = SCNNode(geometry: cone)
        coneNode.scale = SCNVector3(scale, scale, scale)
        coneNode.pivot = SCNMatrix4MakeRotation(-1 * Float.pi / 2, 0, 0, 1)
        coneNode.position = SCNVector3Make(positionX, positionY + 2.0 * height * scale, positionZ + 15.0 * length * scale)
        
        // Add the dart to the scene
        self.sceneView.scene.rootNode.addChildNode(backgroundNode)
        self.sceneView.scene.rootNode.addChildNode(textNode)
        self.sceneView.scene.rootNode.addChildNode(coneNode)
        
        self.text = text
        
        let captions = [
            "The proton is positively charged",
            "Whereas the neutron is neutrally charged",
            "Finally, the electron is negatively charged."
        ]
        
        var index = 0
        self.textUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (timer: Timer) in
            if index >= captions.count {
                timer.invalidate()
                return
            }
            
            self.text!.string = captions[index]
            index += 1
        })
    }
}
