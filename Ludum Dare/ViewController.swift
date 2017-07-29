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

    override func viewDidLoad() {
        super.viewDidLoad()

//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.delegate = self
//        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let scene = SCNScene(named: "art.scnassets/light_test.scn")!
        sceneView.scene = scene
        sceneView.session.delegate = self

//        spotLightNode.eulerAngles = SCNVector3(-90, 0, 0)
        spotLightNode.position = SCNVector3(0, 0, -0.1)
//        sceneView.scene.rootNode.addChildNode(spotLightNode)

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
        sceneView.session.pause()
    }
    
    // MARK: - Configurations
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = frame.camera.transform
        let eulerAngles = frame.camera.eulerAngles
        let cameraPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

//        spotLightNode.position = SCNVector3(spotLightNode.position.x, cameraPosition.y, cameraPosition.z)
//        spotLightNode.eulerAngles = SCNVector3(eulerAngles.x.toDegrees, eulerAngles.y.toDegrees, eulerAngles.z.toDegrees)

//        print(SCNVector3(eulerAngles.x.toDegrees, eulerAngles.y.toDegrees, eulerAngles.z.toDegrees))


//        print(spotLightNode.worldPosition)
//        print(spotLightNode.simdPosition)

//        print(spotLightNode.eulerAngles)
    }
}
