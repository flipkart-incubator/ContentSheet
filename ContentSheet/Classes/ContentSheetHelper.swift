//
//  ContentSheetHelper.swift
//  ContentSheet
//
//  Created by Sunny Agarwal on 24/09/19.
//

import Foundation

class ContentSheetHelper {
    
    static let ThresholdVelocitySquare: CGFloat = 10000 //100*100
    static let CollapsedHeightRatio: CGFloat = 0.5
    static let TotalDuration: Double = 0.5
    
    static func getDefaultImageView(in bounds: CGRect) -> UIImageView{
        let imageView: UIImageView = UIImageView(frame: bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }
    
    static func getDefaultContentView(in bounds: CGRect) -> UIView{
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    static func getDefaultHeader(in frame: CGRect) -> (ContentHeaderView, UINavigationBar) {
        let header = ContentHeaderView(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 44.0))
        let navigationBar = getDefaultNavigationBar(in: frame)
        header.tintColor = navigationBar.tintColor
        header.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        header.addSubview(navigationBar)
        return (header,navigationBar)
    }
    
    static func getDefaultNavigationBar(in frame: CGRect) -> UINavigationBar {
        let navigationBar = UINavigationBar(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 44.0))
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.barTintColor = UIColor.clear
        navigationBar.backgroundColor = UIColor.clear
        navigationBar.isTranslucent = true
        return navigationBar
    }
}


public extension UIPanGestureRecognizer {
    
    enum Direction: String {
        case up = "UP", down = "DOWN", right = "RIGHT", left = "LEFT"
    }

    internal var direction: Direction? {
        let velocity = self.velocity(in: view)
        let vertical = abs(velocity.y) > abs(velocity.x)
        switch (vertical, velocity.x, velocity.y) {
        case (true, _, let y) where y < 0: return .up
        case (true, _, let y) where y > 0: return .down
        case (false, let x, _) where x > 0: return .right
        case (false, let x, _) where x < 0: return .left
        default: return nil
        }
    }
}
