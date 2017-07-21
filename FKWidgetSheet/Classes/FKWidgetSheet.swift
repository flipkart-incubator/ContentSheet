//
//  FKWidgetActionSheet.swift
//  Flipkart
//
//  Created by Rajat Kumar Gupta on 19/07/17.
//  Copyright © 2017 flipkart.com. All rights reserved.
//

import UIKit


fileprivate let CollapsedHeightRatio: CGFloat = 0.5
fileprivate let ThreshodVelocitySquare: CGFloat = 10000 //100*100
fileprivate let ThreshodProgressFraction: CGFloat = 0.3
fileprivate let TotalDuration: Double = 0.5



@objc public protocol FKWidgetSheetDelegate {
    
    @objc optional func widgetSheetWillAppear(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidAppear(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetWillDisappear(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidDisappear(_ sheet: FKWidgetSheet)
    
    @objc optional func widgetSheetWillShow(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidShow(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetWillHide(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidHide(_ sheet: FKWidgetSheet)
}


@objc public protocol FKWidgetSheetContentProtocol {
    
    //View to be set as content
    var view: UIView! {get}
    
    @objc optional func widgetSheetWillAddContent(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidAddContent(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetWillRemoveContent(_ sheet: FKWidgetSheet)
    @objc optional func widgetSheetDidRemoveContent(_ sheet: FKWidgetSheet)
    
    @objc optional func collapsedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat
    @objc optional func expandedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat
    
    @objc optional func scrollViewToObserve(containedIn widgetSheet: FKWidgetSheet) -> UIScrollView?
}



@objc public enum FKWidgetSheetState: UInt {
    case minimised
    case collapsed
    case expanded
}

fileprivate enum PanDirection {
    case up
    case down
}



public class FKWidgetSheet: UIViewController {
    
    //MARK: Variables
    //Content controller object
    //Not necessarilly a view controller
    fileprivate var _content: FKWidgetSheetContentProtocol
    public var content: FKWidgetSheetContentProtocol {
        get {
            return _content
        }
    }
    
    //Reference to content view of content controller
    fileprivate var _contentView: UIView?
    
    //background view for the action sheet
    //default backgorund
    private lazy var _defaultBackground: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: self.view.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return imageView
    } ()
    
    private lazy var _overlay: UIView = {
        let overlay: UIView = UIView(frame: self.view.bounds)
        overlay.contentMode = .scaleAspectFill
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return overlay
    } ()
    
    private var _blurView: UIVisualEffectView {
        get {
            let effect: UIBlurEffect = UIBlurEffect(style: blurStyle)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = self.view.bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            return effectView
        }
    }
    
    //background image
    public var backgroundImage: UIImage? {
        didSet {
            _defaultBackground.image = backgroundImage
        }
    }
    
    //background view, can be provided by host or will use the default background
    public var backgroundView: UIView? {
        didSet {
            backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    private var _backgroundView: UIView {
        get {
            let view = backgroundView != nil ? backgroundView! : _defaultBackground
            view.frame = self.view.bounds
            
            if blurBackground {
                view.addSubview(_blurView)
            } else {
                view.addSubview(_overlay)
            }
            return view
        }
    }
    
    //Settings
    public var blurBackground: Bool = true
    public var blurStyle: UIBlurEffectStyle = .dark
    public var dismissOnTouchOutside: Bool = true
    
    //Scroll management related
    fileprivate weak var _scrollviewToObserve: UIScrollView?
    
    fileprivate var collapsedHeight: CGFloat = 0.0
    fileprivate var expandedHeight: CGFloat = 0.0
    
    //Rotation
    public override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    //State
    fileprivate var _state: FKWidgetSheetState = .minimised
    public var state: FKWidgetSheetState {
        get {
            return _state
        }
    }

    //Transition
    fileprivate lazy var _transitionController: UIViewControllerTransitioningDelegate = {
        let controller = FKWidgetSheetTransitionDelegate()
        controller.duration = TotalDuration
        return controller
    } ()

    //Delegate
    public weak var delegate: FKWidgetSheetDelegate?
    
    //Gesture
    fileprivate lazy var _panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        return gesture
    } ()
    
    
    //MARK: Initializers
    //Not implementing required initializer
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) not implemented.")
    }
    
    // required initializer
    // content controller is non-optional
    public required init(content: FKWidgetSheetContentProtocol) {
        _content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    //MARK: View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load content view
        if let contentView = _content.view {
            _contentView = contentView
        }
        self.view.backgroundColor = UIColor.clear
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if _state == .minimised {
            //Add background view
            self.view.insertSubview(_backgroundView, at: 0)
            
            //Add content view
            if let contentView = _contentView {
                
                let proposedCollapsedHeight = max(_content.collapsedHeight?(containedIn: self) ?? 0.0, 0.0)
                collapsedHeight = proposedCollapsedHeight == 0.0 ? CollapsedHeightRatio*view.bounds.height : proposedCollapsedHeight
                var frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: collapsedHeight)
                contentView.frame = frame
                
                //Content controller should use this do any preps before content view is added
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.widgetSheetWillAddContent?(self)
                self.view.addSubview(contentView)
                
                //Do not expand if no expanded height
                expandedHeight = max(min(max(_content.expandedHeight?(containedIn: self) ?? 0.0, 0.0), self.view.frame.height), collapsedHeight)
                
                //Animate content
                frame.origin.y -= collapsedHeight
                self.transitionCoordinator?.animate(alongsideTransition: { (_) in
                    contentView.frame = frame
                }, completion: nil)
                
                //Notify delegate that sheet will show
                delegate?.widgetSheetWillShow?(self)
            }
        }
        
        //Notify delegate that view will appear
        delegate?.widgetSheetWillAppear?(self)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if _state == .minimised {
            _state = .collapsed
            
            if _contentView != nil {
                //Content controller should use this do any preps after content view is added
                // e.g. in case of view controllers, they might wanna end the appearance transitions
                _content.widgetSheetDidAddContent?(self)
                
                //Only add pan gesture if needed
                if collapsedHeight < expandedHeight {
                    //Check if there is a scrollview to observer
                    _contentView?.addGestureRecognizer(_panGesture)
                }
                
                //Notify delegate that sheet did show
                delegate?.widgetSheetDidShow?(self)
            }
        }
        
        //Notify delegate that view did appear
        delegate?.widgetSheetDidAppear?(self)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if _state == .minimised {
            
            if let contentView = _contentView {
                //Content controller should use this do any preps before content view is removed
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.widgetSheetWillRemoveContent?(self)
                
                //Animate content
                var frame = contentView.frame
                frame.origin.y = self.view.frame.maxY
                self.transitionCoordinator?.animate(alongsideTransition: { (_) in
                    contentView.frame = frame
                }, completion: nil)
                
                //Notify delegate that sheet will hide
                delegate?.widgetSheetWillHide?(self)
            }
        }
        
        //Notify delegate view will disappear
        delegate?.widgetSheetWillDisappear?(self)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if _state == .minimised {
            
            //Remove background view
            _backgroundView.removeFromSuperview()
            
            if let contentView = _contentView {
                contentView.removeFromSuperview()
                //Content controller should use this do any preps after content view is removed
                // e.g. in case of view controllers, they might wanna end the appearance transitions
                _content.widgetSheetDidRemoveContent?(self)
                
                //Notify delegate that sheet did hide
                delegate?.widgetSheetDidHide?(self)
            }
        }
        
        //Notify delegate view did disappear
        delegate?.widgetSheetDidDisappear?(self)
    }
    
    
    public override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            return _transitionController
        }
        set {
            fatalError("Attempt to set transition delegate of widget sheet, which is a read only property.")
        }
    }
}



extension FKWidgetSheet {
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
        if parent is UINavigationController {
            fatalError("Attempt to push widget sheet inside a navigation controller. Widget sheet can only be presented.")
        }
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        _state = .minimised
        super.dismiss(animated: flag, completion: completion)
    }
}





//MARK: Interaction and gestures
extension FKWidgetSheet {
    
    @objc fileprivate func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        if let contentView = _contentView {
            let translation = recognizer.translation(in: self.view)
            
            let y = contentView.frame.minY, totalHeight = self.view.frame.height

            let possibleState = _possibleStateChange(y)

            let minY = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
            let maxY = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight

            let direction: PanDirection = _panDirection(recognizer, view: contentView, possibleStateChange: possibleState)
            let progress = direction == .down ? (y - minY)/(maxY - minY) : (maxY - y)/(maxY - minY)

            // manipulate frame if gesture is in progress
            if recognizer.state == .began || recognizer.state == .changed {
                if (y + translation.y >= totalHeight - expandedHeight) && (y + translation.y <= totalHeight/* - collapsedHeight*/) {
                    contentView.frame = CGRect(x: 0, y: y + translation.y, width: contentView.frame.width, height: totalHeight - (y + translation.y))
                    recognizer.setTranslation(CGPoint.zero, in: self.view)
                }
            }
            
            // animate to either state if gesture and ended or cancelled
            if recognizer.state == .ended || recognizer.state == .cancelled {
                
                let duration = (1 - Double(progress))*TotalDuration
                let finalState: FKWidgetSheetState
                if _state == .collapsed {
                    if possibleState == .minimised {
                        finalState = direction == .up ? .collapsed : .minimised
                    } else {
                        finalState = direction == .up ? .expanded : .collapsed
                    }
                } else if _state == .expanded {
                    finalState = direction == .up ? .expanded : .collapsed
                } else {
                    finalState = .minimised
                }
                
                if finalState == .minimised {
                    (_transitionController as? FKWidgetSheetTransitionDelegate)?.duration = duration
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                
                UIView.animate(withDuration: duration,
                               delay: 0.0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 0.8,
                               options: [.allowUserInteraction],
                               animations: {
                                
                                switch finalState {
                                case .expanded:
                                    contentView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: self.expandedHeight)
                                    break
                                case .collapsed:
                                    contentView.frame = CGRect(x: 0, y: totalHeight - self.collapsedHeight, width: contentView.frame.width, height: max(contentView.frame.height, self.collapsedHeight))
                                    break
//                                case .minimised:
//                                    contentView.frame = CGRect(x: 0, y: totalHeight, width: contentView.frame.width, height: contentView.frame.height)
//                                    break;
                                default:
                                    break
                                }},
                               completion: { [weak self] _ in
                                if let strong = self {
                                    strong._state = finalState
                                    
                                    switch finalState {
                                    case .expanded:
                                        strong._scrollviewToObserve?.isScrollEnabled = true
                                        break;
                                    case .collapsed:
                                        strong._scrollviewToObserve?.isScrollEnabled = false
                                        contentView.frame = CGRect(x: 0, y: totalHeight - strong.collapsedHeight, width: contentView.frame.width, height: strong.collapsedHeight)
                                        break;
//                                    case .minimised:
//                                        strong._scrollviewToObserve?.isScrollEnabled = false
//                                        contentView.frame = CGRect(x: 0, y: totalHeight, width: contentView.frame.width, height: 0)
//                                        strong.dismiss(animated: true, completion: nil)
//                                        break;
                                    default:
                                        break
                                    }
                                }})
            }
        }
    }
    
    @inline(__always) fileprivate func _possibleStateChange(_ progress: CGFloat) -> FKWidgetSheetState {
        let possibleState: FKWidgetSheetState
        if _state == .expanded {
            possibleState = .collapsed
        } else if _state == .collapsed {
            if progress > self.view.frame.height - collapsedHeight {
                possibleState = .minimised
            } else {
                possibleState = .expanded
            }
        } else {
            possibleState = .minimised
        }
        return possibleState
    }
    
    fileprivate func _panDirection(_ gesture: UIPanGestureRecognizer, view contentView: UIView, possibleStateChange possibleState: FKWidgetSheetState) -> PanDirection {
        
        let velocity = gesture.velocity(in: self.view)
        let progress = contentView.frame.minY, totalHeight = self.view.frame.height
        
        let min = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
        let max = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight //totalHeight - collapsedHeight//
        
        let ratio = (max - progress)/(progress - min)
        let thresholdVelocitySquare = (ratio >= 0.5 && ratio <= 2.0) ? 0.0 : ThreshodVelocitySquare
        
        let direction: PanDirection
        
        if (pow(velocity.y, 2) < thresholdVelocitySquare) {
            direction = max - progress > progress - min ? .up : .down
        } else {
            direction = velocity.y < 0 ? .up : .down
        }
        
        return direction
    }
    
    //Touches
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if dismissOnTouchOutside {
            let touch =  touches.first
            var contentInteracted = false
            if let contentview = _contentView, let locationInContent = touch?.location(in: contentview) {
                contentInteracted = contentview.point(inside: locationInContent, with: event)
            }
            if !contentInteracted {
                self.dismiss(animated: true, completion: nil)
                return
            }
        }
        
        super.touchesBegan(touches, with: event)
    }
}





extension FKWidgetSheet: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        /*
         Need to figure out a way to check if the visible view controller has changed,
         because collapsed height and other behaviours also need to be updated.
         TODO: Will solve this later.
         */
        //Check if there is a scrollview to observer
        if let scrollview = _content.scrollViewToObserve?(containedIn: self) {
            _scrollviewToObserve = scrollview
        }
        
        guard let scrollView = _scrollviewToObserve, let contentView = _contentView else {
            return false
        }
        
        guard gestureRecognizer == _panGesture else {
            return false
        }
        
        
        
        let direction = _panDirection(_panGesture, view: contentView, possibleStateChange: _possibleStateChange(contentView.frame.minY))
        
        if ((_state == .expanded) && (scrollView.contentOffset.y + scrollView.contentInset.top == 0) && (direction == .down)) || (_state == .collapsed) {
            scrollView.isScrollEnabled = false
        } else {
            scrollView.isScrollEnabled = true
        }
        
        return false
    }
}








//MARK: UIViewController+WidgetSheet
extension UIViewController: FKWidgetSheetContentProtocol {
    
    //MARK: Utility
    public func widgetSheet() -> FKWidgetSheet? {
        var viewController: UIResponder? = self
        while viewController != nil {
            if viewController is FKWidgetSheet {
                return viewController as? FKWidgetSheet
            }
            viewController = viewController?.next
        }
        return nil
    }
    
    //MARK: FKWidgetSheetContentProtocol
    open func widgetSheetWillAddContent(_ sheet: FKWidgetSheet) {
        self.willMove(toParentViewController: sheet)
        sheet.addChildViewController(self)
        //        self.beginAppearanceTransition(true, animated: true)
    }
    
    open func widgetSheetDidAddContent(_ sheet: FKWidgetSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParentViewController: sheet)
    }
    
    open func widgetSheetWillRemoveContent(_ sheet: FKWidgetSheet) {
        self.willMove(toParentViewController: nil)
        self.removeFromParentViewController()
        //        self.beginAppearanceTransition(false, animated: true)
    }
    
    open func widgetSheetDidRemoveContent(_ sheet: FKWidgetSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParentViewController: nil)
    }
    
    open func collapsedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
        return UIScreen.main.bounds.height*0.5
    }

    //Returning the same height as collapsed height by default
    open func expandedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
        return self.collapsedHeight(containedIn: widgetSheet)
    }
    
    open func scrollViewToObserve(containedIn widgetSheet: FKWidgetSheet) -> UIScrollView? {
        return nil
    }
    
    //MARK: Presentation
    open func present(inWidgetSheet viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        
        let widgetSheet = FKWidgetSheet(content: viewControllerToPresent)
        self.present(widgetSheet, animated: true, completion: completion)
    }
    
    open func dismissWidgetSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.widgetSheet()?.dismiss(animated: true, completion: completion)
    }
}


extension UINavigationController {
    
    open override func collapsedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
        return self.visibleViewController?.collapsedHeight(containedIn: widgetSheet) ?? UIScreen.main.bounds.height*0.5
    }
    
    //Returning the same height as collapsed height by default
    open override func expandedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
        return self.visibleViewController?.expandedHeight(containedIn: widgetSheet) ?? self.collapsedHeight(containedIn: widgetSheet)
    }
    
    open override func scrollViewToObserve(containedIn widgetSheet: FKWidgetSheet) -> UIScrollView? {
        return self.visibleViewController?.scrollViewToObserve(containedIn: widgetSheet)
    }
}




