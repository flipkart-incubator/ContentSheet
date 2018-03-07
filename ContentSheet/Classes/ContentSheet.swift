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


import UIKit


fileprivate let CollapsedHeightRatio: CGFloat = 0.5
fileprivate let ThresholdVelocitySquare: CGFloat = 10000 //100*100
fileprivate let ThresholdProgressFraction: CGFloat = 0.3
fileprivate let TotalDuration: Double = 0.5

fileprivate let HeaderMinHeight: CGFloat = 44.0
fileprivate let HeaderMaxHeight: CGFloat = HeaderMinHeight + UIApplication.shared.statusBarFrame.height


@objc public protocol ContentSheetDelegate {
    
    @objc optional func contentSheetWillAppear(_ sheet: ContentSheet)
    @objc optional func contentSheetDidAppear(_ sheet: ContentSheet)
    @objc optional func contentSheetWillDisappear(_ sheet: ContentSheet)
    @objc optional func contentSheetDidDisappear(_ sheet: ContentSheet)
    
    @objc optional func contentSheetWillShow(_ sheet: ContentSheet)
    @objc optional func contentSheetDidShow(_ sheet: ContentSheet)
    @objc optional func contentSheetWillHide(_ sheet: ContentSheet)
    @objc optional func contentSheetDidHide(_ sheet: ContentSheet)
}


@objc public protocol ContentSheetContentProtocol {
    
    //View to be set as content
    var view: UIView! {get}
    
    //NavigationItem
    @objc optional var navigationItem: UINavigationItem { get }
    
    //Callbacks
    @objc optional func contentSheetWillAddContent(_ sheet: ContentSheet)
    @objc optional func contentSheetDidAddContent(_ sheet: ContentSheet)
    @objc optional func contentSheetWillRemoveContent(_ sheet: ContentSheet)
    @objc optional func contentSheetDidRemoveContent(_ sheet: ContentSheet)
    
    //Params
    @objc optional func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat
    @objc optional func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat
    
    @objc optional func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView?
    
    //Status bar
    @objc optional func prefersStatusBarHidden(contentSheet: ContentSheet) -> Bool
    @objc optional func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle
    @objc optional func preferredStatusBarUpdateAnimation(contentSheet: ContentSheet) -> UIStatusBarAnimation
}


@objc public enum ContentSheetState: UInt {
    case minimised
    case collapsed
    case expanded
}

fileprivate enum PanDirection {
    case up
    case down
}



public class ContentSheet: UIViewController {
    
    //MARK: Variables
    //Content controller object
    //Not necessarilly a view controller
    fileprivate var _content: ContentSheetContentProtocol
    public var content: ContentSheetContentProtocol {
        get {
            return _content
        }
    }
    
    //Reference to content view of content controller
    fileprivate var _contentView: UIView?
    
    //Content container
    fileprivate lazy var _contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        self.view.addSubview(view)
        return view
    } ()
    
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
    fileprivate var _state: ContentSheetState = .minimised
    public var state: ContentSheetState {
        get {
            return _state
        }
    }

    //Transition
    fileprivate lazy var _transitionController: UIViewControllerTransitioningDelegate = {
        let controller = ContentSheetTransitionDelegate()
        controller.duration = TotalDuration
        return controller
    } ()

    //Delegate
    public weak var delegate: ContentSheetDelegate?
    
    //Header
    public var showDefaultHeader: Bool = true
    
    private var _navigationBar: UINavigationBar?
    
    public var contentNavigationBar: UINavigationBar? {
        get {
            return _navigationBar
        }
    }

    public var contentNavigationItem: UINavigationItem? {
        get {
            return _navigationBar?.items?.last
        }
    }
    
    
    private func _defaultHeader() -> UINavigationBar {
        
        var frame = self.view.frame
        frame.size.height = 44.0;
        
        let navigationBar = UINavigationBar(frame: frame)
        navigationBar.delegate = self
        
        return navigationBar
    }
    
    
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
    public required init(content: ContentSheetContentProtocol) {
        _content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    //MARK: View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load content view
        if let contentView = _content.view {
            _contentView = contentView
            
            if showDefaultHeader {
                
                let navigationItem: UINavigationItem
                
                self._navigationBar = _defaultHeader()
                
                if let item = self.content.navigationItem {
                    navigationItem = item
                } else {
                    navigationItem = UINavigationItem()
                }
                
                if navigationItem.leftBarButtonItem == nil {
                    let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelButtonPressed(_:)))
                    navigationItem.leftBarButtonItem = cancelButton
                }
                
                self._navigationBar!.items = [navigationItem]
            }
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
                _contentContainer.frame = frame
                
                if let navigationBar = self._navigationBar {
                    _contentContainer.addSubview(navigationBar)
                }
                
                contentView.frame = frame
                
                //Content controller should use this do any preps before content view is added
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.contentSheetWillAddContent?(self)
                _contentContainer.addSubview(contentView)
                
                //Layout content
                self.layoutContentSubviews()
                
                //Do not expand if no expanded height
                expandedHeight = max(min(max(_content.expandedHeight?(containedIn: self) ?? 0.0, 0.0), self.view.frame.height), collapsedHeight)
                
                //Animate content
                frame.origin.y = self.view.bounds.height - collapsedHeight
                frame.size.height = collapsedHeight
                self.transitionCoordinator?.animate(alongsideTransition: { (_) in
                    self._contentContainer.frame = frame
                }, completion: nil)
                
                //Notify delegate that sheet will show
                delegate?.contentSheetWillShow?(self)
            }
        }
        
        //Notify delegate that view will appear
        delegate?.contentSheetWillAppear?(self)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if _state == .minimised {
            _state = .collapsed
            
            if _contentView != nil {
                //Content controller should use this do any preps after content view is added
                // e.g. in case of view controllers, they might wanna end the appearance transitions
                _content.contentSheetDidAddContent?(self)
                
                //Check if there is a scrollview to observer
                _contentContainer.addGestureRecognizer(_panGesture)
                
                //Notify delegate that sheet did show
                delegate?.contentSheetDidShow?(self)
            }
        }
        
        //Notify delegate that view did appear
        delegate?.contentSheetDidAppear?(self)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if _state == .minimised {
            
            if _contentView != nil {
                //Content controller should use this do any preps before content view is removed
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.contentSheetWillRemoveContent?(self)
                
                //Animate content
                var frame = _contentContainer.frame
                frame.origin.y = self.view.frame.maxY
                self.transitionCoordinator?.animate(alongsideTransition: { (_) in
                    self._contentContainer.frame = frame
                }, completion: nil)
                
                //Notify delegate that sheet will hide
                delegate?.contentSheetWillHide?(self)
            }
        }
        
        //Notify delegate view will disappear
        delegate?.contentSheetWillDisappear?(self)
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
                _content.contentSheetDidRemoveContent?(self)
                
                //Notify delegate that sheet did hide
                delegate?.contentSheetDidHide?(self)
            }
        }
        
        //Notify delegate view did disappear
        delegate?.contentSheetDidDisappear?(self)
    }
    
    
    //Overrides
    //Transition
    public override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            return _transitionController
        }
        set {
            fatalError("Attempt to set transition delegate of content sheet, which is a read only property.")
        }
    }
    
    //Status bar
    public override var prefersStatusBarHidden: Bool {
        get {
            return self.content.prefersStatusBarHidden?(contentSheet: self) ?? false
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return self.content.preferredStatusBarStyle?(contentSheet: self) ?? .default
        }
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        get {
            return self.content.preferredStatusBarUpdateAnimation?(contentSheet: self) ?? .fade
        }
    }
    
    public func resetBottomSheetHeight(collapsedHeight: CGFloat, expandedHeight: CGFloat) {
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        
        let frame = CGRect(x: 0, y: self.view.frame.height - self.collapsedHeight, width: self._contentContainer.frame.width, height: self.collapsedHeight)
        
        UIView.animate(withDuration: 0.2) {
            self._contentContainer.frame = frame
            self.layoutContentSubviews()
        }
    }
}



extension ContentSheet {
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
        if parent is UINavigationController {
            fatalError("Attempt to push content sheet inside a navigation controller. content sheet can only be presented.")
        }
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        _state = .minimised
        super.dismiss(animated: flag, completion: completion)
    }
    
    @objc fileprivate func cancelButtonPressed(_ sender: UIBarButtonItem?) {
        self.dismiss(animated: true)
    }
}





//MARK: Interaction and gestures
extension ContentSheet {
    
    @objc fileprivate func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        if let contentView = _contentView {
            let translation = recognizer.translation(in: self.view)
            
            let y = _contentContainer.frame.minY, totalHeight = self.view.frame.height

            let possibleState = _possibleStateChange(y)

            let minY = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
            let maxY = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight

            let direction: PanDirection = _panDirection(recognizer, view: _contentContainer, possibleStateChange: possibleState)
            let progress = direction == .down ? (y - minY)/(maxY - minY) : (maxY - y)/(maxY - minY)

            // manipulate frame if gesture is in progress
            if recognizer.state == .began || recognizer.state == .changed {
                if (y + translation.y >= totalHeight - expandedHeight) && (y + translation.y <= totalHeight/* - collapsedHeight*/) {
                    let frame = CGRect(x: 0, y: y + translation.y, width: contentView.frame.width, height: totalHeight - (y + translation.y))
                    recognizer.setTranslation(CGPoint.zero, in: self.view)
                    
                    _contentContainer.frame = frame
                }
            }

            // animate to either state if gesture and ended or cancelled
            if recognizer.state == .ended || recognizer.state == .cancelled {
                
                let duration = (1 - Double(progress))*TotalDuration
                let finalState: ContentSheetState
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
                    (_transitionController as? ContentSheetTransitionDelegate)?.duration = duration
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
                                    let y = self.view.bounds.height - self.expandedHeight
                                    let frame = CGRect(x: 0, y: y, width: self._contentContainer.frame.width, height: self.expandedHeight)
                                    self._contentContainer.frame = frame
                                    
                                    self.layoutContentSubviews()
                                    break
                                case .collapsed:
                                    let frame = CGRect(x: 0, y: totalHeight - self.collapsedHeight, width: self._contentContainer.frame.width, height: self.collapsedHeight)
                                    self._contentContainer.frame = frame
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
                                    
                                    if let bar = strong.contentNavigationBar {
                                        strong._contentContainer.bringSubview(toFront: bar)
                                    }
                                    
                                    switch finalState {
                                    case .expanded:
                                        strong._scrollviewToObserve?.isScrollEnabled = true
                                        break;
                                    case .collapsed:
                                        strong._scrollviewToObserve?.isScrollEnabled = strong.collapsedHeight < strong.view.frame.size.height ? false : true
                                        strong.layoutContentSubviews()
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
            
            self.layoutContentSubviews()
        }
    }
    
    
    fileprivate func layoutContentSubviews() {
        
        if let contentView = self._contentView {
            if self.showDefaultHeader, let navigationBar = self.contentNavigationBar {
                
                let frame = self._contentContainer.frame
                
                if frame.origin.y < UIApplication.shared.statusBarFrame.maxY {
                    
                    var subviewFrame = CGRect(x: 0, y: 0, width: frame.width, height: HeaderMaxHeight)
                    navigationBar.frame = subviewFrame
                    
                    subviewFrame.origin.y = subviewFrame.maxY
                    subviewFrame.size.height = frame.height - subviewFrame.origin.y
                    
                    contentView.frame = subviewFrame
                    
                } else {
                    var subviewFrame = CGRect(x: 0, y: 0, width: frame.width, height: HeaderMinHeight)
                    navigationBar.frame = subviewFrame
                    
                    subviewFrame.origin.y = subviewFrame.maxY
                    subviewFrame.size.height = frame.height - subviewFrame.origin.y
                    
                    contentView.frame = subviewFrame
                }
            } else {
                contentView.frame = self._contentContainer.bounds
            }
        }
    }
    
    
    @inline(__always) fileprivate func _possibleStateChange(_ progress: CGFloat) -> ContentSheetState {
        if expandedHeight <= collapsedHeight {
            return .minimised
        }
        let possibleState: ContentSheetState
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
    
    fileprivate func _panDirection(_ gesture: UIPanGestureRecognizer, view contentView: UIView, possibleStateChange possibleState: ContentSheetState) -> PanDirection {
        
        let velocity = gesture.velocity(in: self.view)
        let progress = contentView.frame.minY, totalHeight = self.view.frame.height
        
        let min = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
        let max = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight //totalHeight - collapsedHeight//
        
        let ratio = (max - progress)/(progress - min)
        let thresholdVelocitySquare = (ratio >= 0.5 && ratio <= 2.0) ? 0.0 : ThresholdVelocitySquare
        
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
            if let locationInContent = touch?.location(in: _contentContainer) {
                contentInteracted = _contentContainer.point(inside: locationInContent, with: event)
            }
            if !contentInteracted {
                self.dismiss(animated: true, completion: nil)
                return
            }
        }
        
        super.touchesBegan(touches, with: event)
    }
}





extension ContentSheet: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == _panGesture {
            return collapsedHeight <= expandedHeight
        }
        return true
    }
    
    
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
        
        guard let scrollView = _scrollviewToObserve else {
            return false
        }
        
        guard gestureRecognizer == _panGesture else {
            return false
        }
        
        
        
        let direction = _panDirection(_panGesture, view: _contentContainer, possibleStateChange: _possibleStateChange(_contentContainer.frame.minY))
        
        if (collapsedHeight <= expandedHeight)
            &&
            (((_state == .expanded) && (scrollView.contentOffset.y + scrollView.contentInset.top == 0) && (direction == .down)) || (_state == .collapsed && collapsedHeight < self.view.frame.size.height)) {
            scrollView.isScrollEnabled = false
        } else {
            scrollView.isScrollEnabled = true
        }
        
        return false
    }
}



//Convenience
extension ContentSheet {
    public static func contentSheet(content: ContentSheetContentProtocol) -> ContentSheet? {
        var responder: UIResponder? = content.view
        while responder != nil {
            if responder is ContentSheet {
                return responder as? ContentSheet
            }
            responder = responder?.next
        }
        return nil
    }
}



//UIBarPositioningDelegate
extension ContentSheet: UINavigationBarDelegate {
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
}





//MARK: UIViewController+ContentSheet
extension UIViewController: ContentSheetContentProtocol {
    
    //MARK: Utility
    public func contentSheet() -> ContentSheet? {
        return ContentSheet.contentSheet(content: self)
    }
    
    public func cs_navigationBar() -> UINavigationBar? {
        return self.navigationController != nil ? self.navigationController?.navigationBar : self.contentSheet()?.contentNavigationBar
    }
    
    //MARK: ContentSheetContentProtocol
    open func contentSheetWillAddContent(_ sheet: ContentSheet) {
        self.willMove(toParentViewController: sheet)
        sheet.addChildViewController(self)
        //        self.beginAppearanceTransition(true, animated: true)
    }
    
    open func contentSheetDidAddContent(_ sheet: ContentSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParentViewController: sheet)
    }
    
    open func contentSheetWillRemoveContent(_ sheet: ContentSheet) {
        self.willMove(toParentViewController: nil)
        self.removeFromParentViewController()
        //        self.beginAppearanceTransition(false, animated: true)
    }
    
    open func contentSheetDidRemoveContent(_ sheet: ContentSheet) {
        //        self.endAppearanceTransition()
        self.didMove(toParentViewController: nil)
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
    open func present(inContentSheet content: ContentSheetContentProtocol, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        
        let contentSheet = ContentSheet(content: content)
        self.present(contentSheet, animated: true, completion: completion)
    }
    
    open func dismissContentSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.contentSheet()?.dismiss(animated: true, completion: completion)
    }
}


extension UINavigationController {
    
    open override func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return self.visibleViewController?.collapsedHeight(containedIn: contentSheet) ?? UIScreen.main.bounds.height*0.5
    }
    
    //Returning the same height as collapsed height by default
    open override func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return self.visibleViewController?.expandedHeight(containedIn: contentSheet) ?? self.collapsedHeight(containedIn: contentSheet)
    }
    
    open override func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
        return self.visibleViewController?.scrollViewToObserve(containedIn: contentSheet)
    }
    
    open override func prefersStatusBarHidden(contentSheet: ContentSheet) -> Bool {
        return self.visibleViewController?.prefersStatusBarHidden(contentSheet: contentSheet) ?? false
    }
    
    open override func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return self.visibleViewController?.preferredStatusBarStyle(contentSheet: contentSheet) ?? .default
    }
    
    open override func preferredStatusBarUpdateAnimation(contentSheet: ContentSheet) -> UIStatusBarAnimation {
        return self.visibleViewController?.preferredStatusBarUpdateAnimation(contentSheet: contentSheet) ?? .fade
    }
}


extension UIView: ContentSheetContentProtocol {
    
    open var view: UIView! {
        get {
            return self
        }
    }
    
    //MARK: Presentation
    open func dismissContentSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.contentSheet()?.dismiss(animated: true, completion: completion)
    }
    
    //MARK: Utility
    public func contentSheet() -> ContentSheet? {
        return ContentSheet.contentSheet(content: self)
    }
}





