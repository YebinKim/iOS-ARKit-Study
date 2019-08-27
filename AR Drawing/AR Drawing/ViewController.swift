//
//  ViewController.swift
//  AR Drawing
//
//  Created by 김예빈 on 2019. 2. 4..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    @IBOutlet var draw: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.showsStatistics = true   // 프레임 정보와 렌더링 정보를 표시
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
    }
    
    // 현실에서의 카메라의 현재 위치를 구함
    // 프레임마다 호출하는 함수 (func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)) 와 유사한 역할을 함
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform   // 변환행렬
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)   // 방향은 3번째 열에 정보를 담고 있음, 일반적인 오른손잡이 규칙에 따를 수 있게 값을 뒤집어줌
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)  // 위치는 4번째 열에 정보를 담고 있음
        let frontOfCamera = orientation + location  // CNVector 타입에 일반적인 + 연산자 사용 불가능하기 때문에 연산자 오버로딩, 드로잉이 될 위치
        
        DispatchQueue.main.async {
            if self.draw.isHighlighted {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                sphereNode.position = frontOfCamera
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                print("draw button is being pressed")
            }
            else {
                let pointer = SCNNode(geometry: SCNSphere(radius: 0.01))
                pointer.name = "pointer"
                pointer.position = frontOfCamera
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node.name == "pointer" {
                        node.removeFromParentNode()
                    }
                })
                self.sceneView.scene.rootNode.addChildNode(pointer)
                pointer.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                
            }
            
        }
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}
