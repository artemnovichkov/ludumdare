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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Maze.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - Actions
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
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
