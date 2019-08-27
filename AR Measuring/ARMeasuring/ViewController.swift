//
//  ViewController.swift
//  ARMeasuring
//
//  Created by 김예빈 on 2019. 2. 27..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var xLabel: UILabel!
    @IBOutlet var yLabel: UILabel!
    @IBOutlet var zLabel: UILabel!
    
    var startingPosition: SCNNode?
    
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin, SCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.delegate = self
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        
        // startingPosition이 중복으로 생기지 않도록
        if self.startingPosition != nil {
            self.startingPosition?.removeFromParentNode()
            self.startingPosition = nil
            return
        }
        
        guard let currentFrame = sceneView.session.currentFrame else {return}   // camera 속성에 접근할 수 있게 해주는 currentFrame (2번째 방법, 1번째 방법은 AR Drawing에서 쓴 것
        let camera = currentFrame.camera    // currentFrame.camera 는 카메라의 현재 위치, 방향, 이미지를 배열에 포함함
        let transform = camera.transform    // transform 은 4x4 배열, 현재 카메라의 위치는 정확하게 transform과 같다
                                            // transform = standard linearly independent matrix (선형대수)
        
        var translationMatrix = matrix_identity_float4x4    // sphere의 위치를 이동하기 위한 변수, 선형 독립적이기 때문에 여기에는 어떤 연산을 해도 계산되지 않음
        translationMatrix.columns.3.z = -0.1    // 정확한 카메라의 위치가 아닌, 정면으로 10센치 거리를 둠
        var modifiedMatrix = simd_mul(transform, translationMatrix) // 행렬의 곱셈 연산 수행
        
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.005))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        sphere.simdTransform = modifiedMatrix   // simdTransform는 카메라의 위치가 sphere의 위치와 같게 접근할 수 있게 해줌
        self.sceneView.scene.rootNode.addChildNode(sphere)
        self.startingPosition = sphere
    }
    
    // 프레임마다 호출
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let startingPosition = self.startingPosition else {return}
        
        // 카메라의 현재 위치 인식
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        
        // startingPosition 과 카메라의 차이값 계산
        let xDistance = location.x - startingPosition.position.x
        let yDistance = location.y - startingPosition.position.y
        let zDistance = location.z - startingPosition.position.z
        DispatchQueue.main.async {
            print("frererff")
            self.xLabel.text = String(format: "%.2f", xDistance) + "m"  // 소수점 2째자리까지 표시
            self.yLabel.text = String(format: "%.2f", yDistance) + "m"
            self.zLabel.text = String(format: "%.2f", zDistance) + "m"
            self.distanceLabel.text = String(format: "%.2f", self.distanceTravelled(x: xDistance, y: yDistance, z: zDistance)) + "m"
        }
    }
    
    // 거리 계산을 위한 함수
    func distanceTravelled(x: Float, y: Float, z: Float) -> Float {
        
        return (sqrtf(x*x + y*y + z*z))
    }
}
