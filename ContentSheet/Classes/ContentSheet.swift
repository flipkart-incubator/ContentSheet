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



@objc public class ContentSheet: UIViewController {
    
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
    @objc public var content: ContentSheetContentProtocol {
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
            self._stopObservingKeyboard()
            if handleKeyboard {
                self._startObservingKeyboard()
            }
        }
    }
    @objc public var enablePanGesture: Bool = true {
        didSet {
            self._panGesture.isEnabled = enablePanGesture
        }
    }
    
    //Scroll management related
    fileprivate weak var _scrollviewToObserve: UIScrollView?
    
    fileprivate var collapsedHeight: CGFloat = 0.0
    fileprivate var expandedHeight: CGFloat = 0.0

    fileprivate var _oldCollapsedHeight: CGFloat = 0
    fileprivate var _oldExpandedHeight: CGFloat = 0
    fileprivate var _keyboardFrame: CGRect?
    fileprivate var _keyboardPresent: Bool = false
    fileprivate var _oldScrollInsets: UIEdgeInsets?

    //Rotation
    @objc public override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    //State
    fileprivate var _state: ContentSheetState = .minimised
    @objc public var state: ContentSheetState {
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
        
        var frame = self.view.frame
        frame.size.height = 44.0;
        
        let navigationBar = UINavigationBar(frame: frame)
        navigationBar.delegate = self
        
        _navigationBar = navigationBar
        
        let header = ContentHeaderView(frame: frame)
        header.tintColor = navigationBar.tintColor
        header.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.barTintColor = UIColor.clear
        navigationBar.backgroundColor = UIColor.clear
        navigationBar.isTranslucent = true

        header.addSubview(navigationBar)
        
        return header
    }
    

    //Gesture
    fileprivate lazy var _panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        return gesture
    } ()
    
    
    //MARK: Initializers
    //Not implementing required initializer
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) not implemented.")
    }
    
    // required initializer
    // content controller is non-optional
    @objc public required init(content: ContentSheetContentProtocol) {
        _content = content
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
    }
    
    //MARK: View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load content view
        if let contentView = _content.view {
            _contentView = contentView
            
            if showDefaultHeader {
                
                self._contentHeader = _defaultHeader()
                
                let navigationItem: UINavigationItem
                
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
                
                if let header = self.contentHeader {
                    _contentContainer.addSubview(header)
                }
                
                contentView.frame = frame
                
                //Content controller should use this do any preps before content view is added
                // e.g. in case of view controllers, they might wanna prepare for appearance transitions
                _content.contentSheetWillAddContent?(self)
                _contentContainer.addSubview(contentView)
                
                //Layout content
                self._layoutContentSubviews()
                
                //Do not expand if no expanded height
                expandedHeight = max(min(max(_content.expandedHeight?(containedIn: self) ?? 0.0, 0.0), self.view.frame.height), collapsedHeight)
                
                
                self.transitionCoordinator?.animate(alongsideTransition: { (_) in
                    //Animate content
                    frame.origin.y = self.view.bounds.height - self.collapsedHeight
                    frame.size.height = self.collapsedHeight
                    self._contentContainer.frame = frame
                    self._layoutContentSubviews()
                }, completion: nil)
                
                //Notify delegate that sheet will show
                delegate?.contentSheetWillShow?(self)
            }
        }
        
        //Notify delegate that view will appear
        delegate?.contentSheetWillAppear?(self)
        
        if self.handleKeyboard {
            self._stopObservingKeyboard()
            self._startObservingKeyboard()
        }
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

        if self.handleKeyboard {
            self._stopObservingKeyboard()
        }
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
    @objc public override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            return _transitionController
        }
        set {
            fatalError("Attempt to set transition delegate of content sheet, which is a read only property.")
        }
    }
    
    //Status bar
    @objc public override var prefersStatusBarHidden: Bool {
        get {
            return self.content.prefersStatusBarHidden?(contentSheet: self) ?? false
        }
    }
    
    @objc public override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return self.content.preferredStatusBarStyle?(contentSheet: self) ?? .default
        }
    }
    
    @objc public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        get {
            return self.content.preferredStatusBarUpdateAnimation?(contentSheet: self) ?? .fade
        }
    }
    
    @objc public func resetContentSheetHeight(collapsedHeight: CGFloat, expandedHeight: CGFloat) {
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        
        let frame = CGRect(x: 0, y: self.view.frame.height - self.collapsedHeight, width: self._contentContainer.frame.width, height: self.collapsedHeight)
        
        UIView.animate(withDuration: 0.2) {
            self._contentContainer.frame = frame
            self._layoutContentSubviews()
        }
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
}



extension ContentSheet {
    
   public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
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
                                    
                                    self._layoutContentSubviews()
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
                                    
                                    if let bar = strong.contentHeader {
                                        strong._contentContainer.bringSubviewToFront(bar)
                                    }
                                    
                                    switch finalState {
                                    case .expanded:
                                        strong._scrollviewToObserve?.isScrollEnabled = true
                                        break;
                                    case .collapsed:
                                        strong._scrollviewToObserve?.isScrollEnabled = strong.collapsedHeight < strong.expandedHeight ? false : true
                                        strong._layoutContentSubviews()
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
            
            self._layoutContentSubviews()
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
    
    @objc public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == _panGesture {
            return collapsedHeight <= expandedHeight
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
        
        
        
        let direction = _panDirection(_panGesture, view: _contentContainer, possibleStateChange: _possibleStateChange(_contentContainer.frame.minY))
        
        if (collapsedHeight <= expandedHeight)
            &&
            (((scrollView.contentOffset.y + scrollView.contentInset.top == 0) && (direction == .down)) || (_state == .collapsed && collapsedHeight < expandedHeight)) {
            scrollView.isScrollEnabled = false
        } else {
            scrollView.isScrollEnabled = true
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
    @objc open func present(inContentSheet content: ContentSheetContentProtocol, animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        
        let contentSheet = ContentSheet(content: content)
        self.present(contentSheet, animated: true, completion: completion)
    }
    
    @objc open func dismissContentSheet(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        self.contentSheet()?.dismiss(animated: true, completion: completion)
    }
}


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



