//
//  ViewController.swift
//  WidgetActionSheet
//
//  Created by Rajat Kumar Gupta on 19/07/17.
//  Copyright © 2017 Rajat Kumar Gupta. All rights reserved.
//

import UIKit

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
        a?.view.frame = self.view.bounds.insetBy(dx: 25, dy: 100)
        self.view.addSubview(a!.view)
        a?.didMove(toParentViewController: self)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if canPresent {
            canPresent = false
            
            let secondVC = SecondViewController(nibName: nil, bundle: nil)
            let navcon = UINavigationController(rootViewController: secondVC)
            
            self.present(inWidgetSheet: navcon, animated: true)
            //            a?.present(inWidgetSheet: secondVC, animated: true)
        }
    }
}

