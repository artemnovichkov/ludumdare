//
//  ViewController.swift
//  Ludum Dare
//
//  Created by Artem Novichkov on 28/07/2017.
//  Copyright © 2017 Artem Novichkov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var lastForce: CGFloat = 0 {
        didSet {
            //            print("👆Last force: \(lastForce)")
        }
    }
    
    var planes = [Plane]()
    var mazeNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Create a new scene
        //        let scene = SCNScene(named: "art.scnassets/Maze.scn")!
        //
        //        // Set the scene to the view
        //        sceneView.scene = scene
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func pinch(recognizer: UIPinchGestureRecognizer) {
        guard let mazeNode = mazeNode else {
            return
        }
        let scale = Float(recognizer.scale)
        mazeNode.scale = SCNVector3Make(mazeNode.scale.x * scale,
                                        mazeNode.scale.y * scale,
                                        mazeNode.scale.z * scale)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - Planes
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = Plane(anchor: planeAnchor)
        planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = planes.filter { $0.anchor.identifier == anchor.identifier }.first
        plane?.update(withAnchor: planeAnchor)
    }
    
    // MARK: - Actions
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        if mazeNode == nil {
            let touchPoint = recognizer.location(in: sceneView)
            if let result = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent).first {
                addMaze(with: result)
            }
            return
        }
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        let cameraPosition = SCNVector3Make(frame.camera.transform.columns.3.x,
                                            frame.camera.transform.columns.3.y,
                                            frame.camera.transform.columns.3.z)
        let touchPoint = recognizer.location(in: sceneView)
        if let result = sceneView.hitTest(touchPoint, options: [:]).first {
            let ratPosition = result.node.worldPosition
            let force = flatForceVector(for: ratPosition, second: cameraPosition)
            result.node.physicsBody?.applyForce(force, asImpulse: true)
        }
    }
    
    func addMaze(with result: ARHitTestResult) {
        guard let planeAnchor = result.anchor as? ARPlaneAnchor else {
            print("Not plane anchor")
            return
        }
        let plane = planes.filter { $0.anchor.identifier == planeAnchor.identifier }.first
        guard let unwrappedPlane = plane else {
            print("Not saved plane")
            return
        }
        unwrappedPlane.planeNode?.isHidden = true
        let mazeScene = SCNScene(named: "art.scnassets/Maze.scn")!
        let mazeNode = mazeScene.rootNode.clone()
        mazeNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
        mazeNode.position = SCNVector3Make(result.worldTransform.columns.3.x,
                                                     result.worldTransform.columns.3.y,
                                                     result.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(mazeNode)
        self.mazeNode = mazeNode
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    func flatForceVector(for first: SCNVector3, second: SCNVector3, forceVolume: Float = 0.15) -> SCNVector3 {
        let xForce = ((abs(first.x) - abs(second.x))) > 0 ? -forceVolume : forceVolume
        let zForce = ((abs(first.z) - abs(second.z))) > 0 ? -forceVolume : forceVolume
        return SCNVector3Make(xForce, 0, zForce)
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        lastForce = firstTouch.force
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        lastForce = firstTouch.force
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        lastForce = firstTouch.force
    }
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //        frame.camera.transform
    }
}
