//
//  FKWidgetSheetTransitionDelegate.swift
//  WidgetActionSheet
//
//  Created by Rajat Kumar Gupta on 20/07/17.
//  Copyright © 2017 Rajat Kumar Gupta. All rights reserved.
//

import Foundation
import UIKit


public class FKWidgetSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var _duration: TimeInterval = 0.357
    public var duration: TimeInterval {
        get {
            return _duration
        }
        set {
            if newValue >= 0.0 {
                _duration = newValue
            }
        }
    }
    public var presenting: Bool = true
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
        
        let fromView: UIView? = transitionContext.view(forKey: .from)
        let toView: UIView? = transitionContext.view(forKey: .to)
        
        if let fromView = fromView, let toView = toView {
            
            let fromViewFrame: CGRect = fromViewController != nil ? transitionContext.initialFrame(for: fromViewController!) : UIScreen.main.bounds
            let toViewFrame: CGRect = toViewController != nil ? transitionContext.finalFrame(for: toViewController!) : UIScreen.main.bounds
            
            if presenting {
                
                toView.frame = toViewFrame
                toView.alpha = 0.0
                fromView.frame = fromViewFrame
                
                transitionContext.containerView.addSubview(toView)
                
                UIView.animate(withDuration: self.duration,
                               delay: 0.0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 0.8,
                               options: [.allowUserInteraction],
                               animations: {
                                toView.alpha = 1.0
                },
                               completion: { (finished) in
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
                
            } else {
                
                toView.frame = toViewFrame
                fromView.frame = fromViewFrame
                
                transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
                
                UIView.animate(withDuration: self.duration,
                               delay: 0.0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 0.8,
                               options: [.allowUserInteraction],
                               animations: {
                                fromView.alpha = 0.0
                },
                               completion: { (finished) in
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
                
            }
        }
    }
}


public class FKWidgetSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    private var _duration: TimeInterval = 0.357
    public var duration: TimeInterval {
        get {
            return _duration
        }
        set {
            if newValue >= 0.0 {
                _duration = newValue
            }
        }
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let sheet = presented as? FKWidgetSheet {
            if sheet.backgroundView == nil && sheet.backgroundImage == nil {
                sheet.backgroundView = presenting.view.snapshotView(afterScreenUpdates: false)
            }
        }
        
        let animator: FKWidgetSheetAnimator = FKWidgetSheetAnimator()
        animator.duration = duration
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator: FKWidgetSheetAnimator = FKWidgetSheetAnimator()
        animator.duration = duration
        animator.presenting = false
        return animator
    }
}































