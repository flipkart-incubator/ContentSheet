//
//  UIViewController+Extension.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 26/09/19.
//

import Foundation

//MARK: UIViewController+ContentSheet
extension UIViewController: ContentSheetContentProtocol {
    
    //MARK: Utility
    @objc public func contentSheet() -> ContentSheet? {
        return ContentSheet.contentSheet(content: self)
    }
    
    @objc public func cs_navigationBar() -> UINavigationBar? {
        return self.navigationController != nil ? self.navigationController?.navigationBar : self.contentSheet()?.contentNavigationBar
    }
    
    //MARK: ContentSheetContentProtocol
    open func contentSheetWillAddContent(_ sheet: ContentSheet) {
        self.willMove(toParent: sheet)
        sheet.addChild(self)
        //        self.beginAppearanceTransition(true, animated: true)
    }
    
    open func contentSheetDidAddContent(_ sheet: ContentSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParent: sheet)
    }
    
    open func contentSheetWillRemoveContent(_ sheet: ContentSheet) {
        self.willMove(toParent: nil)
        self.removeFromParent()
        //        self.beginAppearanceTransition(false, animated: true)
    }
    
    open func contentSheetDidRemoveContent(_ sheet: ContentSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParent: nil)
    }
    
    open func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return UIScreen.main.bounds.height*0.5
    }
    
    open func prefersStatusBarHidden(contentSheet: ContentSheet) -> Bool {
        return false
    }
    
    open func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return .default
    }
    
    open func preferredStatusBarUpdateAnimation(contentSheet: ContentSheet) -> UIStatusBarAnimation {
        return .fade
    }
    
    //Returning the same height as collapsed height by default
    open func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return self.collapsedHeight(containedIn: contentSheet)
    }
    
    open func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
        return nil
    }
    
    //MARK: Presentation
    @objc open func present(inContentSheet content: ContentSheetContentProtocol, animated flag: Bool, completion: (() -> Swift.Void)? = nil, direction: PresentationDirection) {
        
        let contentSheet = ContentSheet(content: content, presentationType: .contentSheet, presentationDirection: direction)
        self.present(contentSheet, animated: true, completion: completion)
    }
    
    @objc open func dismissContentSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.contentSheet()?.dismiss(animated: true, completion: completion)
    }
    
    @objc open func present(inPopUp popup: ContentSheetContentProtocol, animated flag: Bool, completion: (() -> Swift.Void)? = nil, direction: PresentationDirection) {
        let contentSheet = ContentSheet(content: popup, presentationType: .popUp, presentationDirection: direction)
        self.present(contentSheet, animated: true, completion: completion)
    }
}
