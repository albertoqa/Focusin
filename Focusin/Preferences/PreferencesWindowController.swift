//
//  PreferencesWindowController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa
import ServiceManagement

/* The delegate must implement the methods to take action for the new preferences */
protocol PreferencesDelegate {
    func preferencesDidUpdate()
}

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    
    var delegate: PreferencesDelegate?
    
    let defaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var pomodoroDuration: NSTextField!
    @IBOutlet weak var breakDuration: NSTextField!
    @IBOutlet weak var targetPomodoros: NSTextField!
    @IBOutlet weak var showNotifications: NSButton!
    @IBOutlet weak var showTimeInBar: NSButton!
    @IBOutlet weak var startAtLogin: NSButton!
    
    var closedWithButton: Bool = false
    let seconds: Int = 60
    
    let errorTitle = "Invalid value"
    let buttonTitle = "Ok"
    let errorPomodoro = "Pomodoro duration must be between 1 - 500"
    let errorBreak = "Break duration must be between 1 - 500"
    let errorTarget = "Target pomodoros must be between 1 - 99"
    
    let MIN_TIME = 1
    let MAX_TIME = 500
    let MIN_TARGET = 1
    let MAX_TARGET = 99
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
        
        /* Load preferred settings */
        pomodoroDuration.integerValue = defaults.integerForKey(Defaults.pomodoroKey)/seconds
        breakDuration.integerValue = defaults.integerForKey(Defaults.breakKey)/seconds
        targetPomodoros.integerValue = defaults.integerForKey(Defaults.targetKey)
        showNotifications.state = defaults.integerForKey(Defaults.showNotificationsKey)
        showTimeInBar.integerValue = defaults.integerForKey(Defaults.showTimeKey)
        startAtLogin.integerValue = defaults.integerForKey(Defaults.startAtLogin)
    }
    
    override var windowNibName : String! {
        return "PreferencesWindowController"
    }
    
    /* Save the current settings and close the window */
    @IBAction func savePreferences(sender: AnyObject) {
        closedWithButton = true
        
        if(pomodoroDuration.integerValue < MIN_TIME || pomodoroDuration.integerValue > MAX_TIME) {
            dialogError(errorPomodoro)
        } else if(breakDuration.integerValue < MIN_TIME || breakDuration.integerValue > MAX_TIME) {
            dialogError(errorBreak)
        } else if(targetPomodoros.integerValue < MIN_TARGET || targetPomodoros.integerValue > MAX_TARGET) {
            dialogError(errorTarget)
        } else {
            defaults.setValue(pomodoroDuration.integerValue * seconds, forKey: Defaults.pomodoroKey)
            defaults.setValue(breakDuration.integerValue * seconds, forKey: Defaults.breakKey)
            defaults.setValue(targetPomodoros.integerValue, forKey: Defaults.targetKey)
            defaults.setValue(showNotifications.state, forKey: Defaults.showNotificationsKey)
            defaults.setValue(showTimeInBar.state, forKey: Defaults.showTimeKey)
            defaults.setValue(startAtLogin.state, forKey: Defaults.startAtLogin)

            let launcherAppIdentifier = "com.albertoquesada.LauncherApplication"
            SMLoginItemSetEnabled(launcherAppIdentifier, startAtLogin.state == NSOnState)
            
            closeAndSave()
            self.window?.close()
        }
    }
    
    /* Notify of changes to delegates */
    func closeAndSave() {
        delegate?.preferencesDidUpdate()
    }
    
    /* Show an alert to the user */
    func dialogError(text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = errorTitle
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle(buttonTitle)
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }

}
