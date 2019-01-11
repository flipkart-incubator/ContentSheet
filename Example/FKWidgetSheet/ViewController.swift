/*
 * Apache License
 * Version 2.0, January 2004
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
 *
 * Copyright (c) 2017 Flipkart Internet Pvt. Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of the
 * License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */


import UIKit
import ContentSheet


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UINavigationBar.appearance().barTintColor = UIColor.purple
        
        self._craeteShapeLayer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var canPresent = false
    var a: SecondViewController?
    private var iconLayer: CAShapeLayer!
    
    private func _craeteShapeLayer() {
        
        let iconPath = UIBezierPath()
        iconPath.move(to: CGPoint(x: 26.5, y: 0.5))
        iconPath.addLine(to: CGPoint(x: 20.5, y: 0.5))
        iconPath.addLine(to: CGPoint(x: 16.5, y: 5.5))
        iconPath.addLine(to: CGPoint(x: 13.5, y: 25.5))
        iconPath.addLine(to: CGPoint(x: 10.5, y: 45.5))
        iconPath.addLine(to: CGPoint(x: 6.5, y: 50.5))
        iconPath.addLine(to: CGPoint(x: 0.5, y: 50.5))
        iconPath.move(to: CGPoint(x: 0.5, y: 25.5))
        iconPath.addLine(to: CGPoint(x: 25.5, y: 25.5))
        
        iconLayer = CAShapeLayer()
        iconLayer.path = iconPath.cgPath
        iconLayer.strokeColor = UIColor.white.cgColor
        iconLayer.fillColor = UIColor.clear.cgColor
        iconLayer.lineWidth = 5
        
        var iconLayerFrame = self.view.bounds
        iconLayerFrame.size.height = 60
        iconLayerFrame.size.width = 26
        iconLayerFrame.origin.x = (self.view.bounds.width - iconLayerFrame.size.width)/2
        iconLayerFrame.origin.y = 88
        
        iconLayer.frame = iconLayerFrame
        iconLayer.transform = CATransform3DScale(CATransform3DIdentity, 2.5, 2.5, 1)
        
        self.view.layer.addSublayer(iconLayer)
    }
    
    private func _animateIcon() {
        let pathAnimation = CABasicAnimation(keyPath: "strokeStart")
        pathAnimation.duration = 1.5
        pathAnimation.fromValue = -2.0
        pathAnimation.toValue = 1.0
        pathAnimation.autoreverses = true
        pathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        pathAnimation.repeatCount = Float.greatestFiniteMagnitude
        iconLayer.add(pathAnimation, forKey: "strokeStartAnimation")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canPresent = true
        
        a = SecondViewController(nibName: nil, bundle: nil)
        a?.willMove(toParent: self)
        a?.view.backgroundColor = UIColor.yellow
        self.addChild(a!)
        var frame = self.view.bounds.insetBy(dx: 25, dy: 0)
        frame.size.height = 88
        frame.origin.y = self.view.bounds.midY - 44
        a?.view.frame = frame
        self.view.addSubview(a!.view)
        a?.didMove(toParent: self)
        
        self.view.backgroundColor = UIColor.purple
        self._animateIcon()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if canPresent {
            canPresent = false
            
            let secondVC = SecondViewController(nibName: nil, bundle: nil)
            let navcon = UINavigationController(rootViewController: secondVC)
            
            self.present(inContentSheet: navcon, animated: true)
        }
    }
    
    @IBAction func presentCustomView(_ sender: Any) {
        
        let content: ContentSheetContentProtocol
        
        switch (sender as! UIButton).tag {
        case 0:
            let view = UIView()
            view.backgroundColor = UIColor.cyan
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            content = view
            break
        case 1:
            let customView = CustomView.customView()
            content = customView
            break
        default:
            let contentController = CustomObject()
            content = contentController
            break
        }
        
        let contentSheet = ContentSheet(content: content)
        contentSheet.showDefaultHeader = (sender as! UIButton).tag != 2
        self.present(contentSheet, animated: true, completion: nil)
    }
}

