//
//  ViewController.swift
//  Eyes Tracking
//
//  Created by Virakri Jinangkul on 6/6/18.
//  Copyright © 2018 virakri. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import WebKit
import Foundation

final class LogDestination: TextOutputStream {
  private let path: String
  init() {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    path = paths.first! + "/log"
    print(path)
  }

  func write(_ string: String) {
    if let data = string.data(using: .utf8), let fileHandle = FileHandle(forWritingAtPath: path) {
      defer {
        fileHandle.closeFile()
      }
      fileHandle.seekToEndOfFile()
      fileHandle.write(data)
    }
  }
}



@available(iOS 13.0, *)
class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    //@IBOutlet weak var webView: WKWebView!
    @IBOutlet var sceneView: ARSCNView!
    //@IBOutlet weak var blurBarView: UIVisualEffectView!
    @IBOutlet weak var lookAtPositionXLabel: UILabel!
    @IBOutlet weak var lookAtPositionYLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var circleXLabel: UILabel!
    @IBOutlet weak var circleYLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    var faceNode: SCNNode = SCNNode()
    
    var eyeLNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var eyeRNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var lookAtTargetEyeLNode: SCNNode = SCNNode()
    var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    // actual physical size of iPhoneX screen
    let phoneScreenSize = CGSize(width: 0.06451288343558282, height: 0.13962208588957056)
    
    // actual point size of iPhoneX screen
    let phoneScreenPointSize = CGSize(width: 414, height: 896)
    
    var randomX = CGFloat(207)
    var randomY = CGFloat(100)
    var count = 0
    
    var virtualPhoneNode: SCNNode = SCNNode()
    
    var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    var eyeLookAtPositionXs: [CGFloat] = []
    
    var eyeLookAtPositionYs: [CGFloat] = []
    
    var leftblinks: [Float] = []
    
    var errordistances: [CGFloat] = []
    
    var calibrationx: [Int] = []
    var calibrationy: [Int] = []
    var calibrationrealx: [Int] = []
    var calibrationrealy: [Int] = []
    var calibrationdis: [Int] = []
    var factdis: [Int] = []
    var aftery: [Int] = []
    
    var ya = 0.0
    var yb = 0.0
    
    var calibrationmode = 1
    
    var blink = 0
    
    var blinkcount = 0
    
    var tmpY = 0
    
    var tmpY_new = 0

    var circleView = UIImageView(image:UIImage(systemName: "circle.fill"))
    
    var lookatView = UIImageView(image:UIImage(systemName: "circle.fill"))
    
    var hideView = UIImageView(image:UIImage(systemName: "circle.fill"))
    
    
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //webView.load(URLRequest(url: URL(string: "https://www.apple.com")!))
        let viewWidth: CGFloat = view.frame.size.width
        let viewHeight: CGFloat = view.frame.size.height
        
        
        if #available(iOS 13.0, *) {

            // 画面の縦幅・横幅を取得
            

            // 画像に設定したい縦・横幅を変数に格納
            let circleWidth: CGFloat = 10
            let circleHeight: CGFloat = 10

            // 画像の座標・大きさを生成
            let circlerect: CGRect = CGRect(x: 0, y: 0, width: circleWidth, height: circleHeight)
            
            let lookcircle: CGRect = CGRect(x:0, y: 0, width:10, height: 10)
            
            let hidecircle: CGRect = CGRect(x:0, y: 0, width:200, height: 220)

            // 指定した座標・大きさを設定
            circleView.frame = circlerect;
            lookatView.frame = lookcircle;
            hideView.frame = hidecircle;

            // 画像を画面の中央を指定
            circleView.center = CGPoint(x: randomX, y: randomY)
            
            lookatView.center = CGPoint(x: 400, y:400)
            lookatView.tintColor = .systemRed
            lookatView.layer.zPosition = 1
            
            hideView.center = CGPoint(x: 350, y:800)
            hideView.tintColor = .systemBackground
            hideView.layer.zPosition = 1

            // viewにUIImageViewを追加
            self.view.addSubview(circleView)
            self.view.addSubview(lookatView)
            self.view.addSubview(hideView)
            
            
                
            sleep(3)
            print("X: ", self.randomX, " Y:", self.randomY, separator: " ")
        } else {
        }

        // UIImageViewの初期化
        
        
        // Setup Design Elements

        sceneView.layer.cornerRadius = 28

        
        //blurBarView.layer.cornerRadius = 36
        //blurBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        //webView.layer.cornerRadius = 16
        //webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Setup Scenegraph
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        // Set LookAtTargetEye at 2 meters away from the center of eyeballs to create segment vector
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        let blendShapes = faceAnchor.blendShapes
        guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? CGFloat,
            let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? CGFloat
            else{return}
        
        update(withFaceAnchor: faceAnchor)
    }
    
    // MARK: - update(ARFaceAnchor)
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        eyeRNode.simdTransform = anchor.rightEyeTransform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        
        var eyeblinkleft = anchor.blendShapes[.eyeBlinkLeft]
        var eyeblinkright = anchor.blendShapes[.eyeBlinkRight]
        
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        let heightCompensation: CGFloat = 312
        
        DispatchQueue.main.async {
            

            // Perform Hit test using the ray segments that are drawn by the center of the eyeballs to somewhere two meters away at direction of where users look at to the virtual plane that place at the same orientation of the phone screen
            
            let phoneScreenEyeRHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeRNode.worldPosition, to: self.eyeRNode.worldPosition, options: nil)
            
            let phoneScreenEyeLHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeLNode.worldPosition, to: self.eyeLNode.worldPosition, options: nil)
            
            for result in phoneScreenEyeRHitTestResults {
                
                eyeRLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeRLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            for result in phoneScreenEyeLHitTestResults {
                
                eyeLLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeLLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            // Add the latest position and keep up to 8 recent position to smooth with.
            let smoothThresholdNumber: Int = 10
            self.eyeLookAtPositionXs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
            self.eyeLookAtPositionYs.append(-(eyeRLookAt.y + eyeLLookAt.y) / 2)
            self.leftblinks.append(eyeblinkleft!.floatValue)
            self.leftblinks = Array(self.leftblinks.suffix(5))
            self.eyeLookAtPositionXs = Array(self.eyeLookAtPositionXs.suffix(smoothThresholdNumber))
            self.eyeLookAtPositionYs = Array(self.eyeLookAtPositionYs.suffix(smoothThresholdNumber))
            
            var x: Float = 0
            var check = 1
            if self.blink == 0{
                for item in self.leftblinks{
                    if item >= x{
                        x = item
                    }
                    else{
                        check = 0
                    }
                }
                if check == 1 && x > 0.1{
                    self.blink = 1
                }
            }
            else{
                x = 1
                for item in self.leftblinks{
                    if item <= x{
                        x = item
                    }
                    else{
                        check = 0
                    }
                }
                if check == 1 && x < 0.1{
                    self.blink = 0
                }
                if self.blinkcount > 30{
                    self.blink = 0
                }
            }
            
            
            let smoothEyeLookAtPositionX = self.eyeLookAtPositionXs.average!
            let smoothEyeLookAtPositionY = self.eyeLookAtPositionYs.average!
            
            // update indicator position

            if self.blink == 0{
                if self.calibrationmode == 1{
                    self.tmpY = Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2))
                }
                else{
                    self.tmpY_new = Int(self.ya * Double(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2)) + self.yb)
                    self.tmpY = Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2))
                }
                self.blinkcount = 0
            }
            
            if self.blink == 1{
                if self.calibrationmode == 1{
                    self.tmpY = Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2))
                }
                self.blinkcount += 1
            }
            // update eye look at labels values
            self.lookAtPositionXLabel.text = "\(Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2)))"
            
            self.lookAtPositionYLabel.text = String(self.tmpY)
            
            self.lookatView.center = CGPoint(x:Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2)), y: self.tmpY)
            
            // Calculate distance of the eyes to the camera
            let distanceL = self.eyeLNode.worldPosition - SCNVector3Zero
            let distanceR = self.eyeRNode.worldPosition - SCNVector3Zero
            
            // Average distance from two eyes
            let distance = (distanceL.length() + distanceR.length()) / 2
            
            // Update distance label value
            
            
            //self.distanceLabel.text = "\(Int(round(distance * 100))) cm"
            
            //self.circleXLabel.text = "\(Int(round(self.randomX)))"
            //self.circleYLabel.text = "\(Int(round(self.randomY)))"
            
            let tmperrordistance = sqrt(pow(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2 - self.randomX, 2.0) + pow(CGFloat(self.tmpY) - self.randomY, 2.0)) / 414 * 6.451288343558282
            
            self.errordistances.append(tmperrordistance)
            //self.errorLabel.text = "\(tmperrordistance) cm"
            
            
            
            //print("distance: ", terminator: " ")
            //print("\(Int(round(distance * 100)))")
            //print(self.errordistances.count, terminator: " ")
            //print(tmperrordistance)
            self.calibrationrealx.append(Int(self.randomX))
            self.calibrationrealy.append(Int(self.randomY))
            self.calibrationx.append(Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2)))
            self.calibrationy.append(self.tmpY)
            //print("\(Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2)))")
            //print(self.tmpY)
            //print("\(Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2 - self.randomX)))")
            //print("\(Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2 - self.randomY)))")
            //print("leftblink: ", terminator: " ")
            //print(eyeblinkleft)
            //print("rightblink: ", terminator: " ")
            //print(eyeblinkright)
            
            if self.calibrationmode == 1 {
                self.calibrationdis.append(Int(round(distance * 100)))
                self.randomY = self.randomY + 1
                self.circleView.center = CGPoint(x:self.randomX, y: self.randomY)
                self.view.addSubview(self.circleView)
                //print("X: ", self.randomX, " Y:", self.randomY, separator: " ")
                if self.errordistances.count == 600{
                    print(self.calibrationy)
                    print(self.calibrationdis)
                    self.calibrationmode = 0
                    self.errordistances = []
                    //print(self.calibrationrealx)
                    //print(self.calibrationrealy)
                    //print(self.calibrationx)
                    //print(self.calibrationy)
                    let m = self.calibrationx.count
                    //print(m)
                    let aveX = self.calibrationy.reduce(0, +) / m
                    let aveY = self.calibrationrealy.reduce(0, +) / m
                    let sxy = Float(zip(self.calibrationy.map{$0-aveX}, self.calibrationrealy.map{$0-aveY}).map(*).reduce(0, +) / m)
                    let sx = Float(zip(self.calibrationy.map{$0-aveX}, self.calibrationy.map{$0-aveX}).map(*).reduce(0, +) / m)
                    let a = sxy / sx
                    let b = Float(aveY) - Float(a) * Float(aveX)
                    self.ya = Double(a)
                    self.yb = Double(b)
                    self.calibrationy = []
                    self.calibrationx = []
                    self.calibrationrealy = []
                    self.calibrationrealx = []
                    self.calibrationdis = []
                    
                    print(a)
                    print(b)
                    sleep(10)
                    self.randomX = CGFloat(207)
                    self.randomY = CGFloat(100)
                    self.circleView.center = CGPoint(x: self.randomX, y: self.randomY)
                    self.view.addSubview(self.circleView)

                }
            }
            
            if self.calibrationmode == 0{
                self.aftery.append(self.tmpY_new)
                self.factdis.append(Int(round(distance * 100)))
                if self.errordistances.count == 1000{
                    self.errordistances = []
                    self.count = self.count + 1
                    self.randomX = CGFloat(207)
                    self.randomY = self.randomY + 100
                    self.circleView.center = CGPoint(x: self.randomX, y: self.randomY)
                    self.view.addSubview(self.circleView)
                    //print("X: ", self.randomX, " Y:", self.randomY, separator: " ")
                    sleep(1)
                    if self.count == 7{
                        print(self.calibrationrealy)
                        print(self.calibrationy)
                        print(self.aftery)
                        print(self.factdis)
                        let m = self.calibrationy.count
                        let errY = zip(self.calibrationy, self.calibrationrealy).map(-)
                        print(errY.count)
                        let errY_new = zip(self.aftery, self.calibrationrealy).map(-)
                        print(errY_new.count)
                        let errorY = zip(errY, errY).map(*).reduce(0, +) / m
                        let errorY_new = zip(errY_new, errY_new).map(*).reduce(0, +) / m
                        print(m)
                        print(errorY)
                        print(errorY_new)
                        sleep(1000)
                    }
                }
                
            }
            
            /*
            if self.errordistances.count == 2000 {
                //sleep(10000)
                self.count = self.count + 1
                if self.count == 15{
                    sleep(1000)
                }
                //self.circleView.removeFromSuperview()
                self.errordistances = []
                
                self.randomX = CGFloat(100 + 107 * (Int(self.count) % 3))
                self.randomY = CGFloat(100 + 150 * (Int(self.count) / 3))
                //self.randomX = CGFloat(Int.random(in: 100 ... 320))
                //self.randomY = CGFloat(Int.random(in: 100 ... 700))
                self.circleView.center = CGPoint(x: self.randomX, y: self.randomY)
                self.view.addSubview(self.circleView)
                sleep(1)
                print("X: ", self.randomX, " Y:", self.randomY, separator: " ")
            }
             */
            
            
            
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }
}
