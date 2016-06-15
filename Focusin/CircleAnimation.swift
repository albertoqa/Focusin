//
//  CircleAnimation.swift
//  Focusin
//
//  Created by Alberto Quesada Aranda on 14/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

/* In this app there are two circles: one for the time and one for the target pomodoros to complete */
enum Circles {
    case TIME, TARGET
}

/* Add two layers and animations to the pomodoro view */
public class CircleAnimation {
    
    let defaults = NSUserDefaults.standardUserDefaults()

    // Time circle (big)
    let timeLeftShapeLayer = CAShapeLayer()
    let bgTimeLeftShapeLayer = CAShapeLayer()
    var strokeTimeIt = CABasicAnimation(keyPath: "strokeEnd")
    let radiusBig: CGFloat = 65
    let widthBig: CGFloat = 5

    // Target circle (small)
    let targetShapeLayer = CAShapeLayer()
    let bgTargetShapeLayer = CAShapeLayer()
    let strokeTargetIt = CABasicAnimation(keyPath: "strokeEnd")
    let radiusSmall: CGFloat = 25
    let widthSmall: CGFloat = 2
    
    let mainView: PopoverRootView   // pomodoro view

    let strokeStartValue: Double = 0.0
    let strokeToValue: Double = 1.0
    
    let orangeFull = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1).CGColor
    let orangeAplha = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:0.5).CGColor
    let greenFull = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:1).CGColor
    let greenAlpha = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:0.5).CGColor
    
    // startButton is the position of the Time Circle, fullPomodoros is the position of the Target circle
    init(popoverRootView: PopoverRootView, startButton: NSButton, fullPomodoros: NSTextField) {
        self.mainView = popoverRootView
        
        // Animation circle for the current timer
        drawBgShape(bgTimeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                    radius: radiusBig, lineWidth: widthBig)
        drawShape(timeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                  radius: radiusBig, lineWidth: widthBig)
        
        strokeTimeIt.fromValue = strokeStartValue
        strokeTimeIt.toValue = strokeToValue
        strokeTimeIt.duration = defaults.doubleForKey(Defaults.pomodoroKey)+1
        strokeTargetIt.removedOnCompletion = true
        pauseLayer(Circles.TIME)
        timeLeftShapeLayer.addAnimation(strokeTimeIt, forKey: "timeLeft")
        
        // Animation circle for the target pomodoros
        drawBgShape(bgTargetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                    radius: radiusSmall, lineWidth: widthSmall)
        drawShape(targetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                  radius: radiusSmall, lineWidth: widthSmall)
        
        strokeTargetIt.fromValue = strokeStartValue
        strokeTargetIt.toValue = strokeToValue
        strokeTargetIt.duration = defaults.doubleForKey(Defaults.targetKey)*defaults.doubleForKey(Defaults.pomodoroKey)
        strokeTargetIt.removedOnCompletion = false
        pauseLayer(Circles.TARGET)
        targetShapeLayer.addAnimation(strokeTargetIt, forKey: "target")
    }
    
    /* Draw a cricle on the given layer */
    func drawBgShape(layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = orangeAplha
        layer.fillColor = NSColor.clearColor().CGColor
        layer.lineWidth = lineWidth
        mainView.wantsLayer = true
        mainView.layer!.addSublayer(layer)
    }
    
    /* Draw a circle over the previous circle to make the apparence of fill it */
    func drawShape(layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = orangeFull
        layer.fillColor = NSColor.clearColor().CGColor
        layer.lineWidth = lineWidth
        mainView.layer!.addSublayer(layer)
    }
    
    /* Pause the animation for the given circle */
    func pauseLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    /* Resume the animation for the given circle */
    func resumeLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime = layer.timeOffset
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    /* Reset the animation for the given circle */
    func resetLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        layer.speed = 0.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
    }
    
    /* Restart (reset and start) the animation for the given circle */
    func restartLayer(circle: Circles) {
        resetLayer(circle)
        resumeLayer(circle)
    }
    
    /* Set the color of the circle and the animation */
    func setTimeLayerColor(isPomodoro: Bool) {
        if(isPomodoro) {
            timeLeftShapeLayer.strokeColor = orangeFull
            bgTimeLeftShapeLayer.strokeColor = orangeAplha
        } else {
            timeLeftShapeLayer.strokeColor = greenFull
            bgTimeLeftShapeLayer.strokeColor = greenAlpha
        }
    }
    
    /*func resetLastPomodoro() {
        let pausedTime = targetShapeLayer.timeOffset
        targetShapeLayer.speed = 1.0;
        targetShapeLayer.timeOffset = 0.0;
        targetShapeLayer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = targetShapeLayer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        //targetShapeLayer.beginTime = timeSincePause - (timeSincePause - (timeSincePause%defaults.doubleForKey("pomodoroDuration")))
    }*/

    
    /* Add a new animation for the time left. Remove previous animation before add the new one. */
    func addTimeLeftAnimation(isPomodoro: Bool) {
        if(timeLeftShapeLayer.animationForKey("timeLeft") != nil) {
            timeLeftShapeLayer.removeAnimationForKey("timeLeft")
        }
        
        if(isPomodoro) {
            strokeTimeIt.duration = defaults.doubleForKey(Defaults.pomodoroKey)+1
            timeLeftShapeLayer.addAnimation(strokeTimeIt, forKey: "timeLeft")
        } else {
            strokeTimeIt.duration = defaults.doubleForKey(Defaults.breakKey)+1
            timeLeftShapeLayer.addAnimation(strokeTimeIt, forKey: "timeLeft")
        }
    }
    
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

extension NSBezierPath {
    func CGPath(forceClose forceClose:Bool) -> CGPathRef? {
        var cgPath:CGPathRef? = nil
        
        let numElements = self.elementCount
        if numElements > 0 {
            let newPath = CGPathCreateMutable()
            let points = NSPointArray.alloc(3)
            var bDidClosePath:Bool = true
            
            for i in 0 ..< numElements {
                
                switch elementAtIndex(i, associatedPoints:points) {
                    
                case NSBezierPathElement.MoveToBezierPathElement:
                    CGPathMoveToPoint(newPath, nil, points[0].x, points[0].y )
                    
                case NSBezierPathElement.LineToBezierPathElement:
                    CGPathAddLineToPoint(newPath, nil, points[0].x, points[0].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.CurveToBezierPathElement:
                    CGPathAddCurveToPoint(newPath, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.ClosePathBezierPathElement:
                    CGPathCloseSubpath(newPath)
                    bDidClosePath = true
                }
                
                if forceClose && !bDidClosePath {
                    CGPathCloseSubpath(newPath)
                }
            }
            cgPath = CGPathCreateCopy(newPath)
        }
        return cgPath
    }
}
