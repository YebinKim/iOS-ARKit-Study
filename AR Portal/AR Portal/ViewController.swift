//
//  ViewController.swift
//  AR Portal
//
//  Created by 김예빈 on 2019. 3. 1..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)  // 위치 읽어오기
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)  // 위치 중에서도 Plane 을 터치했을 때 반응
        
        // hitTestResult 값이 있을 때
        if !hitTestResult.isEmpty {
            self.addPortal(hitTestResult: hitTestResult.first!)
        } else {
            ////
        }
    }
    
    func addPortal(hitTestResult: ARHitTestResult) {
        let portalScene = SCNScene(named: "Portal.scnassets/Portal.scn")    // scn 폴더가 있어야 불러올 수 있음
        let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
        
        let transform = hitTestResult.worldTransform
        // transform 의 3번째 열에 position 정보가 있음
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition)
        
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        self.addPlane(nodeName: "roof", portalNode: portalNode, imageName: "top")
        self.addPlane(nodeName: "floor", portalNode: portalNode, imageName: "bottom")
        self.addWalls(nodeName: "backWall", portalNode: portalNode, imageName: "back")
        self.addWalls(nodeName: "sideWallA", portalNode: portalNode, imageName: "sideA")
        self.addWalls(nodeName: "sideWallB", portalNode: portalNode, imageName: "sideB")
        self.addWalls(nodeName: "sideDoorA", portalNode: portalNode, imageName: "sideDoorA")
        self.addWalls(nodeName: "sideDoorB", portalNode: portalNode, imageName: "sideDoorB")
    }
    
    // ARAnchor 가 감지될 때 실행
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        
        // 3초 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetected.isHidden = true
        }
    }
    
    // 벽에 이미지 추가 (box 오브젝트)
    func addWalls(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
        
        child?.renderingOrder = 200 // mask 를 제외한 노드는 잘 보이게
        // 반투명한 객체가 렌더링된 후 불투명한 객체가 렌더링되면 색상이 혼합되기 떄문에 불투명한 객체 먼저 렌더링될 수 있도록 벽 오브젝트의 렌더링 순서를 200이라는 아주 큰 숫자로 변경
        
        // 겉 면이 투명하게
        if let mask = child?.childNode(withName: "mask", recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.000001   // 투명도가 아주아주 낮아서 거의 투명한 상태
        }
    }
    
    // 천장과 바닥에 이미지 추가 (plane 오브젝트)
    func addPlane(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true) // root 노드는 Portal이고 원하는 이미지 정보가 redCarpet 노드 아래에 있기 떄문
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
        
        // 겉 면이 투명하게
        child?.renderingOrder = 200
        // wall의 mask가 렌더링되기 전에 렌더링될 수 있도록
    }

}

