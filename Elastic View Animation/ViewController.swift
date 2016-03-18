//
//  ViewController.swift
//  Elastic View Animation
//
//  Created by Ugo Besa on 18/03/2016.
//  Copyright © 2016 Ugo Besa. All rights reserved.
//

import UIKit

extension UIView {
    
    
    // When you animate UIView from one frame to another and you are trying to access UIView.frame,
    // UIView.center it will give you the final animation value instead of the current.
    // to get the currentFrame during the animation we use presentationLayer()
    func dg_center(usePresentationLayerIfPossible: Bool) -> CGPoint {
        if usePresentationLayerIfPossible, let presentationLayer = layer.presentationLayer() as? CALayer {
            return presentationLayer.position
        }
        return center
    }
}

class ViewController: UIViewController {
    
    private let minimalHeight: CGFloat = 50.0
    private let maxWaveHeight: CGFloat = 100.0
    
    private let shapeLayer = CAShapeLayer()
    
    // Control Point Views
    private let l3ControlPointView = UIView()
    private let l2ControlPointView = UIView()
    private let l1ControlPointView = UIView()
    private let cControlPointView = UIView()
    private let r1ControlPointView = UIView()
    private let r2ControlPointView = UIView()
    private let r3ControlPointView = UIView()
    
    private var displayLink: CADisplayLink!
    
    private var animating = false {
        didSet {
            view.userInteractionEnabled = !animating
            displayLink.paused = !animating
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    override func loadView() {
        super.loadView()
        
        shapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: minimalHeight)
        shapeLayer.fillColor = UIColor(red: 57/255.0, green: 67/255.0, blue: 89/255.0, alpha: 1.0).CGColor
        view.layer.addSublayer(shapeLayer)
        shapeLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]  // disable implicit animations
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "panGestureDidMove:"))
        
        let pointViews = [l3ControlPointView,l2ControlPointView,l1ControlPointView,cControlPointView,r1ControlPointView,r2ControlPointView,r3ControlPointView]
        for v in pointViews {
            v.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
            //v.backgroundColor = .redColor()
            view.addSubview(v)
        }
        
        layoutControlPoints(baseHeight: minimalHeight, waveHeight: 0.0, locationX: view.bounds.width / 2.0)
        updateShapeLayer()
        
        displayLink = CADisplayLink(target: self, selector: Selector("updateShapeLayer"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        displayLink.paused = true
        
    }
    
    func panGestureDidMove(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Ended || gesture.state == .Failed || gesture.state == .Cancelled {
            let centerY = minimalHeight
            
            animating = true
            UIView.animateWithDuration(0.9, delay: 0.0, usingSpringWithDamping: 0.57, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
                self.l3ControlPointView.center.y = centerY
                self.l2ControlPointView.center.y = centerY
                self.l1ControlPointView.center.y = centerY
                self.cControlPointView.center.y = centerY
                self.r1ControlPointView.center.y = centerY
                self.r2ControlPointView.center.y = centerY
                self.r3ControlPointView.center.y = centerY
                }, completion: { _ in
                    self.shapeLayer.frame.size.height = self.minimalHeight // Useful ??
                    self.animating = false
            })
        } else {
            let additionalHeight = max(gesture.translationInView(view).y, 0)
            
            let waveHeight = min(additionalHeight * 0.6, maxWaveHeight)
            let baseHeight = minimalHeight + additionalHeight - waveHeight
            
            let locationX = gesture.locationInView(gesture.view).x
            
            layoutControlPoints(baseHeight: baseHeight, waveHeight: waveHeight, locationX: locationX)
            updateShapeLayer()
        }
    }
    
    private func currentPath() -> CGPath {
        let width = view.bounds.width
        
        let bezierPath = UIBezierPath()
        
        bezierPath.moveToPoint(CGPoint(x: 0.0, y: 0.0))
        bezierPath.addLineToPoint(CGPoint(x: 0.0, y: l3ControlPointView.dg_center(animating).y))
        bezierPath.addCurveToPoint(l1ControlPointView.dg_center(animating), controlPoint1: l3ControlPointView.dg_center(animating), controlPoint2: l2ControlPointView.dg_center(animating))
        bezierPath.addCurveToPoint(r1ControlPointView.dg_center(animating), controlPoint1: cControlPointView.dg_center(animating), controlPoint2: r1ControlPointView.dg_center(animating))
        bezierPath.addCurveToPoint(r3ControlPointView.dg_center(animating), controlPoint1: r1ControlPointView.dg_center(animating), controlPoint2: r2ControlPointView.dg_center(animating))
        bezierPath.addLineToPoint(CGPoint(x: width, y: 0.0))
        
        bezierPath.closePath()
        
        return bezierPath.CGPath
    }
    
    func updateShapeLayer() {
        shapeLayer.path = currentPath()
    }
    
    
    
//    baseHeight - the height of the "base". baseHeight + waveHeight = our full height;
//    waveHeight - wave of our curve, we want it to have max value which we defined before. Without max value it may look really weird.
//    locationX - X location of the finger in the view (apex of our wave);
//    width -  width of our view;
//    minLeftX - defines minimal position X for l3ControlPointView. This value can go less than zero, so it visually looks nice and clean.
//    maxRightX - same as minLeftX, but defines maximal position X for r3ControlPointView;
//    leftPartWidth - defines distance between minLeftX and locationX;
//    rightPartWidth - defines distance between locationX and maxRightX
    private func layoutControlPoints(baseHeight baseHeight: CGFloat, waveHeight: CGFloat, locationX: CGFloat) {
        let width = view.bounds.width
        
        let minLeftX = min((locationX - width / 2.0) * 0.28, 0.0)
        let maxRightX = max(width + (locationX - width / 2.0) * 0.28, width)
        
        let leftPartWidth = locationX - minLeftX
        let rightPartWidth = maxRightX - locationX
        
        l3ControlPointView.center = CGPoint(x: minLeftX, y: baseHeight)
        l2ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.44, y: baseHeight)
        l1ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
        cControlPointView.center = CGPoint(x: locationX , y: baseHeight + waveHeight * 1.36)
        r1ControlPointView.center = CGPoint(x: maxRightX - rightPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
        r2ControlPointView.center = CGPoint(x: maxRightX - (rightPartWidth * 0.44), y: baseHeight)
        r3ControlPointView.center = CGPoint(x: maxRightX, y: baseHeight)
    }


}

