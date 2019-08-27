//
//  ViewController.swift
//  Ikea
//
//  Created by 김예빈 on 2019. 2. 26..
//  Copyright © 2019년 김예빈. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {

    @IBOutlet var planeDetected: UILabel!
    
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]   // 이름이 소스와 일치해야함
    var selectedItem: String?    // 선택한 셀의 이름을 반환하기 위한 변수
    
    @IBOutlet var itemsCollectionView: UICollectionView!
    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        
        self.itemsCollectionView.dataSource = self  // 콜렉션뷰 내용 설정
        self.itemsCollectionView.delegate = self    // 하이라이트 효과 설정
        self.sceneView.delegate = self  // plane 감지 레이블 표시 설정
        
        self.registerGestureRecognizers()   // sceneView의 제스쳐 감지
        
        self.sceneView.autoenablesDefaultLighting = true    // 광원을 현실처럼 설정
        
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1   // longPress 딜레이 시간 설정
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        
        let hitTest = sceneView.hitTest(pinchLocation)  // 오브젝트의 위치와 pinch 위치가 같을 때만 대입
        
        // hitTest에 값이 있을 때 -> 오브젝트의 위치와 hitTest 위치가 같을 때
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            
            // pinch 거리에 따라 오브젝트 크기 조절
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)    // duration: 0 -> pinch 하는 즉시 크기가 조절됨(딜레이가 없음)
            print(sender.scale)
            node.runAction(pinchAction) // 오브젝트 크기가 조절됨
            sender.scale = 1.0  // 값이 기하급수적으로 커지지 않도록 기준값을 1.0 으로 설정
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)  // plane을 탭했을 경우 값을 대입
        
        // hitTest배열의 첫 번째 요소에 위치가 들어있음
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))! // recursively가 true -> 전체 트리를 탐색하게 됨, false -> 원하는 노드를 찾으면 탐색 종료
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3   // world origin의 위치 값은 3번째 열에 있음
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            
            // table의 pivot 값이 오브젝트의 중심 값과 일치하지 않기 때문에 변경 필요
            if selectedItem == "table" {
                self.centerPivot(for: node)
            }
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    // 콜렉션뷰에서 몇 개의 셀을 보여줄지 결정
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    // 콜렉션뷰 셀의 이름을 배열의 요소로 설정
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCell
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        return cell
    }
    
    // 콜렉션뷰 셀을 선택했을 때 하이라이트 효과 주기
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = itemsArray[indexPath.row]   // 선택한 셀의 이름을 반환하기 위한 변수
        cell?.backgroundColor = UIColor.green
    }
    
    // 콜렉션뷰 셀을 선택하고 다른 셀을 선택했을 때 색 원래대로 변경
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.orange
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        
        // main thread 에서 동작할 수 있도록
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
            
            // 3초 뒤 사라지도록
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetected.isHidden = true
            }
        }
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        
        let hitTest = sceneView.hitTest(holdLocation)   // 오브젝트의 위치와 손가락 위치가 같을 때만 대입
        
        if !hitTest.isEmpty {
            let result = hitTest.first!
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)  // 오브젝트 회전
            } else if sender.state == .ended {
                result.node.removeAllActions()
            }
        }
    }
    
    // 오브젝트의 중심을 기준으로 회전할 수 있도록 -> Xcode에서 자체적으로 중심 값을 움직일 수는 없음
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
