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


public class ContentSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
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


public class ContentSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
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
        
        if let sheet = presented as? ContentSheet {
            if sheet.backgroundView == nil && sheet.backgroundImage == nil {
                sheet.backgroundView = presenting.view.snapshotView(afterScreenUpdates: false)
            }
        }
        
        let animator: ContentSheetAnimator = ContentSheetAnimator()
        animator.duration = duration
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator: ContentSheetAnimator = ContentSheetAnimator()
        animator.duration = duration
        animator.presenting = false
        return animator
    }
}































