//
//  PopoverRootView.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class PopoverRootView: NSView {

    override func viewDidMoveToWindow() {
        let aFrameView = self.window?.contentView?.superview
        let a = PopoverBackgroundView(frame: aFrameView!.bounds)
        a.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        aFrameView?.addSubview(a, positioned: NSWindowOrderingMode.Below, relativeTo: aFrameView)
        super.viewDidMoveToWindow()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        // Drawing code here.
    }
    
}


class PopoverBackgroundView: NSView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        NSColor.whiteColor().set()
        NSRectFill(self.bounds)
    }
}
