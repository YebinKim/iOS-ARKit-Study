//
//  ViewController.swift
//  Whack a jellyfish
//
//  Created by 김예빈 on 2019. 2. 23..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit
import Each // cocoapod을 통해 추가한 타이머 라이브러리

class ViewController: UIViewController {

    var timer = Each(1).seconds // 1초 단위로
    var countdown = 10  // 제한시간 10초
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var play: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        
        // 탭 제스쳐를 감지
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @IBAction func play(_ sender: Any) {
        self.setTimer()
        self.addNode()
        
        // play 버튼이 중복으로 눌리지 않도록 비활성화
        self.play.isEnabled = false
    }
    
    @IBAction func reset(_ sender: Any) {
        self.timer.stop()
        self.restoreTimer()
        self.play.isEnabled = true
        
        // 화면상의 모든 jellyfish 지우기
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    
    func addNode() {
//        let node = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0))
//        node.position = SCNVector3(0,0,-1)
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//        self.sceneView.scene.rootNode.addChildNode(node)
        
        // 필요없는 광원, 카메라는 .dae 파일에서 삭제
        // .dae 확장자 파일을 .scn 파일로 변환
        // .scnassets 확장자 폴더를 만들고 3d 모델 파일을 넣음
        let jellyFishScene = SCNScene(named: "art.scnassets/Jellyfish.scn")
        // 3d 모델 파일은 자식노드에 있음 -> 루트 노드에서부터 재귀적으로 찾을 수 있음
        let jellyfishNode = jellyFishScene?.rootNode.childNode(withName: "Jellyfish", recursively: false)
        // jellyfish가 world origin에서 일정한 범위의 랜덤 위치에서 나타날 수 있도록
        jellyfishNode?.position = SCNVector3(randomNumbers(firstNum: -1, secondNum: 1),randomNumbers(firstNum: -0.5, secondNum: 0.5),randomNumbers(firstNum: -1, secondNum: 1))
        self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
    }
    
    // Objective-C 문법
    @objc func handleTap(sender: UITapGestureRecognizer) {
        // 탭한 객체를 다룰 수 있게 함
        let sceneViewTappdeOn = sender.view as! SCNView
        let touchCoordinates = sender.location(in: sceneViewTappdeOn)
        let hitTest = sceneViewTappdeOn.hitTest(touchCoordinates)
        
        if hitTest.isEmpty {
            print("didn't touch anything")
        } else {
            if countdown > 0 {
                let results = hitTest.first!
                // 탭한 객체의 위치를 읽어올 수 있게 함
                //            let geometry = results.node.geometry
                //            print(geometry)
                let node = results.node
                
                // 애니메이션이 동작중일 때는 다시 눌러도 아무 일이 일어나지 않도록
                if node.animationKeys.isEmpty {
                    SCNTransaction.begin()
                    self.animatedNode(node: node)
                    
                    // 트랜잭션은 작업 수행 단위
                    // 애니메이션이 동작하는동안 다음 동작이 수행되지 않도록 제어
                    SCNTransaction.completionBlock = {
                        node.removeFromParentNode()
                        self.addNode()
                        self.restoreTimer()
                    }
                    SCNTransaction.commit()
                }
            }
        }
    }
    
    func animatedNode(node: SCNNode) {
        // CABasicAnimation 으로 할 수 있는 애니메이션 -> opacity, backgroundcolor, position
        // position을 이용해 spin을 줄 것
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.presentation.position // presentation -> sceneView에서 보이는 현재 상태
        spin.toValue = SCNVector3(node.presentation.position.x - 0.02, node.presentation.position.y - 0.02, node.presentation.position.z - 1) // world origin이 아닌 현재 위치를 기준으로 움직이게 하기 위해
        spin.duration = 0.07
        spin.autoreverses = true    // 다시 원래위치로 돌아오도록 반복
        spin.repeatCount = 5
        node.addAnimation(spin, forKey: "position")
    }
    
    // 랜덤 위치 지정
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func setTimer() {
        self.timer.perform { () -> NextStep in
            self.countdown -= 1
            self.timerLabel.text = String(self.countdown)
            
            // 타이머가 0이 된 경우 멈추기
            if self.countdown == 0 {
                self.timerLabel.text = "you lose"
                return .stop
            }
            
            return .continue    // closure 타입 리턴 변수 -> 반복하도록
        }
    }
    
    // 시간 내에 jellyfish를 잡으면 시간 초기화
    func restoreTimer() {
        self.countdown = 10
        self.timerLabel.text = String(self.countdown)
    }
}

