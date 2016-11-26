//
//  NotificationsHandler.swift
//  Focusin
//
//  Created by Alberto Quesada Aranda on 14/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Foundation
import Cocoa

/* The delegate must implement the methods for control the action to perform for each notification */
protocol NotificationsDelegate {
    func handleNotificationAction(_ caller: Caller)
    func handleNotificationOther(_ caller: Caller)
    func handleNotificationOpenApp()
}

/* Who is invoking the notification? The point of the application who create the notification. */
enum Caller {
    case target, pomodoro, `break`
}

/* Create and handle interaction with user notifications */
open class NotificationsHandler: NSObject, NSUserNotificationCenterDelegate {
    
    var delegate: NotificationsDelegate?
    
    var caller: Caller = Caller.break
    var actionButtonPressed: Bool = false   // allows to differenciate between the buttons of the notification
    
    override init() {
        super.init()
        NSUserNotificationCenter.default.delegate = self
    }
    
    /* Detect if the user interact with the notification - real action button */
    open func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if(notification.activationType == NSUserNotification.ActivationType.actionButtonClicked) {
            self.handleNotifications(notification, isActionButton: true, openApp: false)
        } else {
            self.handleNotifications(notification, isActionButton: true, openApp: true)
        }
    }
    
    /* Show always the notification, even if the app is open */
    open func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    /* Detect dismissed notification -> in this app that is considered as press the other button */
    open func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        let priority = DispatchQueue.GlobalQueuePriority.default
        DispatchQueue.global(priority: priority).async {
            var notificationStillPresent = true
            while (notificationStillPresent) {
                Thread.sleep(forTimeInterval: 1)
                notificationStillPresent = false
                for deliveredNotification in NSUserNotificationCenter.default.deliveredNotifications {
                    if deliveredNotification.identifier == notification.identifier {
                        notificationStillPresent = true
                    }
                }
            }
            DispatchQueue.main.async {
                self.handleNotifications(notification, isActionButton: false, openApp: false)
            }
        }
    }
    
    /* Clear all notifications from the app */
    func removeAllNotifications() {
        actionButtonPressed = true  // this is set so the notification is not handled
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    }
    
    /* Show a new notification on the Notification Center */
    func showNotification(_ title: String, text: String, actionTitle: String, otherTitle: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.actionButtonTitle = actionTitle
        notification.otherButtonTitle = otherTitle
        //notification.contentImage = NSImage(named: "goal")
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    /* Handle the notifications */
    func handleNotifications(_ notification: NSUserNotification, isActionButton: Bool, openApp: Bool) {
        if(isActionButton && !openApp) {
            actionButtonPressed = true
            handleNotificationAction(caller)
        } else if(openApp) {
            handleNotificationOpenApp()
            removeAllNotifications()
        } else if(!actionButtonPressed) {           // TODO this is not working for the "Close" notifications
            actionButtonPressed = false
            handleNotificationOther(caller)
        } else {
            actionButtonPressed = false
        }
    }
    
    /* Notification action: button action */
    func handleNotificationAction(_ caller: Caller) {
        delegate?.handleNotificationAction(caller)
    }
    
    /* Notification action: other action */
    func handleNotificationOther(_ caller: Caller) {
        delegate?.handleNotificationOther(caller)
    }
    
    /* Close the notification and open the app */
    func handleNotificationOpenApp() {
        delegate?.handleNotificationOpenApp()
    }
    
}
