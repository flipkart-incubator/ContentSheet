//
//  UINavigationController+Extension.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 26/09/19.
//

import Foundation

extension UINavigationController {
    
    @objc open override func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return self.visibleViewController?.collapsedHeight(containedIn: contentSheet) ?? UIScreen.main.bounds.height*0.5
    }
    
    //Returning the same height as collapsed height by default
    @objc open override func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return self.visibleViewController?.expandedHeight(containedIn: contentSheet) ?? self.collapsedHeight(containedIn: contentSheet)
    }
    
    @objc open override func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
        return self.visibleViewController?.scrollViewToObserve(containedIn: contentSheet)
    }
    
    @objc open override func prefersStatusBarHidden(contentSheet: ContentSheet) -> Bool {
        return self.visibleViewController?.prefersStatusBarHidden(contentSheet: contentSheet) ?? false
    }
    
    @objc open override func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return self.visibleViewController?.preferredStatusBarStyle(contentSheet: contentSheet) ?? .default
    }
    
    @objc open override func preferredStatusBarUpdateAnimation(contentSheet: ContentSheet) -> UIStatusBarAnimation {
        return self.visibleViewController?.preferredStatusBarUpdateAnimation(contentSheet: contentSheet) ?? .fade
    }
}
