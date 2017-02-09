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
    
    let menu = NSStatusBar.system().statusItem(withLength: 70)
    let popover = NSPopover()
    
    let barIcon = "goal-1"
    let timeFormat = "%d:%02d"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let defaultPomodoroDuration = 25 * 60
        let defaultLongBreakDuration = 15 * 5
        let defaultShortBreakDuration = 5 * 60
        let defaultTargetPomodoros = 8
        let defaultLongBreakAfterXPomodoros = 4
        
        /*NSUserDefaults.standardUserDefaults().setInteger(3, forKey: Defaults.pomodoroKey)
        NSUserDefaults.standardUserDefaults().setInteger(3, forKey: Defaults.shortBreakKey)
        NSUserDefaults.standardUserDefaults().setInteger(5, forKey: Defaults.longBreakKey)
        NSUserDefaults.standardUserDefaults().setInteger(2, forKey: Defaults.longBreakAfterXPomodoros)
        NSUserDefaults.standardUserDefaults().setInteger(4, forKey: Defaults.targetKey)*/

        /* On first time launch set the default values */
        if(UserDefaults.standard.string(forKey: Defaults.pomodoroKey) == nil) {
            UserDefaults.standard.set(defaultPomodoroDuration, forKey: Defaults.pomodoroKey)
            UserDefaults.standard.set(defaultLongBreakDuration, forKey: Defaults.longBreakKey)
            UserDefaults.standard.set(defaultShortBreakDuration, forKey: Defaults.shortBreakKey)
            UserDefaults.standard.set(defaultLongBreakAfterXPomodoros, forKey: Defaults.longBreakAfterXPomodoros)
            UserDefaults.standard.set(defaultTargetPomodoros, forKey: Defaults.targetKey)
            UserDefaults.standard.set(NSOnState, forKey: Defaults.showTimeKey)
            UserDefaults.standard.set(NSOnState, forKey: Defaults.showNotificationsKey)
            UserDefaults.standard.set(NSOffState, forKey: Defaults.startAtLogin)
        }
        
        let launcherAppIdentifier = "com.albertoquesada.LauncherApplication"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, UserDefaults.standard.integer(forKey: Defaults.startAtLogin) == NSOnState)
        
        var startedAtLogin = false
        for app in NSWorkspace.shared().runningApplications {
            if(app.bundleIdentifier == launcherAppIdentifier) {
                startedAtLogin = true
                break
            }
        }
        
        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: NSNotification.Name.init(rawValue: "killme"), object: Bundle.main.bundleIdentifier!)
        }
        
        // Set the icon for the menu bar
        let button = menu.button
        let icon = NSImage(named: barIcon)
        icon?.size.height = 18
        icon?.size.width = 18
        icon?.isTemplate = true   // normal and dark mode
        button!.image = icon
        button!.imagePosition = NSCellImagePosition.imageLeft
        button!.action = #selector(AppDelegate.togglePopover(_:))
        
        // Show time in menu bar only if user wants it
        if(UserDefaults.standard.integer(forKey: Defaults.showTimeKey) == NSOnState) {
            let pomodoroDefaultDuration = UserDefaults.standard.integer(forKey: Defaults.pomodoroKey)
            button!.title = String(format: timeFormat, pomodoroDefaultDuration/60, pomodoroDefaultDuration%60)
        }

        popover.contentViewController = PomodoroViewController(nibName: "PomodoroViewController", bundle: nil, button: button!, popover: popover)
        
        eventMonitor = EventMonitor(mask: .leftMouseDown) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    /* Show popover when click on menu bar button */
    func showPopover(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        
        if let button = menu.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
        eventMonitor?.start()
    }
    
    /* Close popover when click outside of the view */
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    /* Toggle the popover visibility */
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

