//
//  ViewController.swift
//  AR Shooter
//
//  Created by 김예빈 on 2019. 3. 5..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    var power: Float = 50   // bullet 이 중력을 적용하는 값 조절
    var Target: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        
        self.sceneView.autoenablesDefaultLighting = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = position
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))   // type: .dynamic -> 움직이는 물리 오브젝트
        body.isAffectedByGravity = false    // body 가 직선으로 나아갈 수 있도록
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)  // direction 과 asImpulse: true(즉각 반응) 설정
        
        // BitMaskCategory -> 열겨형 타입 정수
        // BitMaskCategory.target.rawValue = 2
        // BitMaskCategory.bullet.rawValue = 3
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        
        self.sceneView.scene.rootNode.addChildNode(bullet)
        
        // 오브젝트 충돌(runAction) 시 bullet이 2초 후 사라지도록
        bullet.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 2.0), SCNAction.removeFromParentNode()]))
    }
    
    @IBAction func addTargets(_ sender: Any) {
        // egg의 거리를 아주 멀게
        self.addEgg(x: 5, y: 0, z: -40)
        self.addEgg(x: 0, y: 0, z: -40)
        self.addEgg(x: -5, y: 0, z: -40)
    }
    
    // egg를 불러오는 함수
    func addEgg(x: Float, y: Float, z: Float) {
        let eggScene = SCNScene(named: "Media.scnassets/egg.scn")
        let eggNode = (eggScene?.rootNode.childNode(withName: "egg", recursively: false))!
        eggNode.position = SCNVector3(x,y,z)
        
        // egg 와 bullet 이 collide 를 일으킬 수 있도록 type: .static 설정
        // 두 eggNode 사이의 contact detection 을 수행하기 위해 shape: SCNPhysicsShape(node: eggNode, options: nil) 지정
        eggNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: eggNode, options: nil))
        
        eggNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        eggNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        
        self.sceneView.scene.rootNode.addChildNode(eggNode)
    }
    
    // 두 오브젝트의 충돌을 감지할 때 마다 불러오는 함수
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeA
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.Target = nodeB
        }
        
        // egg 가 충돌했을 때 particle 애니메이션 실행
        let confetti = SCNParticleSystem(named: "Media.scnassets/Confetti.scnp", inDirectory: nil)
        confetti?.loops = false // 반복하지 않음
        confetti?.particleLifeSpan = 4  // 4초간 지속
        confetti?.emitterShape = Target?.geometry   // Target 오브젝트를 바운더리로 애니메이션 실행
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(confetti!)
        confettiNode.position = contact.contactPoint    // 위치 지정
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
        Target?.removeFromParentNode()  // 충돌 시 삭제
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
