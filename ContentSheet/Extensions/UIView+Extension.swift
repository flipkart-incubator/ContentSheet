//
//  UIView+Extension.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 26/09/19.
//

import Foundation

extension UIView: ContentSheetContentProtocol {
    
    @objc open var view: UIView! {
        get {
            return self
        }
    }
    
    //MARK: Presentation
    @objc open func dismissContentSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.contentSheet()?.dismiss(animated: true, completion: completion)
    }
    
    //MARK: Utility
    @objc public func contentSheet() -> ContentSheet? {
        return ContentSheet.contentSheet(content: self)
    }
}

extension UIView {
    @objc public var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        
        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        
        return nil
    }
}
