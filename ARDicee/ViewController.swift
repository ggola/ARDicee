//
//  ViewController.swift
//  ARDicee
//
//  Created by Giulio Gola on 14/06/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    // Stores the dice we put on the plane
    var diceArray = [SCNNode]()
    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        // Shows as system is searching for a plane object
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        // Add light and shadows to scene view (to see the object in 3D)
        sceneView.autoenablesDefaultLighting = true
    }
    
    // MARK: - view Will Appear (Session configuration here!)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection (flat horizontal and vertical surfaces)
        configuration.planeDetection = .horizontal
        // Run the AR session
        sceneView.session.run(configuration)
    }
    
    // MARK: - view Will Disappear (Session closing)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the AR session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate protocol delegates
    // renderer: finds a plane.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Check if anchor is a plane
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // Create a node (plane) based on the anchor
        let planeNode = createPlane(with: planeAnchor)
        // Add the plane to rootNode (node = rootNode sceneView.scene.rootNode)
        node.addChildNode(planeNode)
    }
    
    // Plane rendering -> returns a node
    func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode {
        // Use the dimensions of the anchor to define the size of the (use .x and .z for horizontal and .x and .y for vertical planes)
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        // Create a plane node. Position: Center of the anchor (y = 0 -> no offset from where it was detected)
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        // Rotate the plane 90 degrees anti-clockwise around the x-axis
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2.0, 1, 0, 0)
        // Add material to plane to see it
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        plane.materials = [gridMaterial]
        // Set the geometry of the planeNode equal to the detected plane
        planeNode.geometry = plane
        return planeNode
    }
    
    // touchesBegan: detects touches on the SNNode in the view on the phone screen and interprets them as locations in the real world
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // touches is a set of UITouch instances
        if let touch = touches.first {
            // If user has touched a node in the view, get its location
            let touchLocation = touch.location(in: sceneView)
            // Convert the 2D to a 3D location. types: .existingPlaneUsingExtent = considers the plane real extension
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            // Take .first result of test as location of the dice
            if let hitResult = results.first {
                print(hitResult)
                addDice(at: hitResult)
            }
        }
    }
    
    // Add dice
    func addDice(at location: ARHitTestResult) {
        // Create a new scene with a dice
        let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        // Create a node from the scene
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            // Add position to the node from worldTransform component (real world position) of the ARHitTestResult
            diceNode.position = SCNVector3(
                CGFloat(location.worldTransform.columns.3.x),
                CGFloat(location.worldTransform.columns.3.y + diceNode.boundingSphere.radius),  // offset otherwise it is cut in half
                CGFloat(location.worldTransform.columns.3.z))
            // Append the node
            diceArray.append(diceNode)
            // Put the node into the scene
            sceneView.scene.rootNode.addChildNode(diceNode)
            // Roll the dice
            roll(dice: diceNode)
        }
    }
    
    // MARK: - Roll actions
    func roll(dice: SCNNode) {
        // Rotate by pi/2 steps the dice along the X and Z axis (Y is constant on plane): 4 faces with same probability.
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        // Rotation spins (otherwise max 1 full rotation)
        let randomSpinX = Float(arc4random_uniform(5))
        let randomSpinZ = Float(arc4random_uniform(5))
        // Run the rotation as an animation (runAction) on the diceNode
        dice.runAction(SCNAction.rotateBy(x: CGFloat(randomX * randomSpinX), y: 0, z: CGFloat(randomZ * randomSpinZ), duration: 0.5))
    }
    
    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    // MARK: - Remove dice from scene
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
}
