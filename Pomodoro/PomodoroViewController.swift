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

    let defaults = NSUserDefaults.standardUserDefaults()
    var timer: Timer!
    var isActive: Bool = false

    var preferencesWindow: PreferencesWindowController!
    var aboutWindow: AboutWindowController!
    
    var updateStatusTimer: NSTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferencesWindow = PreferencesWindowController()
        aboutWindow = AboutWindowController()
        preferencesWindow.delegate = self
        
        timer = Timer(defaults.integerForKey("pomodoroDuration"), defaults.integerForKey("breakDuration"))
        
        resetTimeLabel()
    }
    
    /* Set the timer label to the user preferred pomodoro duration */
    func resetTimeLabel() {
        let pomodoroDefaultDuration = defaults.integerForKey("pomodoroDuration")
        timeLabel.stringValue = String(format: "%d:%02d", pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
    }
    
    /* Start the timer (if paused or stoped) or pause the timer (if active) */
    @IBAction func startPauseTimer(sender: NSButton) {
        if(isActive) {
            isActive = false
            timer.pauseTimer()
            updateStatusTimer.invalidate()
        } else {
            isActive = true
            timer.unPause()
            updateStatusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updateCurrentStatus), userInfo: nil, repeats: true)
        }
    }

    /* Stop the current timer and reset all the values */
    @IBAction func resetTimer(sender: AnyObject) {
        timer.resetTimer()
        isActive = false
        updateStatusTimer.invalidate()
        resetTimeLabel()
    }
    
    /* Update the current state of the application. Warn the user when the pomodoro or break finish and ask for the next action*/
    func updateCurrentStatus() {
        if(timer.timeLeft >= 0 && timer.timer.valid) {
            timeLabel.stringValue = String(format: "%d:%02d", timer.timeLeft/60, timer.timeLeft%60)
        } else {
            if(timer.isPomodoro) {
                let userAceptBreak = dialogOKCancel("Pomodoro completed!",
                                                    text: "Do you want to start the break?",
                                                    b1Text: "Ok",
                                                    b2Text: "New Pomodoro")
                if(userAceptBreak) {
                    timer.startBreakTimer()     // start break
                } else {
                    timer.startPomodoroTimer()  // start pomodoro
                }
            } else {
                let userStartNewPomodoro = dialogOKCancel("Break finished!",
                                                          text: "Do you want to start a new pomodoro?",
                                                          b1Text: "New Pomodoro",
                                                          b2Text: "Cancel")
                if(userStartNewPomodoro) {
                    timer.startPomodoroTimer()  // start pomodoro
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
    
}

