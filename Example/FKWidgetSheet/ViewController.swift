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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var canPresent = false
    var a: SecondViewController?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canPresent = true
        
        a = SecondViewController(nibName: nil, bundle: nil)
        a?.willMove(toParentViewController: self)
        a?.view.backgroundColor = UIColor.yellow
        self.addChildViewController(a!)
        var frame = self.view.bounds.insetBy(dx: 25, dy: 100)
        frame.origin.y -= 50
        a?.view.frame = frame
        self.view.addSubview(a!.view)
        a?.didMove(toParentViewController: self)
        
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

