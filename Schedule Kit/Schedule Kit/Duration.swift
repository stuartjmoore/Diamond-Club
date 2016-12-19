//
//  Duration.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

public struct Duration {

    let hours: Int
    let minutes: Int
    let seconds: Int

    public var timeInterval: TimeInterval {
        return TimeInterval(hours * 60 * 60 + minutes * 60 + seconds)
    }

    public init(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    public init(fromDate: Date, toDate: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: fromDate, to: toDate)
        self.init(hours: components.hour ?? 0, minutes: components.minute ?? 0, seconds: components.second ?? 0)
    }

}

extension Duration: CustomStringConvertible {

    public var description: String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        let minutesString = formatter.string(from: NSNumber(integerLiteral: minutes)) ?? "00"
        let secondsString = formatter.string(from: NSNumber(integerLiteral: seconds)) ?? "00"

        return "\(hours):\(minutesString):\(secondsString)"
    }
    
}

extension Duration: Hashable, Equatable, Comparable {
    public var hashValue: Int {
        return timeInterval.hashValue
    }
}

public func ==(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.timeInterval == rhs.timeInterval
}

public func <(lhs: Duration, rhs: Duration) -> Bool {
    return lhs.timeInterval < rhs.timeInterval
}
