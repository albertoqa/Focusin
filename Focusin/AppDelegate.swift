//
//  AppDelegate.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!    // this window will be hidden
    
    var eventMonitor: EventMonitor? // monitor if the user click outside of the app
    
    let menu = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let popover = NSPopover()
    
    let barIcon = "timer-2"
    let timeFormat = "%d:%02d"
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        
        let defaultPomodoroDuration = 25 * 60
        let defaultBreakDuration = 5 * 60
        let defaultTargetPomodoros = 10
        
        NSUserDefaults.standardUserDefaults().setInteger(3, forKey: Defaults.pomodoroKey)
        NSUserDefaults.standardUserDefaults().setInteger(3, forKey: Defaults.breakKey)
        NSUserDefaults.standardUserDefaults().setInteger(4, forKey: Defaults.targetKey)

        /* On first time launch set the default values */
        if(NSUserDefaults.standardUserDefaults().stringForKey(Defaults.pomodoroKey) == nil) {
            NSUserDefaults.standardUserDefaults().setInteger(defaultPomodoroDuration, forKey: Defaults.pomodoroKey)
            NSUserDefaults.standardUserDefaults().setInteger(defaultBreakDuration, forKey: Defaults.breakKey)
            NSUserDefaults.standardUserDefaults().setInteger(defaultTargetPomodoros, forKey: Defaults.targetKey)
            NSUserDefaults.standardUserDefaults().setInteger(NSOnState, forKey: Defaults.showTimeKey)
            NSUserDefaults.standardUserDefaults().setInteger(NSOnState, forKey: Defaults.showNotificationsKey)
            NSUserDefaults.standardUserDefaults().setInteger(NSOffState, forKey: Defaults.startAtLogin)
        }
        
        let launcherAppIdentifier = "com.albertoquesada.LauncherApplication"
        SMLoginItemSetEnabled(launcherAppIdentifier, NSUserDefaults.standardUserDefaults().integerForKey(Defaults.startAtLogin) == NSOnState)
        
        var startedAtLogin = false
        for app in NSWorkspace.sharedWorkspace().runningApplications {
            if(app.bundleIdentifier == launcherAppIdentifier) {
                startedAtLogin = true
                break
            }
        }
        
        if startedAtLogin {
            NSDistributedNotificationCenter.defaultCenter().postNotificationName("killme", object: NSBundle.mainBundle().bundleIdentifier!)
        }
        
        // Set the icon for the menu bar
        let button = menu.button
        let icon = NSImage(named: barIcon)
        icon?.template = true   // normal and dark mode
        button!.image = icon
        button!.imagePosition = NSCellImagePosition.ImageLeft
        button!.action = #selector(AppDelegate.togglePopover(_:))
        
        // Show time in menu bar only if user wants it
        if(NSUserDefaults.standardUserDefaults().integerForKey(Defaults.showTimeKey) == NSOnState) {
            let pomodoroDefaultDuration = NSUserDefaults.standardUserDefaults().integerForKey(Defaults.pomodoroKey)
            button!.title = String(format: timeFormat, pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
        }

        popover.contentViewController = PomodoroViewController(nibName: "PomodoroViewController", bundle: nil, button: button!, popover: popover)
        
        eventMonitor = EventMonitor(mask: .LeftMouseDownMask) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    /* Show popover when click on menu bar button */
    func showPopover(sender: AnyObject?) {
        NSApp.activateIgnoringOtherApps(true)
        
        if let button = menu.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
        
        eventMonitor?.start()
    }
    
    /* Close popover when click outside of the view */
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    /* Toggle the popover visibility */
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

