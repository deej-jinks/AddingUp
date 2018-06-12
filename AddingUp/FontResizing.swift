//
//  FontResizing.swift
//  AddingUp
//
//  Created by Daniel Jinks on 31/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import UIKit

public func getFontScalingForScreenSize() -> CGFloat {
    var sizeScale: CGFloat = 1
    let height = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
    switch height {
    //iPhone 4 or smaller
    case 0.0 ..< 500.0: sizeScale = 0.75
    //iPhone 5, or iPhone 6 in zoom
    case 500.0 ..< 600.0: sizeScale = 0.85
    //iPhone 6, or iPhone 6 Plus in zoom
    case 600.0 ..< 700.0: sizeScale = 1.0
    //iPhone 6 Plus
    case 700.0 ..< 800.0: sizeScale = 1.1
    //iPhone X
    case 800.0 ..< 1000.0: sizeScale = 1.1
    //iPads
    case 1000.0 ..< 10000.0: sizeScale = 1.8
    default: sizeScale = 1.0
    }
    return sizeScale
}

extension UILabel {
    @IBInspectable
    var adjustFontToRealIPhoneSize: Bool {
        set {
            if newValue {
                let currentFont = self.font
                self.font = currentFont?.withSize((currentFont?.pointSize)! * getFontScalingForScreenSize())
            }
        }
        
        get {
            return false
        }
    }
}

extension UIButton {
    @IBInspectable
    var adjustFontToRealIPhoneSize: Bool {
        set {
            if let label = self.titleLabel {
                label.adjustFontToRealIPhoneSize = true
            }
        }
        get {
            return false
        }
    }
}

extension UITextView {
    
    @IBInspectable
    var adjustFontToRealIPhoneSize: Bool {
        set {
            if newValue {
                let currentFont = self.font
                self.font = currentFont?.withSize((currentFont?.pointSize)! * getFontScalingForScreenSize())
            }
        }
        
        get {
            return false
        }
    }
}

extension UITextField {
    
    @IBInspectable
    var adjustFontToRealIPhoneSize: Bool {
        set {
            if newValue {
                let currentFont = self.font
                self.font = currentFont?.withSize((currentFont?.pointSize)! * getFontScalingForScreenSize())
            }
        }
        
        get {
            return false
        }
    }
}

