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

fileprivate let HeaderMinHeight: CGFloat = 44.0

@objc public protocol ContentSheetDelegate {
    
    @objc optional func contentSheetWillAppear(_ sheet: ContentSheet)
    @objc optional func contentSheetDidAppear(_ sheet: ContentSheet)
    @objc optional func contentSheetWillDisappear(_ sheet: ContentSheet)
    @objc optional func contentSheetDidDisappear(_ sheet: ContentSheet)
    
    @objc optional func contentSheetWillShow(_ sheet: ContentSheet)
    @objc optional func contentSheetDidShow(_ sheet: ContentSheet)
    @objc optional func contentSheetWillHide(_ sheet: ContentSheet)
    @objc optional func contentSheetDidHide(_ sheet: ContentSheet)
    
    @objc optional func contentSheetShouldHandleTouches(_ sheet: ContentSheet) -> Bool
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
    
    @objc optional func contentSheetWillBeginTouchHandling(_ sheet: ContentSheet)
}

@objc public enum PresentationType: UInt {
    case contentSheet
    case popUp
}

@objc public enum PresentationDirection: UInt {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft
}

@objc open class ContentSheet: UIViewController {
    
    //MARK: Variables
    
    //Utility
    fileprivate var _safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets
        } else {
            return UIEdgeInsets.init(top: UIApplication.shared.statusBarFrame.maxY, left: 0, bottom: 0, right: 0)
        }
    }
    
    fileprivate var _headerMaxHeight: CGFloat {
        return HeaderMinHeight + _safeAreaInsets.top
    }
    
    //Content controller object
    //Not necessarilly a view controller
    fileprivate var _content: ContentSheetContentProtocol
    fileprivate var _asPopUp: Bool = false
    @objc public var content: ContentSheetContentProtocol {
        get {
            return _content
        }
    }
    
    //Reference to content view of content controller
    var _contentView: UIView?
    
    //Content container
    lazy var _contentContainer: UIView = {
        let view = ContentSheetHelper.getDefaultContentView(in: self.view.bounds)
        self.view.addSubview(view)
        return view
    } ()
    
    //background view for the action sheet
    //default backgorund
    private lazy var _defaultBackground: UIImageView = {
        return ContentSheetHelper.getDefaultImageView(in: self.view.bounds)
    } ()
    
    //background image
    @objc public var backgroundImage: UIImage? {
        didSet {
            _defaultBackground.image = backgroundImage
        }
    }
    
    //background view, can be provided by host or will use the default background
    @objc public var backgroundView: UIView? {
        didSet {
            backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    private var _backgroundView: UIView {
        get {
            let view = backgroundView != nil ? backgroundView! : _defaultBackground
            view.frame = self.view.bounds
            return view
        }
    }
    
    //Settings
    @objc public var blurBackground: Bool = false
    @objc public var blurStyle: UIBlurEffect.Style = .dark
    @objc public var dismissOnTouchOutside: Bool = true
    @objc public var handleKeyboard: Bool = false {
        didSet {
            setUpKeyboardObserving(shouldStart: true)
        }
    }
    @objc public var enablePanGesture: Bool = true {
        didSet {
            self._panGesture.isEnabled = enablePanGesture
        }
    }
    
    //Scroll management related
    fileprivate weak var _scrollviewToObserve: UIScrollView?
    
    open var collapsedHeight: CGFloat = 0.0
    open var expandedHeight: CGFloat = 0.0
    
    fileprivate var _oldCollapsedHeight: CGFloat = 0
    fileprivate var _oldExpandedHeight: CGFloat = 0
    fileprivate var _keyboardFrame: CGRect?
    fileprivate var _keyboardPresent: Bool = false
    fileprivate var _oldScrollInsets: UIEdgeInsets?
    
    //Rotation
    @objc open override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    //Presentation Type
    fileprivate var _presentationType: PresentationType = .contentSheet
    @objc public var presentationType: PresentationType {
        get {
            return _presentationType
        }
    }
    
    fileprivate var _presentationDirection: PresentationDirection = .bottomToTop
    @objc public var presentationDirection: PresentationDirection {
        get {
            return _presentationDirection
        }
    }
    
    //Transition
    fileprivate lazy var _transitionController: UIViewControllerTransitioningDelegate = {
        let controller = ContentSheetTransitionDelegate()
        controller.duration = ContentSheetHelper.TotalDuration
        return controller
    } ()
    
    //Delegate
    @objc public weak var delegate: ContentSheetDelegate?
    
    //Header
    @objc public var showDefaultHeader: Bool = true
    
    private var _navigationBar: UINavigationBar?
    
    @objc public var contentNavigationBar: UINavigationBar? {
        get {
            return _navigationBar
        }
    }
    
    private var _contentHeader: ContentHeaderView?
    
    @objc public var contentHeader: UIView? {
        get {
            return _contentHeader
        }
    }
    
    @objc public var contentNavigationItem: UINavigationItem? {
        get {
            return _navigationBar?.items?.last
        }
    }
    
    private func _defaultHeader() -> ContentHeaderView {
        let (header, navigationBar) = ContentSheetHelper.getDefaultHeader(in: self.view.frame)
        navigationBar.delegate = self
        _navigationBar = navigationBar
        return header
    }
    
    //Gesture
    fileprivate lazy var _panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        return gesture
    } ()
    
    fileprivate var contentSheetPresentationAnimator: ViewPresentationProtocol!
    
    //MARK: Initializers
    //Not implementing required initializer
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) not implemented.")
    }
    
    // required initializer
    @objc public required init(content: ContentSheetContentProtocol, presentationType: PresentationType, presentationDirection: PresentationDirection) {
        _content = content
        _presentationType = presentationType
        _presentationDirection = presentationDirection
        super.init(nibName: nil, bundle: nil)
        initialiseAnimator()
        self.modalPresentationStyle = .custom
    }
    
    //MARK: View lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        //Load content view
        if let contentView = _content.view {
            _contentView = contentView
            updateContentSheetHeader()
            self.setIntialHeights()
        }
        self.view.backgroundColor = UIColor.clear
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if contentSheetPresentationAnimator.state == .minimised {
            //Add background view
            self.view.insertSubview(_backgroundView, at: 0)
            //Add content view
            if let _ = _contentView {
                //Content controller should use this do any preps before content view is added
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                self.setInitialContentContainer()
                _content.contentSheetWillAddContent?(self)
                //Do not expand if no expanded height
                contentSheetPresentationAnimator.viewWillStartPresentation(self)
                delegate?.contentSheetWillShow?(self)
            }
        }
        //Notify delegate that view will appear
        delegate?.contentSheetWillAppear?(self)
        setUpKeyboardObserving(shouldStart: true)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if contentSheetPresentationAnimator.state == .minimised {
            if _contentView != nil {
                //Content controller should use this do any preps after content view is added
                // e.g. in case of view controllers, they might wanna end the appearance transitions
                contentSheetPresentationAnimator.viewDidStartPresentation(self)
                _content.contentSheetDidAddContent?(self)
                _contentContainer.addGestureRecognizer(_panGesture)
                //Notify delegate that sheet did show
                delegate?.contentSheetDidShow?(self)
            }
        }
        //Notify delegate that view did appear
        delegate?.contentSheetDidAppear?(self)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if contentSheetPresentationAnimator.state == .minimised {
            if _contentView != nil {
                //Content controller should use this do any preps before content view is removed
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.contentSheetWillRemoveContent?(self)
                //Animate content
                contentSheetPresentationAnimator.viewWillEndPresentation(self)
                //Notify delegate that sheet will hide
                delegate?.contentSheetWillHide?(self)
            }
        }
        //Notify delegate view will disappear
        delegate?.contentSheetWillDisappear?(self)
        setUpKeyboardObserving(shouldStart: false)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if contentSheetPresentationAnimator.state == .minimised {
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
    @objc open override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            return _transitionController
        }
        set {
            fatalError("Attempt to set transition delegate of content sheet, which is a read only property.")
        }
    }
    
    //Status bar
    @objc open override var prefersStatusBarHidden: Bool {
        get {
            return self.content.prefersStatusBarHidden?(contentSheet: self) ?? false
        }
    }
    
    @objc open override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return self.content.preferredStatusBarStyle?(contentSheet: self) ?? .default
        }
    }
    
    @objc open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        get {
            return self.content.preferredStatusBarUpdateAnimation?(contentSheet: self) ?? .fade
        }
    }
    
    @objc public func resetContentSheetHeight(collapsedHeight: CGFloat, expandedHeight: CGFloat) {
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        contentSheetPresentationAnimator.resetViewFrame(sheet: self)
    }
    
    fileprivate func _startObservingKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardWillAppear(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardWillDisappear(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardDidAppear(_:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardDidDisappear(_:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_keyboardDidChangeFrame(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }
    
    fileprivate func _stopObservingKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }
    
    @objc private func _keyboardWillAppear(_ notification: Notification) {
        if self._keyboardPresent {
            return
        }
        var keyboardHeight: CGFloat = 250
        if let userInfo = notification.userInfo {
            var localKeyboard = true
            if #available(iOS 9.0, *) {
                localKeyboard = userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? self._keyboardPresent
            }
            if !localKeyboard {
                return
            }
            self._keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect(x: 0, y: 0, width: self.view.frame.width, height: keyboardHeight)
            keyboardHeight = self._keyboardFrame?.height ?? keyboardHeight
        }
        
        self._oldCollapsedHeight = self.collapsedHeight
        self._oldExpandedHeight = self.expandedHeight
        
        let maxHeight = expandedHeight;
        
        resetContentSheetHeight(collapsedHeight: min(maxHeight, self._oldCollapsedHeight + keyboardHeight), expandedHeight: min(maxHeight, self._oldExpandedHeight + keyboardHeight))
    }
    
    @objc private func _keyboardDidAppear(_ notification: Notification) {
        if self._keyboardPresent {
            return
        }
        
        if let userInfo = notification.userInfo, let keyboardFrame = self._keyboardFrame {
            self._keyboardPresent = true
            if #available(iOS 9.0, *) {
                self._keyboardPresent = userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? self._keyboardPresent
            }
            if !self._keyboardPresent {
                return
            }
            if let scrollview = _content.scrollViewToObserve?(containedIn: self), let firstResponder = scrollview.firstResponder {
                _scrollviewToObserve = scrollview
                self._oldScrollInsets = scrollview.contentInset
                
                let insets = self._oldScrollInsets ?? UIEdgeInsets.zero
                scrollview.contentInset = UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom + keyboardFrame.height, right: insets.right)
                
                let focusRect = firstResponder.convert(firstResponder.frame, to: scrollview)
                scrollview.scrollRectToVisible(focusRect, animated: true)
            }
        }
    }
    
    @objc private func _keyboardDidDisappear(_ notification: Notification) {
        if self._keyboardPresent {
            self._keyboardPresent = false
            self._keyboardFrame = nil
            
            self._oldCollapsedHeight = self.collapsedHeight
            self._oldExpandedHeight = self.expandedHeight
            
            if let scrollview = _content.scrollViewToObserve?(containedIn: self) {
                _scrollviewToObserve = scrollview
                scrollview.contentInset = self._oldScrollInsets ?? UIEdgeInsets.zero
                self._oldScrollInsets = nil
            }
        }
    }
    
    @objc private func _keyboardWillDisappear(_ notification: Notification) {
        if self._keyboardPresent {
            resetContentSheetHeight(collapsedHeight: self._oldCollapsedHeight, expandedHeight: self._oldExpandedHeight)
        }
    }
    
    @objc private func _keyboardWillChangeFrame(_ notification: Notification) {
        if self._keyboardPresent {
            
            var keyboardHeight: CGFloat = 250
            if let userInfo = notification.userInfo {
                self._keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect(x: 0, y: 0, width: self.view.frame.width, height: keyboardHeight)
                keyboardHeight = self._keyboardFrame?.height ?? keyboardHeight
            }
            
            let maxHeight = expandedHeight;
            
            resetContentSheetHeight(collapsedHeight: min(maxHeight, self.collapsedHeight + keyboardHeight), expandedHeight: min(maxHeight, self.expandedHeight + keyboardHeight))
        }
    }
    
    @objc private func _keyboardDidChangeFrame(_ notification: Notification) {
        if self._keyboardPresent, let keyboardFrame = self._keyboardFrame {
            if let scrollview = _content.scrollViewToObserve?(containedIn: self), let firstResponder = scrollview.firstResponder {
                _scrollviewToObserve = scrollview
                
                let insets = self._oldScrollInsets ?? UIEdgeInsets.zero
                scrollview.contentInset = UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom + keyboardFrame.height, right: insets.right)
                
                let focusRect = firstResponder.convert(firstResponder.frame, to: scrollview)
                scrollview.scrollRectToVisible(focusRect, animated: true)
            }
        }
    }
    
    @objc private func initialiseAnimator() {
        switch presentationType {
        case .contentSheet:
            let animator =  ContentSheetPresentationAnimator()
            animator.delegate = self
            contentSheetPresentationAnimator = animator
        case .popUp:
            switch presentationDirection {
            case .leftToRight,.rightToLeft:
                let animator =  PopUpHorizontalPresentationAnimator()
                animator.delegate = self
                contentSheetPresentationAnimator = animator
            case .bottomToTop,.topToBottom:
                let animator =  PopUpVerticalPresentationAnimator()
                animator.delegate = self
                contentSheetPresentationAnimator = animator
            }
        }
        contentSheetPresentationAnimator.presentationDirection = presentationDirection
    }
    
    @objc private func updateContentSheetHeader() {
        if showDefaultHeader {
            self._contentHeader = _defaultHeader()
            let navigationItem: UINavigationItem = self.content.navigationItem ?? UINavigationItem()
            if navigationItem.leftBarButtonItem == nil {
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelButtonPressed(_:)))
                navigationItem.leftBarButtonItem = cancelButton
            }
            self._navigationBar?.items = [navigationItem]
        }
    }
    
    @objc private func setIntialHeights() {
        let proposedCollapsedHeight = max(_content.collapsedHeight?(containedIn: self) ?? 0.0, 0.0)
        let proposedExpandedHeight = max(_content.expandedHeight?(containedIn: self) ?? 0.0, 0.0)
        collapsedHeight = proposedCollapsedHeight == 0.0 ? ContentSheetHelper.CollapsedHeightRatio*view.bounds.height : proposedCollapsedHeight
        expandedHeight = max(min(proposedExpandedHeight, self.view.frame.height), collapsedHeight)
    }
    
    @objc private func setInitialContentContainer() {
        let frame = contentSheetPresentationAnimator.getIntialViewFrame(in: self.view.bounds)
        _contentContainer.frame = frame
        if let header = contentHeader {
            _contentContainer.addSubview(header)
        }
        _contentView?.frame = frame
        if let contentView = _contentView {
            _contentContainer.addSubview(contentView)
        }
        self._layoutContentSubviews()
    }
    
    @objc private func setUpKeyboardObserving(shouldStart: Bool) {
        self._stopObservingKeyboard()
        if self.handleKeyboard && shouldStart{
            self._startObservingKeyboard()
        }
    }
}



extension ContentSheet {
    
    open override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent is UINavigationController {
            fatalError("Attempt to push content sheet inside a navigation controller. content sheet can only be presented.")
        }
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        contentSheetPresentationAnimator.state = .minimised
        super.dismiss(animated: flag, completion: completion)
    }
    
    @objc fileprivate func cancelButtonPressed(_ sender: UIBarButtonItem?) {
        self.dismiss(animated: true)
    }
}

//MARK: Interaction and gestures
extension ContentSheet {
    
    @objc fileprivate func handlePan(_ recognizer: UIPanGestureRecognizer) {
        if let _ = _contentView {
            contentSheetPresentationAnimator.panGestureInitiated(recognizer: recognizer, in: self)
        }
    }
    
    
    fileprivate func _layoutContentSubviews() {
        
        if let contentView = self._contentView {
            if self.showDefaultHeader, let header = self.contentHeader {
                
                let frame = self._contentContainer.frame
                
                if frame.origin.y < _safeAreaInsets.top {
                    
                    var subviewFrame = CGRect(x: 0, y: 0, width: frame.width, height: min(_headerMaxHeight, (HeaderMinHeight + (_safeAreaInsets.top - frame.origin.y))))
                    header.frame = subviewFrame
                    
                    subviewFrame.origin.y = subviewFrame.maxY
                    subviewFrame.size.height = frame.height - subviewFrame.origin.y
                    
                    contentView.frame = subviewFrame
                    
                } else {
                    var subviewFrame = CGRect(x: 0, y: 0, width: frame.width, height: HeaderMinHeight)
                    header.frame = subviewFrame
                    
                    subviewFrame.origin.y = subviewFrame.maxY
                    subviewFrame.size.height = frame.height - subviewFrame.origin.y
                    
                    contentView.frame = subviewFrame
                }
                
                if let navigationBar = self.contentNavigationBar {
                    navigationBar.frame = CGRect(x: navigationBar.frame.origin.x,
                                                 y: header.bounds.height - navigationBar.frame.height,
                                                 width: navigationBar.frame.width,
                                                 height: navigationBar.frame.height)
                }
            } else {
                contentView.frame = self._contentContainer.bounds
            }
        }
    }
    
    //Touches
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    @objc public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == _panGesture {
            let shouldBegin = (collapsedHeight <= expandedHeight) && (delegate?.contentSheetShouldHandleTouches?(self) ?? true)
            if shouldBegin {
                _content.contentSheetWillBeginTouchHandling?(self)
            }
            return shouldBegin
        }
        return true
    }
    
    
    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
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
        guard self.presentationType != .popUp else {
            return false
        }
        if let direction = contentSheetPresentationAnimator.getPanDirection?(_panGesture, sheet: self, possibleStateChange: contentSheetPresentationAnimator.getPossibleStateChange?(currentYPosition: _contentContainer.frame.minY, parentHeight: self.view.frame.height) ?? .minimised) {
            
            if (collapsedHeight <= expandedHeight)
                &&
                (((scrollView.contentOffset.y + scrollView.contentInset.top == 0) && (direction == .down)) || (contentSheetPresentationAnimator.state == .collapsed && collapsedHeight < expandedHeight)) {
                scrollView.isScrollEnabled = false
            } else {
                scrollView.isScrollEnabled = true
            }
        }
        return false
    }
}

//Convenience
extension ContentSheet {
    @objc public static func contentSheet(content: ContentSheetContentProtocol) -> ContentSheet? {
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
    @objc public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
}

//Delegate methods from ContentSheetPresentationAnimator
extension ContentSheet: ViewPresentationUpdateProtocol {
    
    public func getCollapsedHeight() -> CGFloat {
        return collapsedHeight
    }
    
    public func getExpandedHeight() -> CGFloat {
        return expandedHeight
    }
    
    public func updateContentContainerFrame(updatedFrame frame: CGRect) {
        self._contentContainer.frame = frame
        self._layoutContentSubviews()
    }
    
    public func dismissContentSheet(withDuration duration: Double) {
        (_transitionController as? ContentSheetTransitionDelegate)?.duration = duration
        self.dismiss(animated: true, completion: nil)
    }
    
    public func updateWhenPanGestureCompleted() {
        if let bar = self.contentHeader {
            self._contentContainer.bringSubviewToFront(bar)
        }
    }
    
    public func updateScrollingBehavior(isScrollEnabled: Bool) {
        self._scrollviewToObserve?.isScrollEnabled = isScrollEnabled
    }
}
