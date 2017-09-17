//
//  MainViewController.swift
//  Texturify
//
//  Created by Brian Wang on 9/16/17.
//  Copyright © 2017 BW. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class MainViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var textureButton: UIButton!
    
    let session = ARSession()
    let sessionConfig = ARWorldTrackingConfiguration()
    
    var dataPoints:[SCNVector3] = []
    var pointNodes:[SCNNode] = []
    var lineNodes:[SCNNode] = []
    
    var currentPlane:SCNNode!
    
    var textures = ["carvedlimestoneground", "granitesmooth", "oakfloor2", "old-textured-fabric", "rustediron-streaks", "sculptedfloorboards", "tron"]
    var currentTextureIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(MainViewController.tapped(recognizer:)))
        self.view.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        session.run(sessionConfig)
        uiSetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! TextureSelectViewController
        dest.textures = textures
        dest.callback = { index in
            self.currentTextureIndex = index
            self.updateTextureButton()
        }
    }
    
    func setupScene() {
        sceneView.delegate = self
        sceneView.session = session
        
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        
        resetValues()
    }
    
    func uiSetup() {
//        undoButton.transform = CGAffineTransform(rotationAngle: CGFloat(270 * Double.pi/180))
        textureButton.layer.cornerRadius = textureButton.frame.width / 6
        textureButton.clipsToBounds = true
        updateTextureButton()
    }
    
    func updateTextureButton() {
        DispatchQueue.main.async {
            let name = self.textures[self.currentTextureIndex]
            let image = UIImage(named: "./art.scnassets/\(name)/\(name)-albedo.png")!
            self.textureButton.setImage(image, for: .normal)
            self.updatePlane()
        }
    }
    
    func resetValues() {
        for point in pointNodes {
            point.removeFromParentNode()
        }
        for line in lineNodes {
            line.removeFromParentNode()
        }
        dataPoints = []
        pointNodes = []
        lineNodes = []
        updatePlane()
    }
    
    func updateResultLabel(_ value: Float) {
        let cm = value * 100.0
        let inch = cm * 0.3937007874
        distanceLabel.text = String(format: "%.2f cm / %.2f\"", cm, inch)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.detectObjects()
        }
    }
    
    func detectObjects() {
        if let worldPos = sceneView.realWorldVector(screenPosition: view.center) {
            if let last = dataPoints.last {
                updateResultLabel(worldPos.distance(from: last))
            } else {
                updateResultLabel(0.0)
            }
        }
    }
    
    @IBAction func clearButtonPressed(_ sender: UIButton) {
        resetValues()
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        if !dataPoints.isEmpty {
            dataPoints.removeLast()
        }
        if !pointNodes.isEmpty {
            let lastSphere = pointNodes.removeLast()
            lastSphere.removeFromParentNode()
        }
        if !pointNodes.isEmpty {
            let lastLine = lineNodes.removeLast()
            lastLine.removeFromParentNode()
        }
        updatePlane()
    }
    
    @IBAction func textureButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "textureSegue", sender: nil)
    }
    
    @objc func tapped(recognizer:UIGestureRecognizer) {
        if let worldPos = sceneView.realWorldVector(screenPosition: view.center) {
            if let lastPosition = dataPoints.last {
                createLine(start: lastPosition, stop: worldPos)
            }
            dataPoints.append(worldPos)
            createPoint(position: worldPos)
            updatePlane()
        }
    }
    
    func createPoint(position:SCNVector3) {
        let radius:CGFloat = 0.02
        let sphere = SCNSphere(radius: radius)
        let color = SCNMaterial()
        color.diffuse.contents = UIColor.white
        sphere.materials = [color]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        
        pointNodes.append(sphereNode)
        self.sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    func createLine(start:SCNVector3, stop:SCNVector3) {
        let line = SCNGeometry.lineFrom(vector: start, toVector: stop)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        line.materials = [material]
        let lineNode = SCNNode(geometry: line)
        lineNodes.append(lineNode)
        self.sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
    func clearPlane() {
        if let plane = currentPlane {
            plane.removeFromParentNode()
        }
    }
    
    func updatePlane() {
        clearPlane()
        if let geometry = SCNGeometry.planeFrom(points: dataPoints) {
            let material = SCNMaterial.materialNamed(name: textures[currentTextureIndex])
            material.isDoubleSided = true
            geometry.materials = [material]
            currentPlane = SCNNode(geometry: geometry)
            self.sceneView.scene.rootNode.addChildNode(currentPlane)
        }
    }

}
