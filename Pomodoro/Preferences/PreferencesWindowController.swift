//
//  PreferencesWindowController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

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
    
    var closedWithButton: Bool = false
    let seconds: Int = 60
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
        
        /* Load preferred settings */
        pomodoroDuration.integerValue = defaults.integerForKey("pomodoroDuration")/seconds
        breakDuration.integerValue = defaults.integerForKey("breakDuration")/seconds
        targetPomodoros.integerValue = defaults.integerForKey("targetPomodoros")
        showNotifications.state = defaults.integerForKey("showNotifications")
        showTimeInBar.integerValue = defaults.integerForKey("showTimeInBar")
    }
    
    override var windowNibName : String! {
        return "PreferencesWindowController"
    }
    
    /* Save the current settings and close the window */
    @IBAction func savePreferences(sender: AnyObject) {
        closedWithButton = true
        
        defaults.setValue(pomodoroDuration.integerValue * seconds, forKey: "pomodoroDuration")
        defaults.setValue(breakDuration.integerValue * seconds, forKey: "breakDuration")
        defaults.setValue(targetPomodoros.integerValue, forKey: "targetPomodoros")
        defaults.setValue(showNotifications.state, forKey: "showNotifications")
        defaults.setValue(showTimeInBar.state, forKey: "showTimeInBar")

        closeAndSave()
        self.window?.close()
    }
    
    /* Save changes before close the window (this is performed only in case of close with default close button) */
    func windowWillClose(notification: NSNotification) {
        if(!closedWithButton) {
            savePreferences(self)
            closeAndSave()
        }
    }
    
    /* Notify of changes to delegates */
    func closeAndSave() {
        delegate?.preferencesDidUpdate()
    }

}
