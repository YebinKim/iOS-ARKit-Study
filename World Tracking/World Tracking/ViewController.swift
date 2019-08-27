//
//  ViewController.swift
//  World Tracking
//
//  Created by 김예빈 on 2019. 2. 4..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()  // 스마트폰의 위치를 추적할 수 있게 하는 변수 configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin] // feature point -> 앱을 실행했을 때 주변 정보를 감지하기 위한 점
        self.sceneView.session.run(configuration)   // 앱이 실행되는 동안 늘 위치를 추적할 수 있게 함
        self.sceneView.autoenablesDefaultLighting = true  // specular를 볼 수 있도록 광원을 sceneView에 배치
    }

    @IBAction func add(_ sender: Any) {
//        let doorNode = SCNNode(geometry: SCNPlane(width: 0.03, height: 0.06))
//        doorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.brown
////        let cylinderNode = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.05))
//        let boxNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
//        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//        let node = SCNNode()
//
//          // 모양, 크기 설정
////        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.03)
////        node.geometry = SCNCapsule(capRadius: 0.1, height: 0.3)
////        node.geometry = SCNCone(topRadius: 0, bottomRadius: 0.3, height: 0.3)
////        node.geometry = SCNCone(topRadius: 0.1, bottomRadius: 0.1, height: 0.3) // = cylinder
////        node.geometry = SCNCylinder(radius: 0.1, height: 0.3)
////        node.geometry = SCNSphere(radius: 0.1)
////        node.geometry = SCNTube(innerRadius: 0.2, outerRadius: 0.3, height: 0.5)
////        node.geometry = SCNTorus(ringRadius: 0.3, pipeRadius: 0.1)
////        node.geometry = SCNPlane(width: 0.2, height: 0.2)
////        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
//
//          // custom shape 생성
////        let path = UIBezierPath()
////        path.move(to: CGPoint(x: 0, y: 0))  // 0 start
////        path.addLine(to: CGPoint(x: 0, y: 0.2)) // 0.2 upward -> height 0.2
////        path.addLine(to: CGPoint(x: 0.2, y: 0.3))   // 이 위치의 depth축과 평행한 선이 생긴다고 이해함
////        path.addLine(to: CGPoint(x: 0.4, y: 0.2))
////        path.addLine(to: CGPoint(x: 0.4, y: 0))
////        let shape = SCNShape(path: path, extrusionDepth: 0.2)   // 0.2 depth
////        node.geometry = shape
//
//        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
//        node.geometry?.firstMaterial?.specular.contents = UIColor.white  // specular 부여
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red  // 색 부여
//
//        // 랜덤 위치 부여 (-0.3~0.3 범위)
////        let x = randomNumbers(firstNum: -0.3, secondNum: 0.3)
////        let y = randomNumbers(firstNum: -0.3, secondNum: 0.3)
////        let z = randomNumbers(firstNum: -0.3, secondNum: 0.3)
//
//        node.position = SCNVector3(0.2,0.3,-0.2)   // 위치 조정
//        boxNode.position = SCNVector3(0, -0.05, 0)
//        doorNode.position = SCNVector3(0, -0.02, 0.053) // 0.05 = 5cm, 정확하게 boxNode와 겹치면 잘 안보이기 때문에 값 조정
//        self.sceneView.scene.rootNode.addChildNode(node)
//        node.addChildNode(boxNode)
//        boxNode.addChildNode(doorNode)
////        self.sceneView.scene.rootNode.addChildNode(cylinderNode)
        
        // 집을 만들어보자!
        let doorNode = SCNNode(geometry: SCNPlane(width: 0.03, height: 0.06))
        doorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.brown
        let boxNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
        
        node.geometry?.firstMaterial?.specular.contents = UIColor.orange
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        node.position = SCNVector3(0,0.2,-0.7)
//        node.eulerAngles = SCNVector3(Float(180.degreesToRadians),0,0)
        node.eulerAngles = SCNVector3(0,0,0)
        boxNode.position = SCNVector3(0, -0.05, 0)
        doorNode.position = SCNVector3(0,-0.02,0.053)
        
        self.sceneView.scene.rootNode.addChildNode(node)
        node.addChildNode(boxNode)
        boxNode.addChildNode(doorNode)
    }
    
    @IBAction func reset(_ sender: Any) {
        self.restartSession()
    }
    
    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {  // first~second 까지의 수를 갖는 난수
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min (firstNum, secondNum)
    }
}

extension Int { // 우리가 구현하고 싶은 90도를 정확하게 회전시킬 수 있게 확장
    
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}

