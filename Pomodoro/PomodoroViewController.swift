//
//  PomodoroViewController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class PomodoroViewController: NSViewController, PreferencesDelegate {

    @IBOutlet var mainView: PopoverRootView!
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var fullPomodoros: NSTextField!
    @IBOutlet weak var currentTask: NSTextField!

    let defaults = NSUserDefaults.standardUserDefaults()
    var timer: Timer!
    var isActive: Bool = false

    var preferencesWindow: PreferencesWindowController!
    var aboutWindow: AboutWindowController!
    
    var updateStatusTimer: NSTimer = NSTimer()
    
    let timeLeftShapeLayer = CAShapeLayer()
    let bgShapeLayer = CAShapeLayer()
    var endTime: NSDate!
    let strokeIt = CABasicAnimation(keyPath: "strokeEnd")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferencesWindow = PreferencesWindowController()
        aboutWindow = AboutWindowController()
        preferencesWindow.delegate = self
        
        timer = Timer(defaults.integerForKey("pomodoroDuration"), defaults.integerForKey("breakDuration"))

        drawBgShape()
        drawTimeLeftShape()
        
        strokeIt.fromValue = 0.0
        strokeIt.toValue = 1.0
        strokeIt.duration = defaults.doubleForKey("pomodoroDuration")+1
        strokeIt.removedOnCompletion = false
        pauseLayer(timeLeftShapeLayer)
        timeLeftShapeLayer.addAnimation(strokeIt, forKey: "timeLeft")
        
        reset()
        resetButton.hidden = true
    }
    
    /* Set the timer label to the user preferred pomodoro duration, stop the current timer, hide reset button, 
     set start button to play and reset timeLeftShapeLayer */
    func reset() {
        let pomodoroDefaultDuration = defaults.integerForKey("pomodoroDuration")
        timeLabel.stringValue = String(format: "%d:%02d", pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
        fullPomodoros.stringValue = "0/" + defaults.stringForKey("targetPomodoros")!
        resetButton.hidden = true
        startButton.image = NSImage(named: "play")
        resetLayer(timeLeftShapeLayer)
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(sender: NSButton) {
        resetButton.hidden = false
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            pauseLayer(timeLeftShapeLayer)
            updateStatusTimer.invalidate()
            startButton.image = NSImage(named: "play")
        } else {
            startButton.image = NSImage(named: "pause")
            isActive = true
            if(timer.unPause()) {
                resumeLayer(timeLeftShapeLayer)
            } else {
                restartLayer(timeLeftShapeLayer)
            }
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
        }
    }

    /* Stop the current timer and reset all the values */
    @IBAction func resetTimer(sender: AnyObject) {
        timer.resetTimer()
        isActive = false
        updateStatusTimer.invalidate()
        reset()
    }
    
    /* Start a new timer and restart the animation */
    func startTimer(isPomodoro: Bool) {
        if(isPomodoro) {
            timer.startPomodoroTimer()
        } else {
            timer.startBreakTimer()
        }
        restartLayer(timeLeftShapeLayer)
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.valid) {
            timeLabel.stringValue = String(format: "%d:%02d", timer.timeLeft/60, timer.timeLeft%60)
        } else {
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey("targetPomodoros")!
            if(timer.finishedPomodoros >= defaults.integerForKey("targetPomodoros")) {
                let userWantToStartOver = dialogOKCancel("Target achieved!",
                                                    text: "Do you want to start over?",
                                                    b1Text: "Yes",
                                                    b2Text: "Cancel")
                if(userWantToStartOver) {
                    startTimer(true)     // start pomodoro
                } else {
                    resetTimer(self)
                }
            } else if(timer.isPomodoro) {
                let userAceptBreak = dialogOKCancel("Pomodoro completed!",
                                                    text: "Do you want to start the break?",
                                                    b1Text: "Ok",
                                                    b2Text: "New Pomodoro")
                if(userAceptBreak) {
                    startTimer(false)     // start break
                } else {
                    startTimer(true)  // start pomodoro
                }
            } else {
                let userStartNewPomodoro = dialogOKCancel("Break finished!",
                                                          text: "Do you want to start a new pomodoro?",
                                                          b1Text: "New Pomodoro",
                                                          b2Text: "Cancel")
                if(userStartNewPomodoro) {
                    startTimer(true)  // start pomodoro
                } else {
                    // stop timer and wait for user action
                    resetTimer(self)
                }
            }
        }
    }
    
    /* Open a contextual menu with the possible actions: settings, about and quit */
    @IBAction func openSettingsMenu(sender: NSButton) {
        let menu = NSMenu()
        
        menu.insertItemWithTitle("Settings", action: #selector(PomodoroViewController.openPreferences),
                                 keyEquivalent: "", atIndex: 0)
        menu.insertItemWithTitle("About", action: #selector(PomodoroViewController.openAbout),
                                 keyEquivalent: "", atIndex: 1)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 2)
        menu.insertItemWithTitle("Quit", action: #selector(PomodoroViewController.quitApp),
                                 keyEquivalent: "", atIndex: 3)

        NSMenu.popUpContextMenu(menu, withEvent: NSApplication.sharedApplication().currentEvent!, forView: sender as NSButton)
    }
    
    /* Open a new window with the preferences of the application */
    func openPreferences() {
        preferencesWindow.showWindow(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    /* Open a new window with information about the application */
    func openAbout() {
        aboutWindow.showWindow(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    /* Close the application */
    func quitApp() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    /* Called when the default preferences are updated */
    func preferencesDidUpdate() {
        timer.pomodoroDuration = defaults.integerForKey("pomodoroDuration")
        timer.breakDuration = defaults.integerForKey("breakDuration")
    }
    
    /* Show an alert to the user */
    func dialogOKCancel(question: String, text: String, b1Text: String, b2Text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle(b1Text)
        myPopup.addButtonWithTitle(b2Text)
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                                  //
    //    This part of the code was taken from stackoverflow (some modifications where required...)     //
    //  http://stackoverflow.com/questions/30289173/problems-animating-a-countdown-in-swift-sprite-kit  //
    //                                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func drawBgShape() {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(CGPoint(x: startButton.frame.midX , y: startButton.frame.midY), radius:
            50, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        bgShapeLayer.path = bez.CGPath(forceClose: false)
        bgShapeLayer.strokeColor = NSColor.blueColor().CGColor
        bgShapeLayer.fillColor = NSColor.clearColor().CGColor
        bgShapeLayer.lineWidth = 5
        mainView.wantsLayer = true
        mainView.layer!.addSublayer(bgShapeLayer)
    }
    
    func drawTimeLeftShape() {
        let bez = NSBezierPath()
        bez.appendBezierPathWithArcWithCenter(CGPoint(x: startButton.frame.midX, y: startButton.frame.midY), radius:
            50, startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true)
        timeLeftShapeLayer.path = bez.CGPath(forceClose: false)
        timeLeftShapeLayer.strokeColor = NSColor.redColor().CGColor
        timeLeftShapeLayer.fillColor = NSColor.clearColor().CGColor
        timeLeftShapeLayer.lineWidth = 5
        mainView.layer!.addSublayer(timeLeftShapeLayer)
    }
    
    func pauseLayer(layer : CALayer) {
        let pausedTime : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func resetLayer(layer: CALayer) {
        layer.speed = 0.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
    }
    
    func restartLayer(layer: CALayer) {
        resetLayer(layer)
        resumeLayer(layer)
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    
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


