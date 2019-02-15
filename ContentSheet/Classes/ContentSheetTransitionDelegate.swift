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


@objc public class ContentSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var _duration: TimeInterval = 0.357
    @objc public var duration: TimeInterval {
        get {
            return _duration
        }
        set {
            if newValue >= 0.0 {
                _duration = newValue
            }
        }
    }
    @objc public var presenting: Bool = true
    
    @objc public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    @objc public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
        
        let fromView: UIView? = transitionContext.view(forKey: .from)
        let toView: UIView? = transitionContext.view(forKey: .to)
        
        let fromViewFrame: CGRect = fromViewController != nil ? transitionContext.initialFrame(for: fromViewController!) : UIScreen.main.bounds
        let toViewFrame: CGRect = toViewController != nil ? transitionContext.finalFrame(for: toViewController!) : UIScreen.main.bounds
        
        if presenting {
            
            if let toView = toView {
                
                toView.frame = toViewFrame
                toView.alpha = 0.0
                
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
                
            }
        } else {
            
            if let fromView = fromView {
                
                fromView.frame = fromViewFrame
                
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


@objc public class ContentSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    private var _duration: TimeInterval = 0.357
    @objc public var duration: TimeInterval {
        get {
            return _duration
        }
        set {
            if newValue >= 0.0 {
                _duration = newValue
            }
        }
    }
    
    @objc public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator: ContentSheetAnimator = ContentSheetAnimator()
        animator.duration = duration
        return animator
    }

    @objc public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator: ContentSheetAnimator = ContentSheetAnimator()
        animator.duration = duration
        animator.presenting = false
        return animator
    }
    
    @objc public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ContentSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
}


/*
 TODO: Add support for different kind of presentation transitions.
 First variation could be to just add direction of sliding in as an option.
 */
@objc public class ContentSheetPresentationController: UIPresentationController {
    
    public override func presentationTransitionWillBegin() {
        if let sheet = self.presentedViewController as? ContentSheet {
            _overlay = sheet.blurBackground ? _blurView(sheet.blurStyle) : _dimmingView()
            _overlay!.alpha = 0.0
            self.containerView?.insertSubview(_overlay!, at: 0)

            guard let coordinator = presentedViewController.transitionCoordinator else {
                _overlay!.alpha = 1.0
                return
            }
            
            coordinator.animate(alongsideTransition: { _ in
                self._overlay!.alpha = 1.0
            })
        }
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            self._overlay?.removeFromSuperview()
        }
    }

    public override func dismissalTransitionWillBegin() {
        if let sheet = self.presentedViewController as? ContentSheet, !sheet.blurBackground {
            guard let coordinator = presentedViewController.transitionCoordinator else {
                _overlay!.alpha = 0.0
                return
            }
            
            coordinator.animate(alongsideTransition: { _ in
                self._overlay!.alpha = 0.0
            })
        }
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            self._overlay?.removeFromSuperview()
        } else {
            self._overlay?.alpha = 1.0
        }
    }
    
    override public func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override public func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return parentSize
    }

    @objc override public var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        return frame
    }

    
    private var _overlay: UIView?
    
    private func _dimmingView() -> UIView {
        let dimmingView: UIView = UIView(frame: self.containerView?.bounds ?? self.presentingViewController.view.bounds)
        dimmingView.contentMode = .scaleAspectFill
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)

        return dimmingView
    }
    
    private func _blurView(_ style: UIBlurEffect.Style) -> UIVisualEffectView {
        let effect: UIBlurEffect = UIBlurEffect(style: style)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = self.containerView?.bounds ?? self.presentingViewController.view.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return effectView
    }

    @objc private dynamic func _handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}




























