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
    func handleNotificationAction(caller: Caller)
    func handleNotificationOther(caller: Caller)
}

/* Who is invoking the notification? The point of the application who create the notification. */
enum Caller {
    case TARGET, POMODORO, BREAK
}

/* Create and handle interaction with user notifications */
public class NotificationsHandler: NSObject, NSUserNotificationCenterDelegate {
    
    var delegate: NotificationsDelegate?
    
    var caller: Caller = Caller.BREAK
    var actionButtonPressed: Bool = false   // allows to differenciate between the buttons of the notification
    
    override init() {
        super.init()
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }
    
    /* Detect if the user interact with the notification - real action button */
    public func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if(notification.activationType == NSUserNotificationActivationType.ActionButtonClicked) {
            self.handleNotifications(notification, isActionButton: true)
        }
    }
    
    /* Show always the notification, even if the app is open */
    public func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    /* Detect dismissed notification -> in this app that is considered as press the other button */
    public func userNotificationCenter(center: NSUserNotificationCenter, didDeliverNotification notification: NSUserNotification) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            var notificationStillPresent = true
            while (notificationStillPresent) {
                NSThread.sleepForTimeInterval(1)
                notificationStillPresent = false
                for deliveredNotification in NSUserNotificationCenter.defaultUserNotificationCenter().deliveredNotifications {
                    if deliveredNotification.identifier == notification.identifier {
                        notificationStillPresent = true
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.handleNotifications(notification, isActionButton: false)
            }
        }
    }
    
    /* Show a new notification on the Notification Center */
    func showNotification(title: String, text: String, actionTitle: String, otherTitle: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.actionButtonTitle = actionTitle
        notification.otherButtonTitle = otherTitle
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    /* Handle the notifications */
    func handleNotifications(notification: NSUserNotification, isActionButton: Bool) {
        if(isActionButton) {
            actionButtonPressed = true
            handleNotificationAction(caller)
        } else if(!actionButtonPressed) {
            actionButtonPressed = false
            handleNotificationOther(caller)
        } else {
            actionButtonPressed = false
        }
    }
    
    /* Notification action: button action */
    func handleNotificationAction(caller: Caller) {
        delegate?.handleNotificationAction(caller)
    }
    
    /* Notification action: other action */
    func handleNotificationOther(caller: Caller) {
        delegate?.handleNotificationOther(caller)
    }
    
    /* Show an alert to the user */
    func dialogOKCancel(question: String, text: String, b1Text: String, b2Text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle(b1Text)
        myPopup.addButtonWithTitle(b2Text)
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
    
}
