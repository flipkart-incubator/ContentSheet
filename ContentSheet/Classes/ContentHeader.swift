//
//  ContentHeader.swift
//  ContentSheet
//
//  Created by Naveen Chaudhary on 30/07/18.
//

@objc public class ContentHeaderView: UIView {
    
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isTranslucent = true
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isTranslucent = true
    }
    
    @objc public var isTranslucent: Bool = true {
        didSet {
            if isTranslucent {
                self._setBlurrEffect(true)
            } else {
                self._setBlurrEffect(false)
            }
        }
    }
    
    fileprivate var _blurEffectView: UIVisualEffectView?
    
    private func _setBlurrEffect(_ add: Bool) {
        let onView = self
        if add {
            let blurEffectStyle: UIBlurEffect.Style
            if #available(iOS 10.0, *) {
                blurEffectStyle = .regular
            } else {
                blurEffectStyle = .light
            }
            let blurEffect = UIBlurEffect(style: blurEffectStyle)
            _blurEffectView = UIVisualEffectView(effect: blurEffect)
            if let blurEffectView = _blurEffectView {
                blurEffectView.backgroundColor = UIColor.clear
                blurEffectView.frame = onView.bounds
                onView.insertSubview(blurEffectView, at: 0)
            }
        } else {
            onView.alpha = 1
            if let blurEffectView = _blurEffectView {
                blurEffectView.removeFromSuperview()
            }
            _blurEffectView = nil
        }
    }
}
