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
    var showNotifications: Bool = true
    
    var preferencesWindow: PreferencesWindowController!
    var aboutWindow: AboutWindowController!
    var notificationsHandler: NotificationsHandler!
    
    var updateStatusTimer: NSTimer = NSTimer()
    var circleAnimations: CircleAnimation!
    
    let timeFormat = "%d:%02d"
    let zeroPomodoros = "0/"
    let slash = "/"
    let currentTaskLabel = "What are you working on?"
    let currentTaskSize: CGFloat = 18
    let font = "Lato-Light"
    let seconds = 60
    
    let orange = NSColor.init(red: 0.929, green:0.416, blue:0.353, alpha:1)
    let green = NSColor.init(red: 0.608, green:0.757, blue:0.737, alpha:1)
    let gray = NSColor.init(red: 0.551, green:0.551, blue:0.551, alpha:1)
    
    let iconPlay = "play-2"
    let iconPause = "pause-2"
    
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
        showNotifications = defaults.integerForKey(Defaults.showNotificationsKey) == NSOnState
        reset()
    
        resetButton.hidden = true
        removeTaskButton.hidden = true
        fullPomodoros.stringValue = zeroPomodoros + defaults.stringForKey(Defaults.targetKey)!
        
        currentTask.placeholderAttributedString = NSAttributedString(string: currentTaskLabel, attributes: [NSForegroundColorAttributeName: gray, NSFontAttributeName : NSFont(name: font, size: currentTaskSize)!])
    }
    
    /* Set the timer label to the user preferred pomodoro duration, stop the current timer, hide reset button,
     set start button to play. Reset the elements of the view */
    func reset() {
        let pomodoroDefaultDuration = defaults.integerForKey(Defaults.pomodoroKey)
        timeLabel.stringValue = String(format: timeFormat, pomodoroDefaultDuration/seconds, pomodoroDefaultDuration%seconds)
        timeLabel.textColor = orange
        buttonBar.title = showTimeInBar ? timeLabel.stringValue : ""
        resetButton.hidden = true
        startButton.image = NSImage(named: iconPlay)
    }
    
    /* Stop the current timer and reset all the values. */
    @IBAction func resetTimer(sender: AnyObject) {
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
        timer.resetTimer()
        isActive = false
        isPomodoro = true
        updateStatusTimer.invalidate()
        reset()
        
        circleAnimations.resetLayer(Circles.TIME)
        circleAnimations.pauseLayer(Circles.TIME)
        circleAnimations.addTimeLeftAnimation(isPomodoro)
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
            startButton.image = NSImage(named: iconPlay)
        } else {
            if(!updateStatusTimer.valid) {
                updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            }
            startButton.image = NSImage(named: iconPause)
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
    
    /* Start a new timer and restart the animation */
    func startTimer() {
        if(!updateStatusTimer.valid) {
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
        }
        circleAnimations.restartLayer(Circles.TIME)
        //resetLastPomodoro()
        
        if(isPomodoro) {
            circleAnimations.resumeLayer(Circles.TARGET)
            timeLabel.textColor = orange
            timer.startPomodoroTimer()
        } else {
            timeLabel.textColor = green
            timer.startBreakTimer()
        }
        circleAnimations.addTimeLeftAnimation(isPomodoro)
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.valid) {
            timeLabel.stringValue = String(format: timeFormat, timer.timeLeft/seconds, timer.timeLeft%seconds)
            if(showTimeInBar) {
                buttonBar.title = timeLabel.stringValue
            }
        } else {
            updateStatusTimer.invalidate()
            
            if(reloadPreferencesOnNextPomodoro) {
                reloadPreferences()
            }
            
            circleAnimations.pauseLayer(Circles.TARGET)
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + defaults.stringForKey(Defaults.targetKey)!
            
            if(timer.finishedPomodoros >= defaults.integerForKey(Defaults.targetKey)) {
                isPomodoro = true
                notificationsHandler.caller = Caller.TARGET
                if(showNotifications) {
                    notificationsHandler.showNotification("Target achieved!",
                                 text: "Do you want to start over?",
                                 actionTitle: "Yes",
                                 otherTitle: "Cancel")
                }
                timer.finishedPomodoros = 0
            } else if(timer.isPomodoro) {
                notificationsHandler.caller = Caller.POMODORO
                if(showNotifications) {
                    notificationsHandler.showNotification("Pomodoro completed!",
                                 text: "Do you want to start the break?",
                                 actionTitle: "Ok",
                                 otherTitle: "New Pomodoro")
                }
            } else {
                notificationsHandler.caller = Caller.BREAK
                if(showNotifications) {
                    notificationsHandler.showNotification("Break finished!",
                                 text: "Do you want to start a new pomodoro?",
                                 actionTitle: "New Pomodoro", otherTitle: "Cancel")
                }
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + defaults.stringForKey(Defaults.targetKey)!
        }
    }
    
    /* Handle the action to perform when the user interact with a notification using the action button */
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
    
    /* Handle the action to perform when the user interact with a notification using the other (close) button */
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

        // TODO this blocks the timer!! Errorrrrrr
        NSMenu.popUpContextMenu(menu, withEvent: NSApplication.sharedApplication().currentEvent!, forView: sender as NSButton)
    }
    
    /* Set to 0 the current full pomodoros completed */
    func resetFullPomodoros() {
        circleAnimations.resetLayer(Circles.TARGET)
        timer.finishedPomodoros = 0
        fullPomodoros.stringValue = zeroPomodoros + defaults.stringForKey(Defaults.targetKey)!
    }
    
    /* Open a new window with the preferences of the application */
    func openPreferences() {
        preferencesWindow.showWindow(nil)
        NSApp.activateIgnoringOtherApps(true)
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
        self.showTimeInBar = defaults.integerForKey(Defaults.showTimeKey) == NSOnState
        self.showNotifications = defaults.integerForKey(Defaults.showNotificationsKey) == NSOnState
        resetTimer(self)
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



