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
    var buttonBar: NSStatusBarButton
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var fullPomodoros: NSTextField!
    @IBOutlet weak var currentTask: NSTextField!
    @IBOutlet weak var removeTaskButton: NSButton!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var timer: Timer!
    var isActive: Bool = false
    var isPomodoro: Bool = true
    var reloadPreferencesOnNextPomodoro = false
    var showTimeInBar: Bool = true

    var preferencesWindow: PreferencesWindowController!
    var aboutWindow: AboutWindowController!
    
    var updateStatusTimer: NSTimer = NSTimer()
    
    let timeLeftShapeLayer = CAShapeLayer()
    let bgTimeLeftShapeLayer = CAShapeLayer()
    var strokeTimeIt = CABasicAnimation(keyPath: "strokeEnd")
    
    let targetShapeLayer = CAShapeLayer()
    let bgTargetShapeLayer = CAShapeLayer()
    let strokeTargetIt = CABasicAnimation(keyPath: "strokeEnd")
    
    init(nibName: String, bundle: NSBundle?, button: NSStatusBarButton) {
        self.buttonBar = button
        super.init(nibName: nibName, bundle: bundle)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferencesWindow = PreferencesWindowController()
        aboutWindow = AboutWindowController()
        preferencesWindow.delegate = self
        
        timer = Timer(defaults.integerForKey("pomodoroDuration"), defaults.integerForKey("breakDuration"))
        showTimeInBar = defaults.integerForKey("showTimeInBar") == NSOnState
        reset()

        // Animation circle for the current timer
        drawBgShape(bgTimeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                    radius: 65, lineWidth: 5)
        drawShape(timeLeftShapeLayer, center: CGPoint(x: startButton.frame.midX, y: startButton.frame.midY),
                  radius: 65, lineWidth: 5)
        
        strokeTimeIt.fromValue = 0.0
        strokeTimeIt.toValue = 1.0
        strokeTimeIt.duration = defaults.doubleForKey("pomodoroDuration")+1
        strokeTargetIt.removedOnCompletion = true
        pauseLayer(timeLeftShapeLayer)
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
        pauseLayer(targetShapeLayer)
        targetShapeLayer.addAnimation(strokeTargetIt, forKey: "target")
        
        // General configuration
        resetButton.hidden = true
        removeTaskButton.hidden = true
        fullPomodoros.stringValue = "0/" + defaults.stringForKey("targetPomodoros")!

        currentTask.placeholderAttributedString = NSAttributedString(string: "What are you working on?", attributes: [NSForegroundColorAttributeName: NSColor.init(red: 0.551, green:0.551, blue:0.551, alpha:1),
            NSFontAttributeName : NSFont(name: "Lato-Light", size: 18)!])
    }
    
    /* Set the timer label to the user preferred pomodoro duration, stop the current timer, hide reset button, 
     set start button to play and reset timeLeftShapeLayer */
    func reset() {
        let pomodoroDefaultDuration = defaults.integerForKey("pomodoroDuration")
        timeLabel.stringValue = String(format: "%d:%02d", pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
        if(showTimeInBar) {
            buttonBar.title = timeLabel.stringValue
        }
        resetButton.hidden = true
        startButton.image = NSImage(named: "play-2")
        currentTask.editable = true
        resetLayer(timeLeftShapeLayer)
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(sender: NSButton) {
        resetButton.hidden = false
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            pauseLayer(timeLeftShapeLayer)
            pauseLayer(targetShapeLayer)
            updateStatusTimer.invalidate()
            startButton.image = NSImage(named: "play-2")
        } else {
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            startButton.image = NSImage(named: "pause-2")
            isActive = true
            if(timer.unPause()) {
                resumeLayer(timeLeftShapeLayer)
            } else {
                restartLayer(timeLeftShapeLayer)
            }
            if(isPomodoro) {
                resumeLayer(targetShapeLayer)
            }
        }
    }

    /* Stop the current timer and reset all the values */
    @IBAction func resetTimer(sender: AnyObject) {
        timer.resetTimer()
        isActive = false
        isPomodoro = true
        timeLabel.textColor = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1)
        updateStatusTimer.invalidate()
        reset()
        pauseLayer(timeLeftShapeLayer)
        addTimeLeftAnimation()
    }
    
    /* Add a new animation for the time left. Remove previous animation before add the new one. */
    func addTimeLeftAnimation() {
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
    
    /* Start a new timer and restart the animation */
    func startTimer() {
        restartLayer(timeLeftShapeLayer)
        //resetLastPomodoro()

        if(isPomodoro) {
            resumeLayer(targetShapeLayer)
            timeLabel.textColor = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1)
            timer.startPomodoroTimer()
        } else {
            timeLabel.textColor = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:1)
            timer.startBreakTimer()
        }
        addTimeLeftAnimation()
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.valid) {
            timeLabel.stringValue = String(format: "%d:%02d", timer.timeLeft/60, timer.timeLeft%60)
            if(showTimeInBar) {
                buttonBar.title = timeLabel.stringValue
            }
        } else {
            if(reloadPreferencesOnNextPomodoro) {
                reloadPreferences()
            }
            
            pauseLayer(targetShapeLayer)

            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey("targetPomodoros")!

            if(timer.finishedPomodoros >= defaults.integerForKey("targetPomodoros")) {
                isPomodoro = true
                let userWantToStartOver = dialogOKCancel("Target achieved!",
                                                    text: "Do you want to start over?",
                                                    b1Text: "Yes",
                                                    b2Text: "Cancel")
                if(userWantToStartOver) {
                    startTimer()     // start pomodoro
                } else {
                    resetTimer(self)
                }
                timer.finishedPomodoros = 0
            } else if(timer.isPomodoro) {
                let userAceptBreak = dialogOKCancel("Pomodoro completed!",
                                                    text: "Do you want to start the break?",
                                                    b1Text: "Ok",
                                                    b2Text: "New Pomodoro")
                if(userAceptBreak) {
                    isPomodoro = false
                    startTimer()     // start break
                } else {
                    isPomodoro = true
                    startTimer()  // start pomodoro
                }
            } else {
                let userStartNewPomodoro = dialogOKCancel("Break finished!",
                                                          text: "Do you want to start a new pomodoro?",
                                                          b1Text: "New Pomodoro",
                                                          b2Text: "Cancel")
                if(userStartNewPomodoro) {
                    isPomodoro = true
                    startTimer()  // start pomodoro
                } else {
                    // stop timer and wait for user action
                    isPomodoro = true
                    resetTimer(self)
                }
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey("targetPomodoros")!
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
        if(!isActive) {
            reloadPreferences()
        } else {
            reloadPreferencesOnNextPomodoro = true
        }
    }
    
    /* Reload the preferred user preferences and override the current settings */
    func reloadPreferences() {
        reloadPreferencesOnNextPomodoro = false
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
    
    /* Save the current text and lose focus on the NSTextFiel */
    @IBAction func enterTask(sender: NSTextField) {
        sender.resignFirstResponder()
        sender.selectable = false
        if(!sender.stringValue.isEmpty) {
            removeTaskButton.hidden = false
        } else {
            currentTask.editable = true
        }
    }
    
    /* Focus on the NSTextFiel and clear the text */
    @IBAction func removeTask(sender: NSButton) {
        currentTask.stringValue = ""
        currentTask.editable = true
        currentTask.becomeFirstResponder()
        sender.hidden = true
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                                                                  //
    //  This part of the code is based on this stackoverflow answer:                                    //
    //  http://stackoverflow.com/questions/30289173/problems-animating-a-countdown-in-swift-sprite-kit  //
    //                                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
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
    
    func resetLastPomodoro() {
        let pausedTime = targetShapeLayer.timeOffset
        targetShapeLayer.speed = 1.0;
        targetShapeLayer.timeOffset = 0.0;
        targetShapeLayer.beginTime = 0.0;
        let timeSincePause : CFTimeInterval = targetShapeLayer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        targetShapeLayer.beginTime = timeSincePause - (timeSincePause - (timeSincePause%defaults.doubleForKey("pomodoroDuration")))
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


