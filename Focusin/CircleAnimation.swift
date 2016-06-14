//
//  CircleAnimation.swift
//  Focusin
//
//  Created by Alberto Quesada Aranda on 14/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

enum Circles {
    case TIME, TARGET
}

public class CircleAnimation {
    
    let defaults = NSUserDefaults.standardUserDefaults()

    let timeLeftShapeLayer = CAShapeLayer()
    let bgTimeLeftShapeLayer = CAShapeLayer()
    var strokeTimeIt = CABasicAnimation(keyPath: "strokeEnd")
    
    let targetShapeLayer = CAShapeLayer()
    let bgTargetShapeLayer = CAShapeLayer()
    let strokeTargetIt = CABasicAnimation(keyPath: "strokeEnd")
    
    let mainView: PopoverRootView
    
    init(popoverRootView: PopoverRootView, startButton: NSButton, fullPomodoros: NSTextField) {
        self.mainView = popoverRootView
        
        // Animation circle for the current timer
        drawBgShape(bgTimeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                    radius: 65, lineWidth: 5)
        drawShape(timeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                  radius: 65, lineWidth: 5)
        
        strokeTimeIt.fromValue = 0.0
        strokeTimeIt.toValue = 1.0
        strokeTimeIt.duration = defaults.doubleForKey("pomodoroDuration")+1
        strokeTargetIt.removedOnCompletion = true
        pauseLayer(Circles.TIME)
        timeLeftShapeLayer.addAnimation(strokeTimeIt, forKey: "timeLeft")
        
        // Animation circle for the target pomodoros
        drawBgShape(bgTargetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                    radius: 25, lineWidth: 2)
        drawShape(targetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                  radius: 25, lineWidth: 2)
        
        strokeTargetIt.fromValue = 0.0
        strokeTargetIt.toValue = 1.0
        strokeTargetIt.duration = defaults.doubleForKey("targetPomodoros")*defaults.doubleForKey("pomodoroDuration")
        strokeTargetIt.removedOnCompletion = false
        pauseLayer(Circles.TARGET)
        targetShapeLayer.addAnimation(strokeTargetIt, forKey: "target")

    }
    
    func drawBgShape(layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:0.5).CGColor
        layer.fillColor = NSColor.clearColor().CGColor
        layer.lineWidth = lineWidth
        mainView.wantsLayer = true
        mainView.layer!.addSublayer(layer)
    }
    
    func drawShape(layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1).CGColor
        layer.fillColor = NSColor.clearColor().CGColor
        layer.lineWidth = lineWidth
        mainView.layer!.addSublayer(layer)
    }
    
    func pauseLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime = layer.timeOffset
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func resetLayer(circle: Circles) {
        let layer = circle == Circles.TIME ? timeLeftShapeLayer : targetShapeLayer
        layer.speed = 0.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
    }
    
    func restartLayer(circle: Circles) {
        resetLayer(circle)
        resumeLayer(circle)
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
            strokeTimeIt.duration = defaults.doubleForKey("pomodoroDuration")+1
            timeLeftShapeLayer.addAnimation(strokeTimeIt, forKey: "timeLeft")
        } else {
            strokeTimeIt.duration = defaults.doubleForKey("breakDuration")+1
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
