//
//  PomodoroViewController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class PomodoroViewController: NSViewController, PreferencesDelegate, NSUserNotificationCenterDelegate {
    
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
    var notificationsHandler: NotificationsHandler!
    
    var updateStatusTimer: NSTimer = NSTimer()
    
    let timeLeftShapeLayer = CAShapeLayer()
    let bgTimeLeftShapeLayer = CAShapeLayer()
    var strokeTimeIt = CABasicAnimation(keyPath: "strokeEnd")
    
    let targetShapeLayer = CAShapeLayer()
    let bgTargetShapeLayer = CAShapeLayer()
    let strokeTargetIt = CABasicAnimation(keyPath: "strokeEnd")
    
    var caller: Caller = Caller.BREAK
    var actionButtonPressed: Bool = false
    
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
        
        notificationsHandler = NotificationsHandler()
        
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
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }
    
    /* Detect if the user interact with the notification */
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if(notification.activationType == NSUserNotificationActivationType.ActionButtonClicked) {
            self.handleNotifications(notification, isActionButton: true)
        }
    }
    
    /* Show always the notification, even if the app is open */
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    /* Detect dismissed notification -> in this app that is considered as press the other button */
    func userNotificationCenter(center: NSUserNotificationCenter, didDeliverNotification notification: NSUserNotification) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            var notificationStillPresent = true
            while (notificationStillPresent) {
                NSThread.sleepForTimeInterval(1)
                notificationStillPresent = false
                for deliveredNotification in NSUserNotificationCenter.defaultUserNotificationCenter().deliveredNotifications {
                    if deliveredNotification.identifier == notification.identifier {
                        notificationStillPresent = true
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.handleNotifications(notification, isActionButton: false)
            }
        }
    }
    
    /* Show a new notification on the Notification Center */
    func showNotification(title: String, text: String, actionTitle: String, otherTitle: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.actionButtonTitle = actionTitle
        notification.otherButtonTitle = otherTitle
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    func handleNotifications(notification: NSUserNotification, isActionButton: Bool) {
        if(isActionButton) {
            actionButtonPressed = true
            handleNotificationAction()
        } else if(!actionButtonPressed) {
            actionButtonPressed = false
            handleNotificationOther()
        } else {
            actionButtonPressed = false
        }
    }
    
    func handleNotificationAction() {
        if(caller == Caller.TARGET) {
            startTimer()
        } else if(caller == Caller.POMODORO) {
            isPomodoro = false
            startTimer()
        } else if(caller == Caller.BREAK) {
            isPomodoro = true
            startTimer()
        }
    }
    
    func handleNotificationOther() {
        if(caller == Caller.TARGET) {
            resetTimer(self)
        } else if(caller == Caller.POMODORO) {
            isPomodoro = true
            startTimer()  // start pomodoro
        } else if(caller == Caller.BREAK) {
            // stop timer and wait for user action
            isPomodoro = true
            resetTimer(self)
        }
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
            if(!updateStatusTimer.valid) {
                updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            }
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
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
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
        if(!updateStatusTimer.valid) {
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
        }
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
            updateStatusTimer.invalidate()
            
            if(reloadPreferencesOnNextPomodoro) {
                reloadPreferences()
            }
            
            pauseLayer(targetShapeLayer)
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey("targetPomodoros")!
            
            if(timer.finishedPomodoros >= defaults.integerForKey("targetPomodoros")) {
                isPomodoro = true
                caller = Caller.TARGET
                showNotification("Target achieved!",
                                 text: "Do you want to start over?",
                                 actionTitle: "Yes",
                                 otherTitle: "Cancel")
                timer.finishedPomodoros = 0
            } else if(timer.isPomodoro) {
                caller = Caller.POMODORO
                showNotification("Pomodoro completed!",
                                 text: "Do you want to start the break?",
                                 actionTitle: "Ok",
                                 otherTitle: "New Pomodoro")
            } else {
                caller = Caller.BREAK
                showNotification("Break finished!",
                                 text: "Do you want to start a new pomodoro?",
                                 actionTitle: "New Pomodoro", otherTitle: "Cancel")
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey("targetPomodoros")!
        }
    }
    
    /* Open a contextual menu with the possible actions: settings, about and quit */
    @IBAction func openSettingsMenu(sender: NSButton) {
        let menu = NSMenu()
        
        menu.insertItemWithTitle("Reset Full Pomodoros", action: #selector(PomodoroViewController.resetFullPomodoros),
                                 keyEquivalent: "", atIndex: 0)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 1)
        menu.insertItemWithTitle("Settings", action: #selector(PomodoroViewController.openPreferences),
                                 keyEquivalent: "", atIndex: 2)
        menu.insertItemWithTitle("About", action: #selector(PomodoroViewController.openAbout),
                                 keyEquivalent: "", atIndex: 3)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 4)
        menu.insertItemWithTitle("Quit", action: #selector(PomodoroViewController.quitApp),
                                 keyEquivalent: "", atIndex: 5)
        
        NSMenu.popUpContextMenu(menu, withEvent: NSApplication.sharedApplication().currentEvent!, forView: sender as NSButton)
    }
    
    /* Set to 0 the current full pomodoros completed */
    func resetFullPomodoros() {
        resetLayer(targetShapeLayer)
        timer.finishedPomodoros = 0
        fullPomodoros.stringValue = "0/" + defaults.stringForKey("targetPomodoros")!
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
        timer.timeLeft = timer.pomodoroDuration
        resetTimer(self)
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


