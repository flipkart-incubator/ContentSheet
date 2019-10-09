//
//  PopUpVerticalPresentationAnimator.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 27/09/19.
//

import Foundation

@objc public class PopUpVerticalPresentationAnimator: NSObject, ViewPresentationProtocol {

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
    
    fileprivate var finalPanDirection: UIPanGestureRecognizer.Direction = .down
    
    public func viewWillStartPresentation(_ contentSheet: ContentSheet) {
        var frame = contentSheet._contentContainer.frame
        frame.origin.y = (contentSheet.view.bounds.height - collapsedHeight) / 2
        contentSheet.transitionCoordinator?.animate(alongsideTransition: {[weak self] (_) in
            guard let `self` = self else {return}
            self.delegate?.updateContentContainerFrame(updatedFrame: frame)
        }, completion: nil)
    }
    
    public func viewDidStartPresentation(_ contentSheet: ContentSheet) {
        self.state = .expanded
    }
    
    public func viewWillEndPresentation(_ contentSheet: ContentSheet) {
        var frame = contentSheet._contentContainer.frame
        switch finalPanDirection {
        case .down:
            frame.origin.y = contentSheet.view.frame.maxY
        case .up:
            frame.origin.y = contentSheet.view.frame.minY
        default:
            frame.origin.y = contentSheet.view.frame.maxY
        }
        contentSheet.transitionCoordinator?.animate(alongsideTransition: {[weak self] (_) in
            self?.delegate?.updateContentContainerFrame(updatedFrame: frame)
            }, completion: nil)
    }
    
    public func popUpWillStartPresentation(_ contentSheet: ContentSheet) {
        var frame = contentSheet._contentContainer.frame
        contentSheet.transitionCoordinator?.animate(alongsideTransition: {[weak self] (_) in
            guard let `self` = self else {return}
            frame.origin.y = (contentSheet.view.bounds.height - self.collapsedHeight)/2
            frame.size.height = self.collapsedHeight
            self.delegate?.updateContentContainerFrame(updatedFrame: frame)
            }, completion: nil)
    }
    
    public func resetViewFrame(sheet contentSheet: ContentSheet) {
        let originY = (contentSheet.view.frame.height - self.collapsedHeight)/2
        let frame = CGRect(x: 0, y: originY, width: contentSheet._contentContainer.frame.width, height: self.collapsedHeight)
        UIView.animate(withDuration: 0.2) {[weak self] () in
            self?.delegate?.updateContentContainerFrame(updatedFrame: frame)
        }
    }
    
    public func getIntialViewFrame(in bounds: CGRect) -> CGRect {
        let frame: CGRect
        switch presentationDirection {
        case .bottomToTop:
            frame = CGRect(x: 10, y: bounds.height, width: bounds.width - 20, height: collapsedHeight)
        case .topToBottom:
            frame = CGRect(x: 10, y: 0, width: bounds.width - 20, height: collapsedHeight)
        default:
            frame =  CGRect(x: 10, y: bounds.height, width: bounds.width - 20, height: collapsedHeight)
        }
        return frame
    }
    
    public func panGestureInitiated(recognizer: UIPanGestureRecognizer, in contentSheet: ContentSheet) {
        let direction: UIPanGestureRecognizer.Direction = recognizer.direction ?? .down
        guard direction == .down || direction == .up else {return}
        finalPanDirection = direction
        if recognizer.state == .began || recognizer.state == .changed {
            updateContentWhenGestureBegan(recognizer: recognizer, sheet: contentSheet)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            updateContentWhenGestureEnds(recognizer: recognizer, sheet: contentSheet)
        }
    }
    
    fileprivate func updateContentWhenGestureBegan(recognizer: UIPanGestureRecognizer, sheet contentSheet: ContentSheet) {
        let translation = recognizer.translation(in: contentSheet.view)
        //let totalHeight = contentSheet.view.frame.height
        let y = contentSheet._contentContainer.frame.minY
        //if (y + translation.y >= totalHeight - expandedHeight) && (y + translation.y <= totalHeight/* - collapsedHeight*/) {
            let frame = CGRect(x: contentSheet._contentContainer.frame.minX, y: y + translation.y, width: contentSheet._contentContainer.frame.width, height: contentSheet._contentContainer.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: contentSheet.view)
            delegate?.updateContentContainerFrame(updatedFrame: frame)
        //}
    }
    
    fileprivate func updateContentWhenGestureEnds(recognizer: UIPanGestureRecognizer, sheet contentSheet: ContentSheet) {
        let finalState = getFinalState(currentYPosition: contentSheet._contentContainer.frame, insheet: contentSheet)
        if finalState == .minimised {
            delegate?.dismissContentSheet(withDuration: 0.5)
            return
        }
        UIView.animate(withDuration: 0.5,
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
                        self?.delegate?.updateScrollingBehavior(isScrollEnabled: self?.isScrollingAllowed(withState: finalState) ?? false)
        })
    }
    
    
    public func getPossibleStateChange() -> ContentSheetState {
        var possibleState: ContentSheetState
        if self.state == .expanded {
            possibleState = .minimised
        } else {
            possibleState = .expanded
        }
        return possibleState
    }
    
    fileprivate func getFinalState(currentYPosition: CGRect, insheet contentSheet: ContentSheet) -> ContentSheetState {
        let finalState: ContentSheetState
        if self.state == .expanded {
            if currentYPosition.minY < contentSheet.view.frame.minY || currentYPosition.maxY > contentSheet.view.frame.maxY {
                finalState = .minimised
            } else {
                finalState = .expanded
            }
        } else {
            finalState = .expanded
        }
        return finalState
    }
    
    fileprivate func animateToFinalPosition(finalState: ContentSheetState, sheet contentSheet: ContentSheet) {
        switch finalState {
        case .expanded:
            let frame = CGRect(x: 10, y: (contentSheet.view.bounds.height - collapsedHeight) / 2, width: contentSheet._contentContainer.frame.width, height: self.collapsedHeight)
            delegate?.updateContentContainerFrame(updatedFrame: frame)
            break
        default:
            break
        }
    }
    
    fileprivate func isScrollingAllowed(withState finalState: ContentSheetState) -> Bool {
        return false
    }
}
