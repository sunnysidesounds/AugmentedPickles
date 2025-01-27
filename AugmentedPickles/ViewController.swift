//
//  ViewController.swift
//  AugmentedPickles
//
//  Created by Jason Alexander on 11/8/18.
//  Copyright © 2018 Jason Alexander. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var statsItem: UIBarButtonItem!
    @IBOutlet var pickleBlockerView: UIView!
    //@IBOutlet var pickleBlocker: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var statusLabel: UILabel!
    var assetCount: Int = 0
    var motionTimer: Timer!
    let motionManager = CMMotionManager()
    
    var planes = [UUID: VirtualPlane]() {
        didSet {
            if planes.count > 0 {
                currentStatus = .ready
            } else {
                if currentStatus == .ready { currentStatus = .initialized }
            }
        }
    }
    var currentStatus = ARSessionState.initialized {
        didSet {
            DispatchQueue.main.async {
                self.statusLabel.text = self.currentStatus.description                
            }
            if currentStatus == .failed {
                cleanupARSession()
            }
        }
    }
    var selectedPlane: VirtualPlane?
    var graphicsNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // configure settings and debug options for scene
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents]
        self.sceneView.automaticallyUpdatesLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // round corners of status label
        //statusLabel.layer.cornerRadius = 20.0
        statusLabel.layer.masksToBounds = true
        
        self.initializeNode()
        
        
        motionTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.getDeviceDegreesOfArc), userInfo: nil, repeats: true)

        
    }
    
    
    @objc func getDeviceDegreesOfArc(){
                if motionManager.isDeviceMotionAvailable {
            
                    motionManager.deviceMotionUpdateInterval = 0.1
            
                    motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] (motion, error) -> Void in
                
                    if let attitude = motion?.attitude {
                        let degrees = attitude.pitch * 180 / Double.pi
                        var arcDegree = (degrees / 100)
                        
                        //print("\(degrees) degrees")
                        DispatchQueue.main.async{
                            // Update UI
                            self?.statusLabel.text = "Currently \(Int(degrees)) degrees of arc"
                            if degrees > 60.0 {
                                
                                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                                    arcDegree = arcDegree + 0.12
                                    
                                    let rNumber: Int = self!.randomNumber()
                                    
                                    print("random int : \(rNumber)")
                                    
                                     let image: UIImage = UIImage(named: "pickleman")!
                                    
                                    
                                    let imageView = UIImageView(frame: CGRect(x: 16, y: 25, width: 343, height: 454))
                                    imageView.image = image
                                    self?.pickleBlockerView.addSubview(imageView)
                                    
                                    self?.pickleBlockerView.alpha = CGFloat(arcDegree)
                                    self?.statusLabel.textColor = .red
                                }, completion: nil)
                            } else {
                                 self?.pickleBlockerView.alpha = 0
                                self?.statusLabel.textColor = .white
                            }
                        }
                    }
            }
            print("Device motion started")
        }
        else {
            print("Device motion unavailable")
        }
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        if planes.count > 0 { self.currentStatus = .ready }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        self.currentStatus = .temporarilyUnavailable
    }
    
    func initializeNode() {
        let graphicsScene = SCNScene(named: "Patrick.dae")!
        self.graphicsNode = graphicsScene.rootNode.childNode(withName: "Patrick", recursively: true)!
    }
    
    // MARK: - Adding, updating and removing planes in the scene in response to ARKit plane detection.
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // create a 3d plane from the anchor
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
            print("Plane added: \(plane)")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            plane.updateWithNewAnchor(arPlaneAnchor)
            print("Plane updated: \(plane)")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            print("Plane updated: \(planes[index])")
            planes.remove(at: index)
        }
    }
    
    // MARK: - Cleaning up the session
    
    func cleanupARSession() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    
    // MARK: - Session tracking methods
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        self.currentStatus = .failed
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        self.currentStatus = .temporarilyUnavailable
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        self.currentStatus = .ready
    }
    
    // MARK: - Selecting planes and adding out coffee mug.
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            print("Unable to identify touches on any plane. Ignoring interaction...")
            return
        }
        if currentStatus != .ready {
            print("Unable to place objects when the planes are not ready...")
            return
        }
        
        let touchPoint = touch.location(in: sceneView)
        print("Touch happened at point: \(touchPoint)")
        if let plane = virtualPlaneProperlySet(touchPoint: touchPoint) {
            print("Plane touched: \(plane)")
            addToPlane(plane: plane, atPoint: touchPoint)
        } else {
            print("No plane was reached!")
        }
    }
    
    func virtualPlaneProperlySet(touchPoint: CGPoint) -> VirtualPlane? {
        let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] {
            self.selectedPlane = plane
            return plane
        }
        return nil
    }
    
    func addToPlane(plane: VirtualPlane, atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first {
            if let anotherMugYesPlease = graphicsNode?.clone() {
                anotherMugYesPlease.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
                self.assetCount = self.assetCount + 1
                self.statsItem.title = "\(self.assetCount) items"
                sceneView.scene.rootNode.addChildNode(anotherMugYesPlease)
            }
        }
    }
    
    func randomNumber<T : SignedInteger>(inRange range: ClosedRange<T> = 1...4) -> T {
        let length = Int64(range.upperBound - range.lowerBound + 1)
        let value = Int64(arc4random()) % length + Int64(range.lowerBound)
        return T(value)
    }


}
