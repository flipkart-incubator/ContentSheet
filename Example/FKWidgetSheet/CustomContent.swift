//
//  CustomContent.swift
//  FKWidgetSheet
//
//  Created by Rajat Kumar Gupta on 26/07/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ContentSheet


class CustomView: UIView {
    
    //MARK: ContentSheetContentProtocol
    //Optional
    public func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return .lightContent
    }
    
    static func customView() -> CustomView {
        let view = CustomView()
        view.backgroundColor = UIColor.magenta
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissContentSheet(animated: true)
    }
}



class CustomObject: NSObject, ContentSheetContentProtocol {
    
    var view: UIView! {
        get {
            let view = CustomView()
            view.backgroundColor = UIColor.yellow
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return view
        }
    }
}
