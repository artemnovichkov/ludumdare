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
    
    fileprivate lazy var spotLightNode: SCNNode = {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 40
        spotLight.spotOuterAngle = 45
        spotLight.castsShadow = true
        
        let spotNode = SCNNode()
        spotNode.light = spotLight
        return spotNode
    }()
    
    fileprivate lazy var spotLight: SCNLight = {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 0
        spotLight.spotOuterAngle = 45
        spotLight.castsShadow = true
        return spotLight
    }()
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let scene = SCNScene(named: "art.scnassets/light_test.scn")!
        sceneView.scene = scene
        sceneView.session.delegate = self
        
//        spotLightNode.position = SCNVector3(0, 0, -1)
//        spotLightNode.eulerAngles = SCNVector3(-90, 0, 0)
//        sceneView.scene.rootNode.addChildNode(spotLightNode)

        timer = Timer(timeInterval: 0.2, repeats: true) { [unowned self] _ in
            if let transform = self.sceneView.session.currentFrame?.camera.transform {
                let cameraPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                self.spotLightNode.position = SCNVector3(0, 0, cameraPosition.z)
//                self.spotLightNode.worldPosition = SCNVector3(0, 0, cameraPosition.z)
                
//                print("camera position: \(SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z))")
            }
        }
//        RunLoop.current.add(timer, forMode: .commonModes)
        
        
        
        sceneView.pointOfView?.addChildNode(spotLightNode)
//        sceneView.pointOfView?.light = spotLight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingSessionConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Configurations
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        let transform = frame.camera.transform
//        let cameraPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//        spotLightNode.position = SCNVector3(0, 0, cameraPosition.z)
        
        print(spotLightNode.position)
        print(spotLightNode.worldPosition)
    }
}
