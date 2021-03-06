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
        case win
    }
    
    enum Paw {
        case left
        case up
        case right
        case down
        case none
    }
    
    var currentPaw: Paw = .none
    
    fileprivate enum Battery {
        static let fullEnergy: CGFloat = 400
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var progressView: UIView!
    
    @IBOutlet weak var widthProgressConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxProgressConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate lazy var spotLight: SCNLight = {
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 0
        spotLight.spotOuterAngle = 45
        spotLight.castsShadow = true
        return spotLight
    }()
    
    var currentState: State = .surfaceFinding {
        didSet {
            switch currentState {
            case .gameOver:
                let alertController = UIAlertController(title: "ALERT", message: "GAME OVER", preferredStyle: .alert)
                present(alertController, animated: true, completion: nil)
            case .win:
                let alertController = UIAlertController(title: "ALERT", message: "WIN!!!", preferredStyle: .alert)
                present(alertController, animated: true, completion: nil)
            default:
                break
            }
        }
    }
    
    
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
    var ratNode: SCNNode?
    var gameTimer: Timer?
    var positionTimer: Timer?
    
    deinit {
        gameTimer?.invalidate()
        gameTimer = nil
        
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.pointOfView?.light = spotLight
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene.physicsWorld.contactDelegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        progressView.isHidden = true
        
        upButton.isHidden = true
        leftButton.isHidden = true
        rightButton.isHidden = true
        downButton.isHidden = true
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
        sceneView.debugOptions = []
        
        upButton.isHidden = false
        leftButton.isHidden = false
        rightButton.isHidden = false
        downButton.isHidden = false
        
        let source = SCNAudioSource(fileNamed: "art.scnassets/sounds/music.m4a")!
        source.volume = 0.25
        source.loops = true
        source.shouldStream = true
        source.isPositional = false
        let player = SCNAudioPlayer(source: source)
        sceneView.scene.rootNode.addAudioPlayer(player)
        
        let timer = Timer(timeInterval: 0.5, repeats: true) { [unowned self] _ in
            self.currentEnergy -= self.lastForce
        }
        
        let positionTimer = Timer(timeInterval: 0.1, repeats: true) { [unowned self] _ in
            if self.currentPaw == .none {
                return
            }
            
            guard let ratNode = self.ratNode else {
                return
            }
            
            if self.currentPaw == .left {
                ratNode.position.x += 0.2
            }
            if self.currentPaw == .up {
                ratNode.position.z += 0.2
            }
            if self.currentPaw == .right {
                ratNode.position.x -= 0.2
            }
            if self.currentPaw == .down {
                ratNode.position.z -= 0.2
            }
            
            if ratNode.position.z > 40 {
                self.currentState = .win
                self.positionTimer?.invalidate()
            }
        }

        RunLoop.current.add(timer, forMode: .commonModes)
        RunLoop.current.add(positionTimer, forMode: .commonModes)
        
        
        self.positionTimer = positionTimer
        gameTimer = timer
        currentState = .playing
        progressView.isHidden = false
    }
    
    // MARK: - Planes
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if planes.count > 0 {
            return
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        guard currentState == .surfaceFinding else {
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
    
    @objc func pinch(recognizer: UIPinchGestureRecognizer) {
        guard let mazeNode = mazeNode else {
            return
        }
        let scale = Float(recognizer.scale)
        mazeNode.scale = SCNVector3Make(mazeNode.scale.x * scale,
                                        mazeNode.scale.y * scale,
                                        mazeNode.scale.z * scale)
    }
    
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        guard let mazeNode = mazeNode else {
            return
        }
        
        let x: CGFloat
        let z: CGFloat
        
        let velocity = recognizer.velocity(in: sceneView)
        if velocity.x > 0 {
            x = 0.1
        }
        else {
            x = -0.1
        }
        
        if velocity.y > 0 {
            z = 0.1
        }
        else {
            z = -0.1
        }
        
        //        mazeNode.position = SCNVector3(
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
        mazeNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        mazeNode.position = SCNVector3Make(result.worldTransform.columns.3.x,
                                           result.worldTransform.columns.3.y,
                                           result.worldTransform.columns.3.z)
        let planeRotation = unwrappedPlane.planeNode!.rotation
        mazeNode.rotation = SCNVector4Make(planeRotation.x, planeRotation.y, planeRotation.z, 0)
        sceneView.scene.rootNode.addChildNode(mazeNode)
        self.mazeNode = mazeNode
        
        ratNode = mazeNode.childNode(withName: "rat", recursively: true)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        startGame()
    }
    
    func flatForceVector(for first: SCNVector3, second: SCNVector3, forceVolume: Float = 0.2) -> SCNVector3 {
        let xForce = ((abs(first.x) - abs(second.x))) > 0 ? -forceVolume : forceVolume
        let zForce = ((abs(first.z) - abs(second.z))) > 0 ? -forceVolume : forceVolume
        return SCNVector3Make(xForce, 0, zForce)
    }
    
    @IBAction func touchDown(_ sender: UIButton) {
        guard let ratNode = self.ratNode else {
            return
        }
        
        if sender.tag == 0 {
            currentPaw = .left
            ratNode.eulerAngles = SCNVector3Make(0, Float(Double.pi / 2), 0);
        }
        if sender.tag == 1 {
            currentPaw = .up
            ratNode.eulerAngles = SCNVector3Make(0, 0, 0);
        }
        if sender.tag == 2 {
            currentPaw = .right
            ratNode.eulerAngles = SCNVector3Make(0, Float(Double.pi * 1.5), 0);
        }
        if sender.tag == 3 {
            currentPaw = .down
            ratNode.eulerAngles = SCNVector3Make(0, Float(Double.pi), 0);
        }
        
        if ratNode.position.z > 40 {
            currentState = .win
            self.positionTimer?.invalidate()
        }
    }
    
    @IBAction func moveButtonAction(_ sender: Any) {
        currentPaw = .none
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

extension ViewController: SCNPhysicsContactDelegate {
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("didBegin")
    }
}
