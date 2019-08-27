//
//  ViewController.swift
//  Floor is lava
//
//  Created by 김예빈 on 2019. 2. 24..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    let motionManager = CMMotionManager()   // 가속도를 다룰 수 있는 객체
    
    var vehicle = SCNPhysicsVehicle() // 오브젝트가 차처럼 움직일 수 있게 다루기 위한 변수
    
    var orientation: CGFloat = 0    // 오브젝트 방향 설정을 위해 핸드폰의 방향을 감지
    
    var touched: Int = 0   // 오브젝트 운전을 위해 액정 터치를 감지
    // 한 손가락 -> 전진
    // 두 손가락 -> 후진
    // 세 손가락 -> 브레이크
    
    var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]   // 부드러운 움직임을 위해 이동평균을 저장할 변수 [x, y]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal // 수평 바닥을 감지
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        
        self.setUpAccelerometer()   // 오브젝트를 움직일 수 있는 함수 불러오기
        self.sceneView.showsStatistics = true
    }
    
    // 액정을 터치했을 때 차가 움직일 수 있게
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else {return}
        self.touched += touches.count   // 터치한 손가락 개수에 따라 값 증가
    }
    
    // 액정에서 손을 떼면 차가 멈출 수 있게
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = 0
    }
    
    // 용암 텍스쳐 생성
    // anchor를 이용해 용암의 크기를 정할 수 있음
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(CGFloat(planeAnchor.extent.z))))
        // height -> 떨어져있는 거리 값
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true  // 평면의 양면에 텍스쳐가 보일 수 있도록
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)    // 평면이 바닥 방향에 생성될 수 있도록 회전
        
        let staticBody = SCNPhysicsBody.static()    // Car 오브젝트와 충돌을 일으킬 수 있도록 고정
        concreteNode.physicsBody = staticBody
        return concreteNode
    }
    
    // 수평면을 처음으로 인식
    // add
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
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
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    
    // 같은 수평면에서 하나 더 인식하는 경우(오류) 제거
    // error -> remove
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    @IBAction func addCar(_ sender: Any) {
        guard let pointOfView = sceneView.pointOfView else {return}
        
        // AR Drawing 강의2 섹션3 참고
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)  // 3번째 열 -> orientation
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)    // 4번째 열 -> location
        let currentPositionOfCamera = orientation + location    // 카메라의 현재 위치는 방향 + 위치
        
        let scene = SCNScene(named: "Car-Scene.scn")    // Car scn 파일 불러오기
        // scn 파일의 각 오브젝트를 다룰 수 있도록 정의
        let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
        let frontLeftWheel = chassis.childNode(withName: "frontLeftParent", recursively: false)!
        let frontRightWheel = chassis.childNode(withName: "frontRightParent", recursively: false)!
        let rearLeftWheel = chassis.childNode(withName: "rearLeftParent", recursively: false)!
        let rearRightWheel = chassis.childNode(withName: "rearRightParent", recursively: false)!
        
        // 물리엔진 휠 정의
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel)
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel)
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel)
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel)
        
//        let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
//        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        
        chassis.position = currentPositionOfCamera
        
        // 물리엔진 적용
        // type: .dynamic -> 중력 적용
        // shape: SCNPhysicsShape -> 노드 설정
        // options:    [SCNPhysicsShape.Option.keepAsCompound: true] -> 여러개의 노드를 합쳐야하기 때문에 true, 단일이면 false도 OK
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options:    [SCNPhysicsShape.Option.keepAsCompound: true]))
        body.mass = 5   // default = 1, 무게를 설정함으로써 운전 속도를 늦출 수 있음
        chassis.physicsBody = body
        
        // 물리엔진을 실행시킬 변수에 휠 추가
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassis.physicsBody!, wheels: [v_rearRightWheel, v_rearLeftWheel, v_frontRightWheel, v_frontLeftWheel])
        
        // !!!매우 중요한 코드!!!  -> 물리엔진(자동차의 엔진처럼 움직이는 행동) 적용
        self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        // car랑 floor은 physics body -> physics world 의 일부분
        // 이 때 휠은 Y축을 기준으로 앞으로 움직이기 때문에 Y축이 위로 향해 있으면 위로 뜨려고 한다 그러므로 scn파일에서 Y축을 뒤집어주는 것이 필요
        
        self.sceneView.scene.rootNode.addChildNode(chassis)
    }
    
    // 프레임마다 세션을 불러오는 함수 -> 1초에 60번 불러옴
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        var engineForce: CGFloat = 0
        var breakingForce: CGFloat = 0
        
        // front wheel -> 방향 설정
        self.vehicle.setSteeringAngle(orientation, forWheelAt: 2)   // forWheelAt: 2 = v_frontRightWheel
        self.vehicle.setSteeringAngle(orientation, forWheelAt: 3)   // forWheelAt: 3 = v_frontLeftWheel
        
        if self.touched == 1 {  // 한 손가락 터치 -> 전진
            engineForce = 50
        } else if self.touched == 2 {   // 두 손가락 터치 -> 후진
            engineForce = -50
        } else  {   // 세 손가락 터치 -> 브레이크
            breakingForce = 100
            // engineForce = 0 은 멈추지 않음
        }
        
        // rear wheel -> 엔진 힘 설정
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 0)   // forWheelAt: 0 = v_rearRightWheel
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 1)   // forWheelAt: 1 = v_rearLeftWheel
        
        self.vehicle.applyBrakingForce(breakingForce, forWheelAt: 0)
        self.vehicle.applyBrakingForce(breakingForce, forWheelAt: 1)
    }
    
    // 핸드폰의 방향에 따라 accelerometer의 데이터를 불러옴 -> motion 라이브러리 필요
    func setUpAccelerometer() {
        
        // accelerometer -> 핸드폰을 수평으로 뒀을 때 X 값 최대 -> X 방향으로 최대의 중력이 적용되고 있다
        // 핸드폰을 수직으로 뒀을 때 Y 값 최대 -> Y 방향으로 최대의 중력이 적용되고 있다
        if motionManager.isAccelerometerAvailable {
            
            motionManager.accelerometerUpdateInterval = 1/60    // 1초에 60번 업데이트
            // main thread의 행동 감지
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.accelerometerDidChange(acceleration: accelerometerData!.acceleration)
            })
            
        } else {
            print("accelerometer not available")
        }
    }
    
    func accelerometerDidChange(acceleration: CMAcceleration) {
        accelerationValues[1] = filtered(currentAcceleration: accelerationValues[1], UpdatedAcceleration: acceleration.y)
        accelerationValues[0] = filtered(currentAcceleration: accelerationValues[0], UpdatedAcceleration: acceleration.x)
        
        // 핸드폰이 어느 방향의 수평으로 맞추던 조종은 같은 방향으로 할 수 있도록
        if accelerationValues[0] > 0 {
            self.orientation = CGFloat(accelerationValues[1])
        } else {
            self.orientation = -CGFloat(accelerationValues[1])
        }
//        print(acceleration.x)
//        print(acceleration.y)
//        print(acceleration.z) // 핸드폰 액정을 눕혔을 때
    }
    
    // acceleration 값의 부드러운 움직임을 위해 이동평균 구하기
    func filtered(currentAcceleration: Double, UpdatedAcceleration: Double) -> Double {
        let kfilteringFactor = 0.5
        return UpdatedAcceleration * kfilteringFactor + currentAcceleration * (1-kfilteringFactor)
    }
}

// SCNVector3 타입을 계산하기 위해 연산자 오버로딩
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}

// 각도를 일반적인 수학 원주율 각도로 계산할 수 있게 계산
extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
