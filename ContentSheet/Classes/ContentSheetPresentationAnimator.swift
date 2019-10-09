//
//  ContentSheetPresentationAnimator.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 24/09/19.
//

import Foundation

@objc public enum PanDirection: Int {
    case up
    case down
}

@objc public enum ContentSheetState: UInt {
    case minimised
    case collapsed
    case expanded
}

@objc public protocol ViewPresentationProtocol: class {
    @objc var presentationDirection: PresentationDirection {get set}
    @objc var state: ContentSheetState {get set}
    @objc func viewWillStartPresentation(_ contentSheet: ContentSheet)
    @objc func viewDidStartPresentation(_ contentSheet: ContentSheet)
    @objc func viewWillEndPresentation(_ contentSheet: ContentSheet)
    @objc func getIntialViewFrame(in bounds: CGRect) -> CGRect
    @objc func panGestureInitiated(recognizer: UIPanGestureRecognizer, in contentSheet: ContentSheet)
    @objc optional func getPanDirection(_ gesture: UIPanGestureRecognizer, sheet contentSheet: ContentSheet, possibleStateChange possibleState: ContentSheetState) -> PanDirection
    @objc optional func getPossibleStateChange(currentYPosition: CGFloat, parentHeight: CGFloat) -> ContentSheetState
    @objc func resetViewFrame(sheet contentSheet: ContentSheet)
}

@objc public protocol ViewPresentationUpdateProtocol: class {
    @objc func getCollapsedHeight() -> CGFloat
    @objc func getExpandedHeight() -> CGFloat
    @objc func updateContentContainerFrame(updatedFrame frame: CGRect)
    @objc func dismissContentSheet(withDuration duration: Double)
    @objc func updateScrollingBehavior(isScrollEnabled: Bool)
    @objc func updateWhenPanGestureCompleted()
}

@objc public class ContentSheetPresentationAnimator: NSObject,ViewPresentationProtocol {
    
    open var collapsedHeight: CGFloat {
        return delegate?.getCollapsedHeight() ?? 0.0
    }
    
    open var expandedHeight: CGFloat {
        return delegate?.getExpandedHeight() ?? 0.0
    }
    
    //State
    @objc public var state: ContentSheetState = .minimised
    
    weak var delegate: ViewPresentationUpdateProtocol?
    
    public var presentationDirection: PresentationDirection = .bottomToTop
    
    public func viewWillStartPresentation(_ contentSheet: ContentSheet) {
        var frame = contentSheet._contentContainer.frame
        switch presentationDirection {
        case .bottomToTop,.topToBottom:
            frame.origin.y = contentSheet.view.bounds.height - self.collapsedHeight
        case .rightToLeft,.leftToRight:
            frame.origin.x = 0
        }
        contentSheet.transitionCoordinator?.animate(alongsideTransition: {[weak self] (_) in
            guard let `self` = self else {return}
            self.delegate?.updateContentContainerFrame(updatedFrame: frame)
        }, completion: nil)
    }
    
    public func viewDidStartPresentation(_ contentSheet: ContentSheet) {
        self.state = .collapsed
    }
    
    public func viewWillEndPresentation(_ contentSheet: ContentSheet) {
        var frame = contentSheet._contentContainer.frame
        frame.origin.y = contentSheet.view.frame.maxY
        contentSheet.transitionCoordinator?.animate(alongsideTransition: {[weak self] (_) in
            self?.delegate?.updateContentContainerFrame(updatedFrame: frame)
        }, completion: nil)
    }
    
    public func resetViewFrame(sheet contentSheet: ContentSheet) {
        let originY = (contentSheet.view.frame.height - self.collapsedHeight)
        let frame = CGRect(x: 0, y: originY, width: contentSheet._contentContainer.frame.width, height: self.collapsedHeight)
        UIView.animate(withDuration: 0.2) {[weak self] () in
            self?.delegate?.updateContentContainerFrame(updatedFrame: frame)
        }
    }
    
    public func getIntialViewFrame(in bounds: CGRect) -> CGRect {
        let frame: CGRect
        switch presentationDirection {
        case .bottomToTop:
            frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: collapsedHeight)
        case .topToBottom:
            frame = CGRect(x: 0, y: 0, width: bounds.width, height: collapsedHeight)
        case .rightToLeft:
            frame = CGRect(x: bounds.width, y: bounds.height - self.collapsedHeight, width: bounds.width, height: collapsedHeight)
        case .leftToRight:
            frame = CGRect(x: -bounds.width, y: bounds.height - self.collapsedHeight, width: bounds.width, height: collapsedHeight)
        }
        return frame
    }
    
    public func panGestureInitiated(recognizer: UIPanGestureRecognizer, in contentSheet: ContentSheet) {
        if recognizer.state == .began || recognizer.state == .changed {
            updateContentWhenGestureBegan(recognizer: recognizer, sheet: contentSheet)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            updateContentWhenGestureEnds(recognizer: recognizer, sheet: contentSheet)
        }
    }
    
    fileprivate func updateContentWhenGestureBegan(recognizer: UIPanGestureRecognizer, sheet contentSheet: ContentSheet) {
        let translation = recognizer.translation(in: contentSheet.view)
        let totalHeight = contentSheet.view.frame.height
        let y = contentSheet._contentContainer.frame.minY
        if (y + translation.y >= totalHeight - expandedHeight) && (y + translation.y <= totalHeight/* - collapsedHeight*/) {
            let frame = CGRect(x: 0, y: y + translation.y, width: contentSheet._contentContainer.frame.width, height: totalHeight - (y + translation.y))
            recognizer.setTranslation(CGPoint.zero, in: contentSheet.view)
            delegate?.updateContentContainerFrame(updatedFrame: frame)
        }
    }
    
    fileprivate func updateContentWhenGestureEnds(recognizer: UIPanGestureRecognizer, sheet contentSheet: ContentSheet) {
        let y = contentSheet._contentContainer.frame.minY, totalHeight = contentSheet.view.frame.height
        let possibleState = getPossibleStateChange(currentYPosition: y, parentHeight: totalHeight)
        let minY = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
        let maxY = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight
        let direction: PanDirection = getPanDirection(recognizer, sheet: contentSheet, possibleStateChange: possibleState)
        let progress = direction == .down ? (y - minY)/(maxY - minY) : (maxY - y)/(maxY - minY)
        let duration = (1 - Double(progress))*(ContentSheetHelper.TotalDuration)
        let finalState = getFinalState(possibleState: possibleState, direction: direction)
        if finalState == .minimised {
            delegate?.dismissContentSheet(withDuration: duration)
            return
        }
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.8,
                       options: [.allowUserInteraction],
                       animations: {[weak self] () in
                           self?.animateToFinalPosition(finalState: finalState, sheet: contentSheet)
                       },
                       completion: {[weak self] (_: Bool) in
                        self?.state = finalState
                        self?.delegate?.updateWhenPanGestureCompleted()
                        self?.delegate?.updateScrollingBehavior(isScrollEnabled: self?.checkScrollingAllowedWhenGestureEnds(withState: finalState) ?? false)
        })
    }
    
    
    public func getPossibleStateChange(currentYPosition: CGFloat, parentHeight: CGFloat) -> ContentSheetState {
        if expandedHeight <= collapsedHeight {
            return .minimised
        }
        let possibleState: ContentSheetState
        if self.state == .expanded {
            possibleState = .collapsed
        } else if self.state == .collapsed {
            if currentYPosition > parentHeight - collapsedHeight {
                possibleState = .minimised
            } else {
                possibleState = .expanded
            }
        } else {
            possibleState = .minimised
        }
        return possibleState
    }
    
    public func getPanDirection(_ gesture: UIPanGestureRecognizer, sheet contentSheet: ContentSheet, possibleStateChange possibleState: ContentSheetState) -> PanDirection {
        
        let velocity = gesture.velocity(in: contentSheet.view)
        let progress = contentSheet._contentContainer.frame.minY, totalHeight = contentSheet.view.frame.height
        
        let min = possibleState == .minimised ? totalHeight - collapsedHeight : totalHeight - expandedHeight
        let max = possibleState == .minimised ? totalHeight : totalHeight - collapsedHeight //totalHeight - collapsedHeight//
        
        let ratio = (max - progress)/(progress - min)
        let thresholdVelocitySquare = (ratio >= 0.5 && ratio <= 2.0) ? 0.0 : ContentSheetHelper.ThresholdVelocitySquare
        
        let direction: PanDirection
        
        if (pow(velocity.y, 2) < thresholdVelocitySquare) {
            direction = max - progress > progress - min ? .up : .down
        } else {
            direction = velocity.y < 0 ? .up : .down
        }
        
        return direction
    }
    
    fileprivate func getFinalState(possibleState: ContentSheetState, direction: PanDirection) -> ContentSheetState {
        let finalState: ContentSheetState
        if self.state == .collapsed {
            if possibleState == .minimised {
                finalState = direction == .up ? .collapsed : .minimised
            } else {
                finalState = direction == .up ? .expanded : .collapsed
            }
        } else if self.state == .expanded {
            finalState = direction == .up ? .expanded : .collapsed
        } else {
            finalState = .minimised
        }
        return finalState
    }
    
    fileprivate func animateToFinalPosition(finalState: ContentSheetState, sheet contentSheet: ContentSheet) {
        switch finalState {
        case .expanded:
            let y = contentSheet.view.bounds.height - self.expandedHeight
            let frame = CGRect(x: 0, y: y, width: contentSheet._contentContainer.frame.width, height: self.expandedHeight)
            delegate?.updateContentContainerFrame(updatedFrame: frame)
            break
        case .collapsed:
            let frame = CGRect(x: 0, y: contentSheet.view.frame.height - self.collapsedHeight, width: contentSheet._contentContainer.frame.width, height: self.collapsedHeight)
            delegate?.updateContentContainerFrame(updatedFrame: frame)
            break
        default:
            break
        }
    }
    
    fileprivate func checkScrollingAllowedWhenGestureEnds(withState finalState: ContentSheetState) -> Bool {
        var isScrollEnabled: Bool = false
        switch finalState {
        case .expanded:
            isScrollEnabled = true
            break;
        case .collapsed:
            isScrollEnabled = self.collapsedHeight < self.expandedHeight ? false : true
            break;
        default:
            break
        }
        return isScrollEnabled
    }
}
