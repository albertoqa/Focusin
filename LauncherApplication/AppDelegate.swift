//
//  AppDelegate.swift
//  LauncherApplication
//
//  Created by Alberto Quesada Aranda on 15/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {

        let mainAppIndentifier = "com.albertoquesada.Focusin"
        let running = NSWorkspace.sharedWorkspace().runningApplications
        let alreadyRunning = false
        
        for app in running {
            if app.bundleIdentifier == mainAppIndentifier {
                alreadyRunning = true
                break
            }
        }
    
        if !alreadyRunning {
            NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "terminate", name: "killme", object: mainAppIndentifier)
            
            let path = NSBundle.mainBundle().bundlePath as NSString
            var components = path.pathComponents
            
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Focusin")
            
            let newPath = NSString.pathWithComponents(components)
            NSWorkspace.sharedWorkspace().launchApplication(newPath)
        } else {
            self.terminate()
        }
    }

    
    func terminate() {
        NSApp.terminate(nil)
    }


}

