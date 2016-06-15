//
//  PopoverRootView.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

/* Override view of the popover to allow change background color */
class PopoverRootView: NSView {

    override func viewDidMoveToWindow() {
        self.wantsLayer = true
        let aFrameView = self.window?.contentView?.superview
        let a = PopoverBackgroundView(frame: aFrameView!.bounds)
        a.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        aFrameView?.addSubview(a, positioned: NSWindowOrderingMode.Below, relativeTo: aFrameView)
        super.viewDidMoveToWindow()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
    }
    
}

/* Allow to change the background color of the popover view */
class PopoverBackgroundView: NSView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        NSColor.init(red: 1, green:1, blue:1, alpha:1).set()
        NSRectFill(self.bounds)
    }
}
