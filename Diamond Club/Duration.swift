//
//  Duration.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

struct Duration {

    let hours: Int
    let minutes: Int
    let seconds: Int

    var timeInterval: TimeInterval {
        return TimeInterval(hours * 60 * 60 + minutes * 60 + seconds)
    }

    init(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    init(fromDate: Date, toDate: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: fromDate, to: toDate)
        self.init(hours: components.hour ?? 0, minutes: components.minute ?? 0, seconds: components.second ?? 0)
    }

}

extension Duration: CustomStringConvertible {

    var description: String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        let minutesString = formatter.string(from: NSNumber(integerLiteral: minutes)) ?? "00"
        let secondsString = formatter.string(from: NSNumber(integerLiteral: seconds)) ?? "00"

        return "\(hours):\(minutesString):\(secondsString)"
    }
    
}

extension Duration: Hashable, Equatable, Comparable {
    var hashValue: Int {
        return timeInterval.hashValue
    }
}

func ==(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.timeInterval == rhs.timeInterval
}

func <(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.timeInterval < rhs.timeInterval
}
