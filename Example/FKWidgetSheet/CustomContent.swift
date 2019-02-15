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


import Foundation
import UIKit
import ContentSheet


class CustomView: UIView {
    
    //MARK: ContentSheetContentProtocol
    //Optional
    @objc public func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return .lightContent
    }
    
    
    func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return UIScreen.main.bounds.height*0.75
    }
    
    
    static func customView() -> CustomView {
        let view = CustomView()
        view.backgroundColor = UIColor.magenta
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.dismissContentSheet(animated: true)
//    }
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
    
    func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return UIScreen.main.bounds.height*0.75
    }    
}
