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
    case time, target
}

/* Add two layers and animations to the pomodoro view */
open class CircleAnimation {
    
    let defaults = UserDefaults.standard

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
    
    // Short break circle
    let shortBreakShapeLayer = CAShapeLayer()
    
    // Long break circle
    let longBreakShapeLayer = CAShapeLayer()
    
    let mainView: PopoverRootView   // pomodoro view

    let strokeStartValue: Double = 0.0
    let strokeToValue: Double = 1.0
    
    let orangeFull = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1).cgColor
    let orangeAplha = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:0.5).cgColor
    let greenFull = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:1).cgColor
    let greenAlpha = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:0.5).cgColor
    let gray = NSColor.init(red: 0.551, green:0.551, blue:0.551, alpha:1).cgColor
    
    // startButton is the position of the Time Circle, fullPomodoros is the position of the Target circle
    init(popoverRootView: PopoverRootView, startButton: NSButton, fullPomodoros: NSTextField, shortBreak: NSButton, longBreak: NSButton) {
        self.mainView = popoverRootView
        
        // Animation circle for the current timer
        drawBgShape(bgTimeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                    radius: radiusBig, lineWidth: widthBig)
        drawShape(timeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                  radius: radiusBig, lineWidth: widthBig)
        
        strokeTimeIt.fromValue = strokeStartValue
        strokeTimeIt.toValue = strokeToValue
        strokeTimeIt.duration = defaults.double(forKey: Defaults.pomodoroKey)+1
        strokeTargetIt.isRemovedOnCompletion = true
        pauseLayer(Circles.time)
        timeLeftShapeLayer.add(strokeTimeIt, forKey: "timeLeft")
        
        // Animation circle for the target pomodoros
        drawBgShape(bgTargetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                    radius: radiusSmall, lineWidth: widthSmall)
        drawShape(targetShapeLayer, center: CGPoint(x: fullPomodoros.frame.midX, y: fullPomodoros.frame.midY),
                  radius: radiusSmall, lineWidth: widthSmall)
        
        strokeTargetIt.fromValue = strokeStartValue
        strokeTargetIt.toValue = strokeToValue
        strokeTargetIt.duration = defaults.double(forKey: Defaults.targetKey)*defaults.double(forKey: Defaults.pomodoroKey)
        strokeTargetIt.isRemovedOnCompletion = false
        pauseLayer(Circles.target)
        //targetShapeLayer.addAnimation(strokeTargetIt, forKey: "target")
        
        // Static circle for short break
        drawCompleteCircleSpahe(shortBreakShapeLayer, center: CGPoint(x: shortBreak.frame.midX, y: shortBreak.frame.midY-3),
                    radius: radiusSmall, lineWidth: widthSmall, color: greenFull)
        
        // Static circle for long break
        drawCompleteCircleSpahe(longBreakShapeLayer, center: CGPoint(x: longBreak.frame.midX, y: longBreak.frame.midY),
                                radius: radiusSmall, lineWidth: widthSmall, color: gray)

    }
    
    /* Draw a complete static circle */
    func drawCompleteCircleSpahe(_ layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: CGColor) {
        let bez = NSBezierPath()
        bez.appendArc(withCenter: center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 360.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = color
        layer.fillColor = NSColor.clear.cgColor
        layer.lineWidth = lineWidth
        mainView.wantsLayer = true
        layer.zPosition = 1
        mainView.layer!.addSublayer(layer)
    }
    
    /* Draw a cricle on the given layer */
    func drawBgShape(_ layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendArc(withCenter: center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = orangeAplha
        layer.fillColor = NSColor.clear.cgColor
        layer.lineWidth = lineWidth
        mainView.wantsLayer = true
        layer.zPosition = 1
        mainView.layer!.addSublayer(layer)
    }
    
    /* Draw a circle over the previous circle to make the apparence of fill it */
    func drawShape(_ layer: CAShapeLayer, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let bez = NSBezierPath()
        bez.appendArc(withCenter: center, radius:
            radius, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        layer.path = bez.CGPath(forceClose: false)
        layer.strokeColor = orangeFull
        layer.fillColor = NSColor.clear.cgColor
        layer.lineWidth = lineWidth
        layer.zPosition = 1
        mainView.layer!.addSublayer(layer)
    }
    
    /* Pause the animation for the given circle */
    func pauseLayer(_ circle: Circles) {
        let layer = circle == Circles.time ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    /* Resume the animation for the given circle */
    func resumeLayer(_ circle: Circles) {
        let layer = circle == Circles.time ? timeLeftShapeLayer : targetShapeLayer
        let pausedTime = layer.timeOffset
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    /* Reset the animation for the given circle */
    func resetLayer(_ circle: Circles) {
        let layer = circle == Circles.time ? timeLeftShapeLayer : targetShapeLayer
        layer.speed = 0.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
    }
    
    /* Restart (reset and start) the animation for the given circle */
    func restartLayer(_ circle: Circles) {
        resetLayer(circle)
        resumeLayer(circle)
    }
    
    /* Set the color of the circle and the animation */
    func setTimeLayerColor(_ isPomodoro: Bool) {
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
    func addTimeLeftAnimation(_ isPomodoro: Bool, isLongBreak: Bool) {
        if(timeLeftShapeLayer.animation(forKey: "timeLeft") != nil) {
            timeLeftShapeLayer.removeAnimation(forKey: "timeLeft")
        }
        
        if(isPomodoro) {
            strokeTimeIt.duration = defaults.double(forKey: Defaults.pomodoroKey)+1
        } else if(isLongBreak) {
            strokeTimeIt.duration = defaults.double(forKey: Defaults.longBreakKey)+1
        } else {
            strokeTimeIt.duration = defaults.double(forKey: Defaults.shortBreakKey)+1
        }
        timeLeftShapeLayer.add(strokeTimeIt, forKey: "timeLeft")
    }
    
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

extension NSBezierPath {
    func CGPath(forceClose:Bool) -> CGPath? {
        var cgPath:CGPath? = nil
        
        let numElements = self.elementCount
        if numElements > 0 {
            let newPath = CGMutablePath()
            let points = NSPointArray.allocate(capacity: 3)
            var bDidClosePath:Bool = true
            
            for i in 0 ..< numElements {
                
                switch element(at: i, associatedPoints:points) {
                    
                case NSBezierPathElement.moveToBezierPathElement:
                    CGPathMoveToPoint(newPath, nil, points[0].x, points[0].y )
                    
                case NSBezierPathElement.lineToBezierPathElement:
                    CGPathAddLineToPoint(newPath, nil, points[0].x, points[0].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.curveToBezierPathElement:
                    CGPathAddCurveToPoint(newPath, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.closePathBezierPathElement:
                    newPath.closeSubpath()
                    bDidClosePath = true
                }
                
                if forceClose && !bDidClosePath {
                    newPath.closeSubpath()
                }
            }
            cgPath = newPath.copy()
        }
        return cgPath
    }
}
