//
//  ViewController.swift
//  Floor is lava
//
//  Created by 김예빈 on 2019. 2. 24..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal // 수평 바닥을 감지
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
    }
    
    // 용암 텍스쳐 생성
    // anchor를 이용해 용암의 크기를 정할 수 있음
    func createLava(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let lavaNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(CGFloat(planeAnchor.extent.z))))
        // height -> 떨어져있는 거리 값
        lavaNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "lava")
        lavaNode.geometry?.firstMaterial?.isDoubleSided = true  // 평면의 양면에 텍스쳐가 보일 수 있도록
        lavaNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        lavaNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)    // 평면이 바닥 방향에 생성될 수 있도록 회전
        return lavaNode
    }
    
    // 수평면을 처음으로 인식
    // add
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let lavdNode = createLava(planeAnchor: planeAnchor)
        node.addChildNode(lavdNode)
        print("new flat surface detected, new ARPlaneAnchor added")
    }
    
    // 처음 인식한 수평면이 한 화면에 다 들어오지 않는 넓은 경우 인식하도록 끊임없이 anchor를 업데이트
    // update
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        // anchor -> 수평면의 방향과 위치, 크기를 가짐
        print("updating floor's anchor...")
        
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
            // childNode는 let 타입이기 때문에 그 위에 새로 lavaNode를 추가할 수는 없다 -> 지우고 새로 생성
        }
        let lavaNode = createLava(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)
    }
    
    // 같은 수평면에서 하나 더 인식하는 경우(오류) 제거
    // error -> remove
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
}

// 각도를 일반적인 수학 원주율 각도로 계산할 수 있게 계산
extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
