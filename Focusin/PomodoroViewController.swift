//
//  PomodoroViewController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class PomodoroViewController: NSViewController, PreferencesDelegate, NotificationsDelegate {
    
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
    var circleAnimations: CircleAnimation!
    
    let timeFormat = "%d:%02d"
    
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
        notificationsHandler.delegate = self
        
        circleAnimations = CircleAnimation(popoverRootView: mainView, startButton: startButton, fullPomodoros: fullPomodoros)
        
        timer = Timer(defaults.integerForKey(Defaults.pomodoroKey), defaults.integerForKey(Defaults.breakKey))
        showTimeInBar = defaults.integerForKey(Defaults.showTimeKey) == NSOnState
        reset()
    
        // General configuration
        resetButton.hidden = true
        removeTaskButton.hidden = true
        fullPomodoros.stringValue = "0/" + defaults.stringForKey(Defaults.targetKey)!
        
        currentTask.placeholderAttributedString = NSAttributedString(string: "What are you working on?", attributes: [NSForegroundColorAttributeName: NSColor.init(red: 0.551, green:0.551, blue:0.551, alpha:1),
            NSFontAttributeName : NSFont(name: "Lato-Light", size: 18)!])
    }
    
    
    func handleNotificationAction(caller: Caller) {
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
    
    func handleNotificationOther(caller: Caller) {
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
        let pomodoroDefaultDuration = defaults.integerForKey(Defaults.pomodoroKey)
        timeLabel.stringValue = String(format: timeFormat, pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
        if(showTimeInBar) {
            buttonBar.title = timeLabel.stringValue
        }
        resetButton.hidden = true
        startButton.image = NSImage(named: "play-2")
        currentTask.editable = true
        circleAnimations.resetLayer(Circles.TIME)
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(sender: NSButton) {
        resetButton.hidden = false
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            circleAnimations.pauseLayer(Circles.TIME)
            circleAnimations.pauseLayer(Circles.TARGET)
            updateStatusTimer.invalidate()
            startButton.image = NSImage(named: "play-2")
        } else {
            if(!updateStatusTimer.valid) {
                updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            }
            startButton.image = NSImage(named: "pause-2")
            isActive = true
            if(timer.unPause()) {
                circleAnimations.resumeLayer(Circles.TIME)
            } else {
                circleAnimations.restartLayer(Circles.TIME)
            }
            if(isPomodoro) {
                circleAnimations.resumeLayer(Circles.TARGET)
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
        circleAnimations.pauseLayer(Circles.TIME)
        circleAnimations.addTimeLeftAnimation(isPomodoro)
    }
    
    /* Start a new timer and restart the animation */
    func startTimer() {
        if(!updateStatusTimer.valid) {
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
        }
        circleAnimations.restartLayer(Circles.TIME)
        //resetLastPomodoro()
        
        if(isPomodoro) {
            circleAnimations.resumeLayer(Circles.TARGET)
            timeLabel.textColor = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1)
            timer.startPomodoroTimer()
        } else {
            timeLabel.textColor = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:1)
            timer.startBreakTimer()
        }
        circleAnimations.addTimeLeftAnimation(isPomodoro)
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.valid) {
            timeLabel.stringValue = String(format: timeFormat, timer.timeLeft/60, timer.timeLeft%60)
            if(showTimeInBar) {
                buttonBar.title = timeLabel.stringValue
            }
        } else {
            updateStatusTimer.invalidate()
            
            if(reloadPreferencesOnNextPomodoro) {
                reloadPreferences()
            }
            
            circleAnimations.pauseLayer(Circles.TARGET)
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey(Defaults.targetKey)!
            
            if(timer.finishedPomodoros >= defaults.integerForKey(Defaults.targetKey)) {
                isPomodoro = true
                notificationsHandler.caller = Caller.TARGET
                notificationsHandler.showNotification("Target achieved!",
                                 text: "Do you want to start over?",
                                 actionTitle: "Yes",
                                 otherTitle: "Cancel")
                timer.finishedPomodoros = 0
            } else if(timer.isPomodoro) {
                notificationsHandler.caller = Caller.POMODORO
                notificationsHandler.showNotification("Pomodoro completed!",
                                 text: "Do you want to start the break?",
                                 actionTitle: "Ok",
                                 otherTitle: "New Pomodoro")
            } else {
                notificationsHandler.caller = Caller.BREAK
                notificationsHandler.showNotification("Break finished!",
                                 text: "Do you want to start a new pomodoro?",
                                 actionTitle: "New Pomodoro", otherTitle: "Cancel")
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + "/" + defaults.stringForKey(Defaults.targetKey)!
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
        circleAnimations.resetLayer(Circles.TARGET)
        timer.finishedPomodoros = 0
        fullPomodoros.stringValue = "0/" + defaults.stringForKey(Defaults.targetKey)!
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
        timer.pomodoroDuration = defaults.integerForKey(Defaults.pomodoroKey)
        timer.breakDuration = defaults.integerForKey(Defaults.breakKey)
        timer.timeLeft = timer.pomodoroDuration
        resetTimer(self)
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
}



