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
        arSCNView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
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
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(arSCNView)
        arSCNView.delegate = self
        
        // 一个黑色环境
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        arSCNView.scene.rootNode.addChildNode(cameraNode)
//
//        cameraNode.position = SCNVector3Make(0, 50, 250);
//        cameraNode.camera?.zFar = 2000;
//        cameraNode.rotation =  SCNVector4Make(1, 0, 0, -Float.pi/16);
//
//        arSCNView.backgroundColor = UIColor.black
        
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
        sunNode.geometry = SCNSphere(radius: 3.0)
        earthNode.geometry = SCNSphere(radius: 1.0)
        moonNode.geometry = SCNSphere(radius: 0.5)
        
        sunNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "sun.jpg")
        sunNode.geometry?.firstMaterial?.multiply.contents = UIImage(named: "sun.jpg")
        earthNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "earth-diffuse-mini.jpg")
        earthNode.geometry?.firstMaterial?.emission.contents = UIImage(named: "earth-emission-mini.jpg")
        earthNode.geometry?.firstMaterial?.specular.contents = UIImage(named: "earth-specular-mini.jpg")
        moonNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "moon.jpg")
        
        sunNode.geometry?.firstMaterial?.multiply.intensity = 0.5 //強度
        sunNode.geometry?.firstMaterial?.lightingModel = .constant
        
        sunNode.geometry?.firstMaterial?.multiply.wrapS = .repeat
        sunNode.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        sunNode.geometry?.firstMaterial?.multiply.wrapT = .repeat
        sunNode.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        
        sunNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        earthNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        moonNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        
        // 地球反光
        earthNode.geometry?.firstMaterial?.shininess = 0.1
        earthNode.geometry?.firstMaterial?.specular.intensity = 0.5
        moonNode.geometry?.firstMaterial?.specular.contents = UIColor.gray
        
        // 位置
        sunNode.position = SCNVector3Make(0, -10, -20)
        earthPathNode.position = sunNode.position
        
        earthNode.position = SCNVector3Make(10, 0, 0)
        moonPathNode.position = earthNode.position
        
        moonNode.position = SCNVector3Make(3, 0, 0)
        
        // 节点层级关系
        arSCNView.scene.rootNode.addChildNode(sunNode)
        arSCNView.scene.rootNode.addChildNode(earthPathNode)
        
        earthPathNode.addChildNode(earthNode)
        earthPathNode.addChildNode(moonPathNode)
        
        moonPathNode.addChildNode(moonNode)
    }
    
    func setupAnimation() {
        
        // 月亮自转
        moonNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 4, z: 0, duration: 1)))
        
        // 地球自转
        earthNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // 太阳自转，这里采用
        var sunAnimation = CABasicAnimation(keyPath: "contentsTransform")
        sunAnimation.duration = 10.0
        sunAnimation.fromValue = CATransform3DConcat(CATransform3DMakeTranslation(0, 0, 0), CATransform3DMakeScale(3, 3, 3))
        sunAnimation.fromValue = CATransform3DConcat(CATransform3DMakeTranslation(1, 0, 0), CATransform3DMakeScale(3, 3, 3))
        sunAnimation.repeatCount = MAXFLOAT
        sunNode.geometry?.firstMaterial?.diffuse.addAnimation(sunAnimation, forKey: "sun rotation")
        
        sunAnimation = CABasicAnimation(keyPath: "contentsTransform")
        sunAnimation.duration = 30.0
        sunAnimation.fromValue = CATransform3DConcat(CATransform3DMakeTranslation(0, 0, 0), CATransform3DMakeScale(5, 5, 5))
        sunAnimation.fromValue = CATransform3DConcat(CATransform3DMakeTranslation(1, 0, 0), CATransform3DMakeScale(5, 5, 5))
        sunAnimation.repeatCount = MAXFLOAT
        sunNode.geometry?.firstMaterial?.multiply.addAnimation(sunAnimation, forKey: "sun rotation2")
        
        // 月亮公转
        moonPathNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: 1)))
        
        // 地球公转
        earthPathNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))

        /*
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
        let sunAnimation2 = CABasicAnimation(keyPath: "rotation")
        sunAnimation2.duration = 5
        sunAnimation2.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
        sunAnimation2.repeatCount = MAXFLOAT
        sunNode.addAnimation(sunAnimation2, forKey: "sun rotation")
         */
    }
    
    var sunHaloNode: SCNNode? // 太阳光环（晕）
    func setupLight() {
        // 太阳光
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.color = UIColor.black
        lightNode.light?.type = .omni
        lightNode.light?.attenuationStartDistance = 3.0
        lightNode.light?.attenuationEndDistance = 20.0
        sunNode.addChildNode(lightNode)
        
        // 动画
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.completionBlock = {
            lightNode.light?.color = UIColor.white
            self.sunHaloNode?.opacity = 0.5
        }
        SCNTransaction.commit()

        // 晕
        sunHaloNode = SCNNode()
        sunHaloNode?.geometry = SCNPlane(width: 25, height: 25)
        sunHaloNode?.rotation = SCNVector4Make(1, 0, 0, 0)
        sunHaloNode?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "sun-halo")
        sunHaloNode?.geometry?.firstMaterial?.lightingModel = .constant
        sunHaloNode?.geometry?.firstMaterial?.writesToDepthBuffer = false
        sunHaloNode?.opacity = 0.9
        sunNode.addChildNode(sunHaloNode!)
        
        // 地球公转轨道
        let earthOrbitNode = SCNNode()
        earthOrbitNode.opacity = 0.4
        earthOrbitNode.geometry = SCNPlane(width: 21, height: 21)
        earthOrbitNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "orbit")
        earthOrbitNode.geometry?.firstMaterial?.multiply.contents = UIImage(named: "orbit")
        earthOrbitNode.geometry?.firstMaterial?.lightingModel = .constant
        earthOrbitNode.geometry?.firstMaterial?.diffuse.mipFilter = .linear
        earthOrbitNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi/2)
        earthOrbitNode.geometry?.firstMaterial?.lightingModel = .constant
        sunNode.addChildNode(earthOrbitNode)
    }
}

