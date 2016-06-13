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

    @IBOutlet weak var pomodoroDuration: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    override var windowNibName : String! {
        return "PreferencesWindowController"
    }
    
    @IBAction func savePreferences(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()

        defaults.setValue(pomodoroDuration.integerValue, forKey: "pomodoroDuration")

        closeAndSave()
    }
    
    func windowWillClose(notification: NSNotification) {
        savePreferences(self)
        closeAndSave()
    }
    
    func closeAndSave() {
        delegate?.preferencesDidUpdate()
    }
    
}
