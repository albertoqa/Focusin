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
    var tasksView: NSPopover = NSPopover()
    
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
    
    let defaults = UserDefaults.standard
    var timer: Timer!
    var isActive: Bool = false
    var isPomodoro: Bool = true
    var reloadPreferencesOnNextPomodoro = false
    var showTimeInBar: Bool = true
    var showNotifications: Bool = true
    
    var targetPomodoros: Int = 0
    var longBreakAfterXPomodoros: Int = 0
    
    var preferencesWindow: PreferencesWindowController!
    var aboutWindow: AboutWindowController!
    var notificationsHandler: NotificationsHandler!
    
    var updateStatusTimer: Foundation.Timer = Foundation.Timer()
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
    
    init(nibName: String, bundle: Bundle?, button: NSStatusBarButton, popover: NSPopover) {
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
        
        timer = Timer(defaults.integer(forKey: Defaults.pomodoroKey), defaults.integer(forKey: Defaults.shortBreakKey), defaults.integer(forKey: Defaults.longBreakKey))
        showTimeInBar = defaults.integer(forKey: Defaults.showTimeKey) == NSOnState
        showNotifications = defaults.integer(forKey: Defaults.showNotificationsKey) == NSOnState
        targetPomodoros = defaults.integer(forKey: Defaults.targetKey)
        longBreakAfterXPomodoros = defaults.integer(forKey: Defaults.longBreakAfterXPomodoros)
        resetForPomodoro()
    
        resetButton.isHidden = true
        removeTaskButton.isHidden = true
        fullPomodoros.stringValue = zeroPomodoros + defaults.string(forKey: Defaults.targetKey)!
        
        tasksView.contentViewController = TasksViewController(nibName: "TasksViewController", bundle: nil, popover: popoverView, pomodoroView: self)
        tasksView.behavior = NSPopoverBehavior.transient
    }
    
    /* Reset the view elements and get them ready for a new pomodoro */
    func resetForPomodoro() {
        let pomodoroDefaultDuration = defaults.integer(forKey: Defaults.pomodoroKey)
        timeLabel.stringValue = String(format: timeFormat, pomodoroDefaultDuration/seconds, pomodoroDefaultDuration%seconds)
        timeLabel.textColor = orange
        circleAnimations.setTimeLayerColor(true)
        startButton.image = NSImage(named: iconPlayOrange)
        shortBreak.image = NSImage(named: sofa)
        reset()
    }
    
    /* Reset the view elements and get them ready for a break */
    func resetForBreak() {
        let breakDefaultDuration: Int
        if(isLongBreak()) {
            breakDefaultDuration = defaults.integer(forKey: Defaults.longBreakKey)
        } else {
            breakDefaultDuration = defaults.integer(forKey: Defaults.shortBreakKey)
        }
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
        resetButton.isHidden = true
    }
    
    /* Start a break */
    @IBAction func startBreak(_ sender: AnyObject) {
        if(!(!isPomodoro && isActive)) {
            isPomodoro = false
            resetTimerForBreak()
            startTimer()
        }
    }
    
    /* Show the todo list of tasks */
    @IBAction func showToDoList(_ sender: AnyObject) {
        tasksView.show(relativeTo: longBreak.bounds, of: longBreak, preferredEdge: NSRectEdge.minY)
    }
    
    /* Stop the current timer and reset all the values. */
    @IBAction func resetTimer(_ sender: AnyObject) {
        notificationsHandler.removeAllNotifications()
        
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
        if(timer.finishedPomodoros >= targetPomodoros) {
            timer.finishedPomodoros = 0
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + String(targetPomodoros)
        }
        
        isActive = false
        isPomodoro = true
        timer.resetTimer(isPomodoro, isLongBreak: isLongBreak())
        updateStatusTimer.invalidate()
        resetForPomodoro()
        
        circleAnimations.resetLayer(Circles.time)
        circleAnimations.pauseLayer(Circles.time)
        circleAnimations.addTimeLeftAnimation(isPomodoro, isLongBreak: isLongBreak())
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(_ sender: AnyObject) {
        notificationsHandler.removeAllNotifications()

        resetButton.isHidden = false
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            circleAnimations.pauseLayer(Circles.time)
            circleAnimations.pauseLayer(Circles.target)
            updateStatusTimer.invalidate()
            if(isPomodoro) {
                startButton.image = NSImage(named: iconPlayOrange)
            } else {
                startButton.image = NSImage(named: iconPlayGreen)
            }
        } else {
            if(!updateStatusTimer.isValid) {
                updateStatusTimer = Foundation.Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
            }
            if(isPomodoro) {
                startButton.image = NSImage(named: iconPauseOrange)
            } else {
                startButton.image = NSImage(named: iconPauseGreen)
                shortBreak.image = NSImage(named: sofaFill)
            }
            isActive = true
            if(timer.unPause(isPomodoro, isLongBreak: isLongBreak())) {
                circleAnimations.resumeLayer(Circles.time)
            } else {
                circleAnimations.restartLayer(Circles.time)
            }
            if(isPomodoro) {
                circleAnimations.resumeLayer(Circles.target)
            }
        }
    }
    
    /* Check if the break is short or long */
    func isLongBreak() -> Bool {
        return timer.finishedPomodoros % longBreakAfterXPomodoros == 0
    }
    
    /* Start a new timer and restart the animation */
    func startTimer() {
        startPauseTimer(self)
        circleAnimations.addTimeLeftAnimation(isPomodoro, isLongBreak: isLongBreak())
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.isValid) {
            timeLabel.stringValue = String(format: timeFormat, timer.timeLeft/seconds, timer.timeLeft%seconds)
            if(showTimeInBar) {
                buttonBar.title = timeLabel.stringValue
            }
        } else {
            updateStatusTimer.invalidate()
            
            if(reloadPreferencesOnNextPomodoro) {
                reloadPreferences()
            }
            
            circleAnimations.pauseLayer(Circles.target)
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + String(targetPomodoros)
            
            if(timer.finishedPomodoros == targetPomodoros && isPomodoro) {
                isPomodoro = false
                notificationsHandler.caller = Caller.target
                resetTimerForBreak()

                if(showNotifications) {
                    notificationsHandler.showNotification("Target achieved!",
                                 text: "Do you want to start the long break?",
                                 actionTitle: "Yes",
                                 otherTitle: "Cancel")
                }
            } else if(timer.isPomodoro) {
                notificationsHandler.caller = Caller.pomodoro
                isPomodoro = false
                resetTimerForBreak()
                
                if(showNotifications) {
                    notificationsHandler.showNotification("Pomodoro completed!",
                                 text: "Do you want to start the break?",
                                 actionTitle: "Ok",
                                 otherTitle: "Cancel") // TODO this is supposed to be a "New Pomodoro" 
                }
            } else {
                notificationsHandler.caller = Caller.break
                isPomodoro = true
                resetTimer(self)
                if(showNotifications) {
                    notificationsHandler.showNotification("Break finished!",
                                 text: "Do you want to start a new pomodoro?",
                                 actionTitle: "New Pomodoro", otherTitle: "Cancel")
                }
                if(timer.finishedPomodoros >= targetPomodoros) {
                    timer.finishedPomodoros = 0
                }
            }
            
            fullPomodoros.stringValue = String(timer.finishedPomodoros) + slash + String(targetPomodoros)
        }
    }
    
    /* Set the timer and the animation ready for start a bread */
    func resetTimerForBreak() {
        if(reloadPreferencesOnNextPomodoro) {
            reloadPreferences()
        }
        
        timer.resetTimer(isPomodoro, isLongBreak: isLongBreak())
        isActive = false
        updateStatusTimer.invalidate()
        resetForBreak()
        
        circleAnimations.resetLayer(Circles.time)
        circleAnimations.pauseLayer(Circles.time)
        circleAnimations.addTimeLeftAnimation(isPomodoro, isLongBreak: isLongBreak())
    }
    
    /* Handle the action to perform when the user interact with a notification using the action button */
    func handleNotificationAction(_ caller: Caller) {
        if(caller == Caller.target) {
            startTimer()
        } else if(caller == Caller.pomodoro) {
            isPomodoro = false
            startTimer()
        } else if(caller == Caller.break) {
            startTimer()
        }
    }
    
    /* Handle the action to perform when the user interact with a notification using the other (close) button */
    func handleNotificationOther(_ caller: Caller) {
        if(caller == Caller.pomodoro) {
            isPomodoro = true
            //resetTimer(self)
            startTimer()  // start pomodoro
        }
    }
    
    /* Handle the notification action: open the popover view of the app */
    func handleNotificationOpenApp() {
        NSApp.activate(ignoringOtherApps: true)
        popoverView.show(relativeTo: buttonBar.bounds, of: buttonBar, preferredEdge: NSRectEdge.minY)
    }
    
    /* Open a contextual menu with the possible actions: settings, about and quit */
    @IBAction func openSettingsMenu(_ sender: NSButton) {
        notificationsHandler.removeAllNotifications()

        let menu = NSMenu()

        menu.insertItem(withTitle: "Reset Full Pomodoros", action: #selector(PomodoroViewController.resetFullPomodoros),
                                 keyEquivalent: "", at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
        menu.insertItem(withTitle: "Settings", action: #selector(PomodoroViewController.openPreferences),
                                 keyEquivalent: "", at: 2)
        menu.insertItem(withTitle: "About", action: #selector(PomodoroViewController.openAbout),
                                 keyEquivalent: "", at: 3)
        menu.insertItem(NSMenuItem.separator(), at: 4)
        menu.insertItem(withTitle: "Quit", action: #selector(PomodoroViewController.quitApp),
                                 keyEquivalent: "", at: 5)

        // TODO this blocks the timer!! Errorrrrrr
        NSMenu.popUpContextMenu(menu, with: NSApplication.shared().currentEvent!, for: sender as NSButton)
    }
    
    /* Set to 0 the current full pomodoros completed */
    func resetFullPomodoros() {
        circleAnimations.resetLayer(Circles.target)
        timer.finishedPomodoros = 0
        fullPomodoros.stringValue = zeroPomodoros + String(targetPomodoros)
    }
    
    /* Open a new window with the preferences of the application */
    func openPreferences() {
        preferencesWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /* Called when the default preferences are updated */
    func preferencesDidUpdate() {
        if(!isActive) {
            reloadPreferences()
        } else {
            self.showTimeInBar = defaults.integer(forKey: Defaults.showTimeKey) == NSOnState
            if(!self.showTimeInBar) {
                buttonBar.title = ""
            }
            self.showNotifications = defaults.integer(forKey: Defaults.showNotificationsKey) == NSOnState
            reloadPreferencesOnNextPomodoro = true
        }
    }
    
    /* Reload the preferred user preferences and override the current settings */
    func reloadPreferences() {
        reloadPreferencesOnNextPomodoro = false
        timer.pomodoroDuration = defaults.integer(forKey: Defaults.pomodoroKey)
        timer.shortBreakDuration = defaults.integer(forKey: Defaults.shortBreakKey)
        timer.longBreakDuration = defaults.integer(forKey: Defaults.longBreakKey)
        timer.timeLeft = timer.pomodoroDuration
        targetPomodoros = defaults.integer(forKey: Defaults.targetKey)
        self.showTimeInBar = defaults.integer(forKey: Defaults.showTimeKey) == NSOnState
        self.showNotifications = defaults.integer(forKey: Defaults.showNotificationsKey) == NSOnState
        resetTimer(self)
    }
    
    /* Open a new window with information about the application */
    func openAbout() {
        aboutWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /* Close the application */
    func quitApp() {
        notificationsHandler.removeAllNotifications()
        NSApplication.shared().terminate(self)
    }
    
    /* Save the current text and lose focus on the NSTextFiel */
    @IBAction func enterTask(_ sender: NSTextField) {
        notificationsHandler.removeAllNotifications()

        sender.resignFirstResponder()
        sender.isSelectable = false
        if(!sender.stringValue.isEmpty) {
            removeTaskButton.isHidden = false
        } else {
            currentTask.isEditable = true
        }
    }
    
    /* Focus on the NSTextFiel and clear the text */
    @IBAction func removeTask(_ sender: NSButton) {
        notificationsHandler.removeAllNotifications()

        currentTask.stringValue = ""
        currentTask.isEditable = true
        currentTask.becomeFirstResponder()
        sender.isHidden = true
    }

}



