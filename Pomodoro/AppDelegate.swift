//
//  AppDelegate.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!    // this window will be hidden
    
    var eventMonitor: EventMonitor? // monitor if the user click outside of the app
    
    let menu = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let popover = NSPopover()
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        
        let defaultPomodoroDuration = 25 * 60
        let defaultBreakDuration = 5 * 60
        let defaultTargetPomodoros = 10

        if(NSUserDefaults.standardUserDefaults().stringForKey("pomodoroDuration") == nil) {
            NSUserDefaults.standardUserDefaults().setInteger(defaultPomodoroDuration, forKey: "pomodoroDuration")
            NSUserDefaults.standardUserDefaults().setInteger(defaultBreakDuration, forKey: "breakDuration")
            NSUserDefaults.standardUserDefaults().setInteger(defaultTargetPomodoros, forKey: "targetPomodoros")
        }
        
        if let button = menu.button {
            let icon = NSImage(named: "timer")
            icon?.template = true
            button.image = icon
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        popover.contentViewController = PomodoroViewController(nibName: "PomodoroViewController", bundle: nil)
        
        eventMonitor = EventMonitor(mask: .LeftMouseDownMask) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    func showPopover(sender: AnyObject?) {
        NSApp.activateIgnoringOtherApps(true)

        if let button = menu.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
        
        eventMonitor?.start()

    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()

    }
    
    func togglePopover(sender: AnyObject?) {
        if popover.shown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

