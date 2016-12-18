//
//  TasksViewController.swift
//  Focusin
//
//  Created by Alberto Quesada Aranda on 15/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

/* Save only the three most important tasks of the day */
class TasksViewController: NSViewController {

    @IBOutlet var mainView: PopoverRootView!
    
    @IBOutlet weak var t1: NSTextField!
    @IBOutlet weak var t1s: NSButton!
    @IBOutlet weak var t2: NSTextField!
    @IBOutlet weak var t2s: NSButton!
    @IBOutlet weak var t3: NSTextField!
    @IBOutlet weak var t3s: NSButton!
    
    let pomodoroView: PomodoroViewController
    let popoverView: NSPopover
    
    var task1state: Bool = false
    var task2state: Bool = false
    var task3state: Bool = false
    
    init(nibName: String, bundle: Bundle?, popover: NSPopover, pomodoroView: PomodoroViewController) {
        self.popoverView = popover
        self.pomodoroView = pomodoroView
        super.init(nibName: nibName, bundle: bundle)!
        PlistManager.sharedInstance.startPlistManager()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        writeDataInView()
    }
    
    /* Write the data saved in the view */
    func writeDataInView() {
        t1.stringValue = PlistManager.sharedInstance.getValueForKey(TaskKeys.task1) as! String
        t2.stringValue = PlistManager.sharedInstance.getValueForKey(TaskKeys.task2) as! String
        t3.stringValue = PlistManager.sharedInstance.getValueForKey(TaskKeys.task3) as! String
        
        task1state = PlistManager.sharedInstance.getValueForKey(TaskKeys.task1state) as! Bool
        task2state = PlistManager.sharedInstance.getValueForKey(TaskKeys.task2state) as! Bool
        task3state = PlistManager.sharedInstance.getValueForKey(TaskKeys.task3state) as! Bool
        
        toggleButton(t1s, status: task1state)
        toggleButton(t2s, status: task2state)
        toggleButton(t3s, status: task3state)
    }
    
    
    @IBAction func task1Set(_ sender: AnyObject) {
        PlistManager.sharedInstance.saveValue(t1.stringValue as AnyObject, forKey: TaskKeys.task1)
    }
    
    @IBAction func task2Set(_ sender: AnyObject) {
        PlistManager.sharedInstance.saveValue(t2.stringValue as AnyObject, forKey: TaskKeys.task2)
    }
    
    @IBAction func task3Set(_ sender: AnyObject) {
        PlistManager.sharedInstance.saveValue(t3.stringValue as AnyObject, forKey: TaskKeys.task3)
    }
    
    @IBAction func task1SetStatus(_ sender: AnyObject) {
        task1state = !task1state
        toggleButton(t1s, status: task1state)
        PlistManager.sharedInstance.saveValue(task1state as AnyObject, forKey: TaskKeys.task1state)
    }
    
    @IBAction func task2SetStatus(_ sender: AnyObject) {
        task2state = !task2state
        toggleButton(t2s, status: task2state)
        PlistManager.sharedInstance.saveValue(task2state as AnyObject, forKey: TaskKeys.task2state)
    }
    
    @IBAction func task3SetStatus(_ sender: AnyObject) {
        task3state = !task3state
        toggleButton(t3s, status: task3state)
        PlistManager.sharedInstance.saveValue(task3state as AnyObject, forKey: TaskKeys.task3state)
    }
    
    /* Toggle the state of a button */
    func toggleButton(_ button: NSButton, status: Bool) {
        if(status) {
            button.image = NSImage(named: "ok-1")
        } else {
            button.image = NSImage(named: "ok")
        }
    }
    
}
