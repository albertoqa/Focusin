//
//  AboutWindowController.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override var windowNibName : String! {
        return "AboutWindowController"
    }
    
    @IBAction func openIcons8(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "http://icons8.com")!)
    }
    
    @IBAction func openAlberto(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "http://albertoquesada.com")!)
    }
    
    @IBAction func getCode(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://github.com/albertoqa/Focusin")!)
    }
    
    
}
