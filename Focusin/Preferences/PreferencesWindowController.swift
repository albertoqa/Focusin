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
    
    let defaults = UserDefaults.standard

    @IBOutlet weak var pomodoroDuration: NSTextField!
    @IBOutlet weak var shortBreakDuration: NSTextField!
    @IBOutlet weak var longBreakAfterXPomodoros: NSTextField!
    @IBOutlet weak var targetPomodoros: NSTextField!
    @IBOutlet weak var showNotifications: NSButton!
    @IBOutlet weak var showTimeInBar: NSButton!
    @IBOutlet weak var startAtLogin: NSButton!
    
    @IBOutlet weak var longBreadDuration: NSTextField!
    var closedWithButton: Bool = false
    let seconds: Int = 60
    
    let errorTitle = "Invalid value"
    let buttonTitle = "Ok"
    let errorPomodoro = "Pomodoro duration must be between 1 - 500"
    let errorBreak = "Break duration must be between 1 - 500"
    let errorTarget = "Target pomodoros must be between 1 - 99"
    let errorLongBreak = "Long break must be set between 1 - 99"
    
    let MIN_TIME = 1
    let MAX_TIME = 500
    let MIN_TARGET = 1
    let MAX_TARGET = 99
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        /* Load preferred settings */
        pomodoroDuration.integerValue = defaults.integer(forKey: Defaults.pomodoroKey)/seconds
        shortBreakDuration.integerValue = defaults.integer(forKey: Defaults.shortBreakKey)/seconds
        longBreadDuration.integerValue = defaults.integer(forKey: Defaults.longBreakKey)/seconds
        targetPomodoros.integerValue = defaults.integer(forKey: Defaults.targetKey)
        longBreakAfterXPomodoros.integerValue = defaults.integer(forKey: Defaults.longBreakAfterXPomodoros)
        showNotifications.state = defaults.integer(forKey: Defaults.showNotificationsKey)
        showTimeInBar.integerValue = defaults.integer(forKey: Defaults.showTimeKey)
        startAtLogin.integerValue = defaults.integer(forKey: Defaults.startAtLogin)
    }
    
    override var windowNibName : String! {
        return "PreferencesWindowController"
    }
    
    /* Save the current settings and close the window */
    @IBAction func savePreferences(_ sender: AnyObject) {
        closedWithButton = true
        
        if(pomodoroDuration.integerValue < MIN_TIME || pomodoroDuration.integerValue > MAX_TIME) {
            dialogError(errorPomodoro)
        } else if(shortBreakDuration.integerValue < MIN_TIME || shortBreakDuration.integerValue > MAX_TIME) {
            dialogError(errorBreak)
        } else if(longBreadDuration.integerValue < MIN_TIME || longBreadDuration.integerValue > MAX_TIME) {
            dialogError(errorBreak)
        } else if(targetPomodoros.integerValue < MIN_TARGET || targetPomodoros.integerValue > MAX_TARGET) {
            dialogError(errorTarget)
        } else if(longBreakAfterXPomodoros.integerValue < MIN_TARGET || longBreakAfterXPomodoros.integerValue > MAX_TARGET) {
            dialogError(errorLongBreak)
        } else {
            defaults.setValue(pomodoroDuration.integerValue * seconds, forKey: Defaults.pomodoroKey)
            defaults.setValue(shortBreakDuration.integerValue * seconds, forKey: Defaults.shortBreakKey)
            defaults.setValue(longBreadDuration.integerValue * seconds, forKey: Defaults.longBreakKey)
            defaults.setValue(longBreakAfterXPomodoros.integerValue, forKey: Defaults.longBreakAfterXPomodoros)
            defaults.setValue(targetPomodoros.integerValue, forKey: Defaults.targetKey)
            defaults.setValue(showNotifications.state, forKey: Defaults.showNotificationsKey)
            defaults.setValue(showTimeInBar.state, forKey: Defaults.showTimeKey)
            defaults.setValue(startAtLogin.state, forKey: Defaults.startAtLogin)

            let launcherAppIdentifier = "com.albertoquesada.LauncherApplication"
            SMLoginItemSetEnabled(launcherAppIdentifier as CFString, startAtLogin.state == NSOnState)
            
            closeAndSave()
            self.window?.close()
        }
    }
    
    /* Notify of changes to delegates */
    func closeAndSave() {
        delegate?.preferencesDidUpdate()
    }
    
    /* Show an alert to the user */
    func dialogError(_ text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = errorTitle
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: buttonTitle)
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }

}
