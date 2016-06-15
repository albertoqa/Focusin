//
//  TasksViewController.swift
//  Focusin
//
//  Created by Alberto Quesada Aranda on 15/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class TasksViewController: NSViewController {

    @IBOutlet var mainView: PopoverRootView!
    
    let pomodoroView: PomodoroViewController
    let popoverView: NSPopover
    
    init(nibName: String, bundle: NSBundle?, popover: NSPopover, pomodoroView: PomodoroViewController) {
        self.popoverView = popover
        self.pomodoroView = pomodoroView
        super.init(nibName: nibName, bundle: bundle)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
