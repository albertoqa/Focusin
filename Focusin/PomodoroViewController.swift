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
    var popoverView: NSPopover
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var fullPomodoros: NSTextField!
    @IBOutlet weak var currentTask: NSTextField!
    @IBOutlet weak var removeTaskButton: NSButton!
    
    @IBOutlet weak var shortBreak: NSButton!
    @IBOutlet weak var longBreak: NSButton!
    @IBOutlet weak var backgroundButtons: NSTextField!
    
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
    
    let iconPlayOrange = "play-2"
    let iconPauseOrange = "pause-2"
    let iconPlayGreen = "play-3"
    let iconPauseGreen = "pause-3"
    let sofa = "sofa"
    let sofaFill = "sofa_filled"
    
    init(nibName: String, bundle: NSBundle?, button: NSStatusBarButton, popover: NSPopover) {
        self.buttonBar = button
        self.popoverView = popover
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
        
        circleAnimations = CircleAnimation(popoverRootView: mainView, startButton: startButton, fullPomodoros: fullPomodoros, shortBreak: shortBreak, longBreak: longBreak)
        
        timer = Timer(defaults.integerForKey(Defaults.pomodoroKey), defaults.integerForKey(Defaults.breakKey))
        showTimeInBar = defaults.integerForKey(Defaults.showTimeKey) == NSOnState
        showNotifications = defaults.integerForKey(Defaults.showNotificationsKey) == NSOnState
        resetForPomodoro()
    
        resetButton.hidden = true
        removeTaskButton.hidden = true
        fullPomodoros.stringValue = zeroPomodoros + defaults.stringForKey(Defaults.targetKey)!
        
        currentTask.placeholderAttributedString = NSAttributedString(string: currentTaskLabel, attributes: [NSForegroundColorAttributeName: gray, NSFontAttributeName : NSFont(name: font, size: currentTaskSize)!])
        
    }
    
    /* Reset the view elements and get them ready for a new pomodoro */
    func resetForPomodoro() {
        let pomodoroDefaultDuration = defaults.integerForKey(Defaults.pomodoroKey)
        timeLabel.stringValue = String(format: timeFormat, pomodoroDefaultDuration/seconds, pomodoroDefaultDuration%seconds)
        timeLabel.textColor = orange
        circleAnimations.setTimeLayerColor(true)
        startButton.image = NSImage(named: iconPlayOrange)
        shortBreak.image = NSImage(named: sofa)
        reset()
    }
    
    /* Reset the view elements and get them ready for a break */
    func resetForBreak() {
        let breakDefaultDuration = defaults.integerForKey(Defaults.breakKey)
        timeLabel.stringValue = String(format: timeFormat, breakDefaultDuration/seconds, breakDefaultDuration%seconds)
        timeLabel.textColor = green
        circleAnimations.setTimeLayerColor(false)
        startButton.image = NSImage(named: iconPlayGreen)
        shortBreak.image = NSImage(named: sofa)
        reset()
    }
    
    /* Common elements of the reset */
    func reset() {
        buttonBar.title = showTimeInBar ? timeLabel.stringValue : ""
        resetButton.hidden = true
    }
    
    /* Start a break */
    @IBAction func startBreak(sender: AnyObject) {
        if(!(!isPomodoro && isActive)) {
            isPomodoro = false
            resetTimerForBreak()
            startTimer()
        }
    }
    
    /* Show the todo list of tasks */
    @IBAction func showToDoList(sender: AnyObject) {
    }
    
    
    /* Stop the current timer and reset all the values. */
    @IBAction func resetTimer(sender: AnyObject) {
        notificationsHandler.removeAllNotifications()
        
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
        isActive = false
        isPomodoro = true
        timer.resetTimer(isPomodoro)
        updateStatusTimer.invalidate()
        resetForPomodoro()
        
        circleAnimations.resetLayer(Circles.TIME)
        circleAnimations.pauseLayer(Circles.TIME)
        circleAnimations.addTimeLeftAnimation(isPomodoro)
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(sender: AnyObject) {
        notificationsHandler.removeAllNotifications()

        resetButton.hidden = false
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            circleAnimations.pauseLayer(Circles.TIME)
            circleAnimations.pauseLayer(Circles.TARGET)
            updateStatusTimer.invalidate()
            if(isPomodoro) {
                startButton.image = NSImage(named: iconPlayOrange)
            } else {
                startButton.image = NSImage(named: iconPlayGreen)
            }
        } else {
            if(!updateStatusTimer.valid) {
                updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            }
            if(isPomodoro) {
                startButton.image = NSImage(named: iconPauseOrange)
            } else {
                startButton.image = NSImage(named: iconPauseGreen)
                shortBreak.image = NSImage(named: sofaFill)
            }
            isActive = true
            if(timer.unPause(isPomodoro)) {
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
        startPauseTimer(self)
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
                resetTimer(self)
                if(showNotifications) {
                    notificationsHandler.showNotification("Target achieved!",
                                 text: "Do you want to start over?",
                                 actionTitle: "Yes",
                                 otherTitle: "Cancel")
                }
                timer.finishedPomodoros = 0
            } else if(timer.isPomodoro) {
                notificationsHandler.caller = Caller.POMODORO
                isPomodoro = false
                resetTimerForBreak()
                
                if(showNotifications) {
                    notificationsHandler.showNotification("Pomodoro completed!",
                                 text: "Do you want to start the break?",
                                 actionTitle: "Ok",
                                 otherTitle: "Cancel") // TODO this is supposed to be a "New Pomodoro" 
                }
            } else {
                notificationsHandler.caller = Caller.BREAK
                isPomodoro = true
                resetTimer(self)
                if(showNotifications) {
                    notificationsHandler.showNotification("Break finished!",
                                 text: "Do you want to start a new pomodoro?",
                                 actionTitle: "New Pomodoro", otherTitle: "Cancel")
                }
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + defaults.stringForKey(Defaults.targetKey)!
        }
    }
    
    /* Set the timer and the animation ready for start a bread */
    func resetTimerForBreak() {
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
        timer.resetTimer(isPomodoro)
        isActive = false
        updateStatusTimer.invalidate()
        resetForBreak()
        
        circleAnimations.resetLayer(Circles.TIME)
        circleAnimations.pauseLayer(Circles.TIME)
        circleAnimations.addTimeLeftAnimation(isPomodoro)
    }
    
    /* Handle the action to perform when the user interact with a notification using the action button */
    func handleNotificationAction(caller: Caller) {
        if(caller == Caller.TARGET) {
            startTimer()
        } else if(caller == Caller.POMODORO) {
            isPomodoro = false
            startTimer()
        } else if(caller == Caller.BREAK) {
            startTimer()
        }
    }
    
    /* Handle the action to perform when the user interact with a notification using the other (close) button */
    func handleNotificationOther(caller: Caller) {
        if(caller == Caller.POMODORO) {
            isPomodoro = true
            //resetTimer(self)
            startTimer()  // start pomodoro
        }
    }
    
    /* Handle the notification action: open the popover view of the app */
    func handleNotificationOpenApp() {
        NSApp.activateIgnoringOtherApps(true)
        popoverView.showRelativeToRect(buttonBar.bounds, ofView: buttonBar, preferredEdge: NSRectEdge.MinY)
    }
    
    /* Open a contextual menu with the possible actions: settings, about and quit */
    @IBAction func openSettingsMenu(sender: NSButton) {
        notificationsHandler.removeAllNotifications()

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
        notificationsHandler.removeAllNotifications()
        NSApplication.sharedApplication().terminate(self)
    }
    
    /* Save the current text and lose focus on the NSTextFiel */
    @IBAction func enterTask(sender: NSTextField) {
        notificationsHandler.removeAllNotifications()

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
        notificationsHandler.removeAllNotifications()

        currentTask.stringValue = ""
        currentTask.editable = true
        currentTask.becomeFirstResponder()
        sender.hidden = true
    }

}



