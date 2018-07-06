//
//  MultipleDigitRecognitionView.swift
//  AddingUp
//
//  Created by Daniel Jinks on 04/07/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import UIKit

class MultipleDigitRecognitionView: UIView, DigitRecognitionViewDelegate {
    
    @IBInspectable var numberOfDigits = 2
    /*    {
        didSet {
            clearDigitViews()
            setUpDigitViews()
        }
    }
 */
    var digitViews: [DigitRecognitionView] = []
    var digits: [Int?] = []
    var delegate: MultipleDigitRecognitonViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpDigitViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpDigitViews()
    }
    
    func found(digit: Int, sender: DigitRecognitionView) {
        digits[sender.tag] = digit
        if sender == digitViews.last! {
            var numString = ""
            for i in 0..<numberOfDigits {
                if let result = digits[i] {
                    numString += "\(result)"
                    
                }
                digits[i] = nil
                digitViews[i].writtenView.image = #imageLiteral(resourceName: "black_background")
            }
            delegate?.found(number: Int(numString)!, sender: self)
        }
    }
    
    func clearDigitViews() {
        for dView in digitViews {
            dView.removeFromSuperview()
        }
        digitViews = []
        digits = []
    }
    
    func setUpDigitViews() {
        let dWidth = CGFloat(Int(bounds.width / CGFloat(numberOfDigits) + 0.5))
        let dHeight = CGFloat(Int(bounds.height + 0.5))
        let margin:CGFloat = 2.0
        for i in 0..<numberOfDigits {
            let dFrame = CGRect(x: CGFloat(i) * dWidth + margin, y: 0.0 + margin, width: dWidth - margin * 2, height: dHeight - margin * 2)
            let dView = DigitRecognitionView(frame: dFrame)
            dView.tag = i
            dView.backgroundColor = UIColor.clear
            addSubview(dView)
            dView.delegate = self
            digitViews.append(dView)
            digits.append(nil)
        }
    }
}

protocol MultipleDigitRecognitonViewDelegate {
    func found(number: Int, sender: MultipleDigitRecognitionView)
}
