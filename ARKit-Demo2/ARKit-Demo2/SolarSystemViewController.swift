//
//  SolarSystemViewController.swift
//  ARKit-Demo2
//
//  Created by 刘文 on 2017/9/6.
//  Copyright © 2017年 刘文. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class SolarSystemViewController: UIViewController, ARSCNViewDelegate {

    lazy var arSCNView: ARSCNView = {
        let arSCNView = ARSCNView(frame: view.bounds)
        arSCNView.session = arSession
        arSCNView.automaticallyUpdatesLighting = true
        return arSCNView
    }()
    lazy var arSession: ARSession = ARSession()
    var arConfiguration: ARConfiguration?
    
    // node
    var sunNode: SCNNode!
    var earthNode: SCNNode!
    var moonNode: SCNNode!
    
    var earthPathNode: SCNNode! // 黄道(ecliptic)，控制地球公转
    var moonPathNode: SCNNode! // 白道，控制月球公转
    
    // MARK: VC
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(arSCNView)
        arSCNView.delegate = self
        
        setupNodes()
        setupAnimation()
        setupLight()
        
        // 返回按钮
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.setTitle("<-back", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.frame = CGRect(x: 20, y: 20, width: 60, height: 28)
        btn.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        
        view.addSubview(btn)
    }
    
    @objc fileprivate func btnClick(_ btn: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration!.isLightEstimationEnabled = true
        arSession.run(arConfiguration!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        arSession.pause()
    }
    
    func setupNodes() {
        // 创建节点
        sunNode = SCNNode()
        earthNode = SCNNode()
        moonNode = SCNNode()
        earthPathNode = SCNNode()
        moonPathNode = SCNNode()
        
        // 几何形与渲染
        sunNode.geometry = SCNSphere(radius: 3)
        earthNode.geometry = SCNSphere(radius: 1)
        moonNode.geometry = SCNSphere(radius: 0.3)
        
        sunNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "sun.jpg")
        earthNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "earth-diffuse-mini.jpg")
        moonNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "moon.jpg")
        
        sunNode.position = SCNVector3Make(0, 0, -30)
        earthPathNode.position = sunNode.position
        
        earthNode.position = SCNVector3Make(10, 0, 0)
        moonPathNode.position = earthNode.position
        
        moonNode.position = SCNVector3Make(2, 0, 0)
        
        // 节点层级关系
        arSCNView.scene.rootNode.addChildNode(sunNode)
        arSCNView.scene.rootNode.addChildNode(earthPathNode)
        
        earthPathNode.addChildNode(earthNode)
        earthPathNode.addChildNode(moonPathNode)
        
        moonPathNode.addChildNode(moonNode)
    }
    
    func setupAnimation() {
        // 月亮公转
        let moonPathAnimation = CABasicAnimation(keyPath: "rotation")
        moonPathAnimation.duration = 3
        moonPathAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        moonPathAnimation.repeatCount = MAXFLOAT
        moonPathNode.addAnimation(moonPathAnimation, forKey: "moon rotation around earth")
        
        // 地球公转
        let earthPathAnimation = CABasicAnimation(keyPath: "rotation")
        earthPathAnimation.duration = 15
        earthPathAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        earthPathAnimation.repeatCount = MAXFLOAT
        earthPathNode.addAnimation(earthPathAnimation, forKey: "earth rotation around sun")
        
        // 月亮自转
        let moonAnimation = CABasicAnimation(keyPath: "rotation")
        moonAnimation.duration = 0.5
        moonAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        moonAnimation.repeatCount = MAXFLOAT
        moonNode.addAnimation(moonAnimation, forKey: "moon rotation")
        
        // 地球自转
        let earthAnimation = CABasicAnimation(keyPath: "rotation")
        earthAnimation.duration = 0.5
        earthAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        earthAnimation.repeatCount = MAXFLOAT
        earthNode.addAnimation(earthAnimation, forKey: "earth rotation")
        
        // 太阳自转
        let sunAnimation = CABasicAnimation(keyPath: "rotation")
        sunAnimation.duration = 5
        sunAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        sunAnimation.repeatCount = MAXFLOAT
        sunNode.addAnimation(sunAnimation, forKey: "sun rotation")
    }
    
    var sunHaloNode: SCNNode? // 太阳光环（晕）
    func setupLight() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.color = UIColor.red
        sunNode.addChildNode(lightNode)
        
        lightNode.light?.attenuationStartDistance = 1.0
        lightNode.light?.attenuationEndDistance = 20.0
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.completionBlock = {
            lightNode.light?.color = UIColor.white
            self.sunHaloNode?.opacity = 0.5
        }
        SCNTransaction.commit()
        
        sunHaloNode = SCNNode()
        sunHaloNode?.geometry = SCNPlane(width: 25, height: 25)
        sunHaloNode?.rotation = SCNVector4Make(0, 1, 0, 0 * Float.pi / 180.0)
        sunHaloNode?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "sun-halo")
        sunHaloNode?.geometry?.firstMaterial?.lightingModel = .constant
        sunHaloNode?.geometry?.firstMaterial?.writesToDepthBuffer = false
        sunHaloNode?.opacity = 0.9
        sunNode.addChildNode(sunHaloNode!)
    }
}
