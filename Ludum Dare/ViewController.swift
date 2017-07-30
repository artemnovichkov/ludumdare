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

final class ViewController: UIViewController, ARSCNViewDelegate {
    
    enum State {
        case playing
        case gameOver
        case surfaceFinding
    }
    
    fileprivate enum Battery {
        static let fullEnergy: CGFloat = 500
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var progressView: UIView!
    
    @IBOutlet weak var widthProgressConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxProgressConstraint: NSLayoutConstraint!
    
    fileprivate lazy var spotLight: SCNLight = {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 0
        spotLight.spotOuterAngle = 45
        spotLight.castsShadow = true
        return spotLight
    }()
    
    var currentState: State = .surfaceFinding
    var currentEnergy = Battery.fullEnergy {
        didSet {
            if currentEnergy <= 0 {
                currentState = .gameOver
            }
            else {
                let progress = (currentEnergy * 100) / Battery.fullEnergy
                widthProgressConstraint.constant = maxProgressConstraint.constant * progress/100
                view.setNeedsUpdateConstraints()
                view.updateConstraintsIfNeeded()
            }
        }
    }
    
    var lastForce: CGFloat = 0 {
        didSet {
            if currentState == .playing {
                spotLight.intensity = lastForce * 200
            }
        }
    }
    
    var planes = [Plane]()
    var mazeNode: SCNNode?
    var gameTimer: Timer?

    deinit {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.pointOfView?.light = spotLight
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        progressView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Methods
    
    private func startGame() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [unowned self] _ in
            self.currentEnergy -= self.lastForce
        }
        RunLoop.current.add(timer, forMode: .commonModes)
        gameTimer = timer
        currentState = .playing
        progressView.isHidden = false
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
        mazeNode.position = SCNVector3Make(result.worldTransform.columns.3.x,
                                                     result.worldTransform.columns.3.y,
                                                     result.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(mazeNode)
        self.mazeNode = mazeNode
        
        startGame()
    }
    
    func flatForceVector(for first: SCNVector3, second: SCNVector3, forceVolume: Float = 0.15) -> SCNVector3 {
        let xForce = ((abs(first.x) - abs(second.x))) > 0 ? -forceVolume : forceVolume
        let zForce = ((abs(first.z) - abs(second.z))) > 0 ? -forceVolume : forceVolume
        return SCNVector3Make(xForce, 0, zForce)
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}

// MARK: - Touches

extension ViewController {
    
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
        lastForce = 0
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastForce = 0
    }
}
