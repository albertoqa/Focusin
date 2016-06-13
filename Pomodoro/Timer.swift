//
//  Timer.swift
//  Pomodoro
//
//  Created by Alberto Quesada Aranda on 13/6/16.
//  Copyright © 2016 Alberto Quesada Aranda. All rights reserved.
//

import Cocoa

class Timer: NSObject {
    
    let timeInterval = 1.0
    var pomodoroDuration: Int = 0   // total duration of a pomodoro
    var breakDuration: Int = 0      // total duration of a break
    
    var timer: NSTimer = NSTimer()
    
    var isPomodoro: Bool = true     // true if current timer is a pomodoro, false if it is a break
    var timeLeft: Int = 0           // time left for the current timer (it can be a pomodoro or a break)
    
    var finishedPomodoros: Int = 0  // number of pomodoros completed
    
    /* Init a new timer with a given pomodoro and break duration */
    init(_ pomodoroDuration: Int, _ breakDuration: Int) {
        super.init()

        self.pomodoroDuration = pomodoroDuration
        self.breakDuration = breakDuration
        self.timeLeft = pomodoroDuration
    }
    
    /* Control the time that the current timer has been running and stop when finished */
    func timerControl() {
        if(timeLeft > 0) {
            timeLeft = timeLeft - 1
        } else {
            stopTimer()
            if(isPomodoro) {
                finishedPomodoros += 1
            }
        }
    }
    
    /* Start the corresponding timer */
    func startTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self,
                                                            selector: #selector(timerControl), userInfo: nil, repeats: true)
    }
    
    /* Start the pomodoro timer */
    func startPomodoroTimer() {
        isPomodoro = true
        timeLeft = pomodoroDuration
        startTimer()
    }
    
    /* Start the break timer */
    func startBreakTimer() {
        isPomodoro = false
        timeLeft = breakDuration
        startTimer()
    }
    
    /* Unpause the currently running timer or if timeLeft is 0, restart it */
    func unPause() {
        if(timeLeft == 0) {
            startPomodoroTimer()
        } else {
            startTimer()
        }
    }
    
    /* Pause the currently running timer */
    func pauseTimer() {
        stopTimer()
    }
    
    /* Stop the current timer and reset the pomodoro timer (no break timer) */
    func resetTimer() {
        if(self.timer.valid) {
            self.timer.invalidate()
            timeLeft = pomodoroDuration
            isPomodoro = true
        }
    }
    
    /* Stop the current timer */
    func stopTimer() {
        if(self.timer.valid) {
            self.timer.invalidate()
        }
    }
    
    
}
