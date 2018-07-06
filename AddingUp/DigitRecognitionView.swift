//
//  DigitRecognitionView.swift
//  AddingUp
//
//  Created by Daniel Jinks on 04/07/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import UIKit
import CoreML

class DigitRecognitionView: UIView {
    private let writingView = UIImageView()
    let writtenView = UIImageView(image: #imageLiteral(resourceName: "black_background"))
    var delegate: DigitRecognitionViewDelegate?
    
    //drawing
    private var lastPoint = CGPoint.zero
    private var color = UIColor.white.cgColor
    @IBInspectable var brushWidth: CGFloat = 10.0
    @IBInspectable var waitForStrokes = 1.0
    private var opacity: CGFloat = 1.0
    
    private var swiped = false
    private var numberDetectionModel = MNIST()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createSubviews()
    }
    
    func createSubviews() {
        writingView.frame = self.bounds
        writtenView.frame = self.bounds
        
        self.backgroundColor = UIColor.white
        writingView.backgroundColor = UIColor.clear
        writtenView.backgroundColor = UIColor.clear
        
        self.addSubview(writtenView)
        self.addSubview(writingView)
        
    }
    
    
    func testForNumber() {
        
        let comAndSquare = writtenView.image!.getCenterOfMassAndBoundingSquare()
        let rect = comAndSquare.square
        let com = comAndSquare.center
        
        let xTranslate = ((rect.minX + rect.maxX) / 2 - com.x) * 20 / rect.width
        let yTranslate = ((rect.minY + rect.maxY) / 2 - com.y) * 20 / rect.height
        
        let cgImage = writtenView.image!.cgImage!.cropping(to: rect)!
        let croppedImage = UIImage(cgImage: cgImage)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 28, height: 28), false, 0.0);
        #imageLiteral(resourceName: "black_background").draw(at: CGPoint.zero)
        croppedImage.draw(in: CGRect(x: 4.0 + xTranslate, y: 4.0 + yTranslate, width: 20, height: 20))
        let inputImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        if let output = try? numberDetectionModel.prediction(image: inputImage.pixelBuffer()!) {
            let num = Int(output.classLabel)
            delegate?.found(digit: num, sender: self)
            //writtenView.image = #imageLiteral(resourceName: "black_background")
        }
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: self)
            latestCheckNo += 1
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(writingView.bounds.size)
        let context = UIGraphicsGetCurrentContext()
        writingView.image?.draw(in: CGRect(x: 0, y: 0, width: writingView.bounds.size.width, height: writingView.bounds.size.height))
        
        context!.move(to: fromPoint)
        context!.addLine(to: toPoint)
        
        context!.setLineCap(CGLineCap.round)
        context!.setLineWidth(brushWidth)
        context!.setStrokeColor(color)
        context!.setBlendMode(.normal)
        
        context!.strokePath()
        
        writingView.image = UIGraphicsGetImageFromCurrentImageContext()
        writingView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: writingView)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
        
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(writingView.bounds.size)
        writtenView.image?.draw(in: CGRect(x: 0, y: 0, width: writingView.bounds.size.width, height: writingView.bounds.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        writingView.image?.draw(in: CGRect(x: 0, y: 0, width: writingView.bounds.size.width, height: writingView.bounds.size.height), blendMode: CGBlendMode.normal, alpha: opacity)
        writtenView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        writingView.image = nil
        waitAndThenTestForNumber()
    }
    
    var latestCheckNo = 0
    func waitAndThenTestForNumber() {
        let deadline = DispatchTime.now() + waitForStrokes
        let checkNo = latestCheckNo
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            if checkNo == self.latestCheckNo {
                self.latestCheckNo = 0
                self.testForNumber()
            }
        }
    }
    
}

protocol DigitRecognitionViewDelegate {
    func found(digit: Int, sender: DigitRecognitionView)
}

fileprivate extension UIImage {
    
    func getCenterOfMassAndBoundingSquare() -> (center:CGPoint, square:CGRect) {
        var lightnessXProduct: CGFloat = 0.0
        var lightnessYProduct: CGFloat = 0.0
        
        var totalLightness: CGFloat = 0.0
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        var minX = width - 1
        var maxX = 0
        var minY = height - 1
        var maxY = 0
        for i in 0..<width {
            for j in 0..<height {
                let color = getPixelColor(pos: CGPoint(x: i, y: j))
                var lightness: CGFloat = 0.0
                color!.getWhite(&lightness, alpha: nil)
                if lightness > 0.01 {
                    lightnessXProduct += lightness * CGFloat(i)
                    lightnessYProduct += lightness * CGFloat(j)
                    totalLightness += lightness
                    if i < minX { minX = i }
                    if i > maxX { maxX = i }
                    if j < minY { minY = j }
                    if j > maxY { maxY = j }
                }
            }
        }
        let squareCenter = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let sideLength = CGFloat(max(maxX - minX, maxY - minY))
        let boundingSquare = CGRect(x: squareCenter.x - sideLength / 2, y: squareCenter.y - sideLength / 2, width: sideLength, height: sideLength)
        
        let massCenter = CGPoint(x: lightnessXProduct / totalLightness, y: lightnessYProduct / totalLightness)
        return (center: massCenter, square: boundingSquare)
    }
    
    func getPixelColor(pos: CGPoint) -> UIColor? {
        
        guard let cgImage = cgImage, let pixelData = cgImage.dataProvider?.data else { return nil }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        
        let pixelInfo: Int = ((cgImage.bytesPerRow * Int(pos.y)) + (Int(pos.x) * bytesPerPixel))
        
        let b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_OneComponent8,
                                         nil, //attrs,
            &pixelBuffer)
        
        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
        
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: grayColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                                        return nil
        }
        
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return resultPixelBuffer
    }
}
