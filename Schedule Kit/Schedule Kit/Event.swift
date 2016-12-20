//
//  Event.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

public struct Event {

    public let id: String
    public let title: String
    public let airingDate: Date
    public let duration: TimeInterval

    public init(id: String, title: String, airingDate: Date, duration: TimeInterval) {
        self.id = id
        self.title = title
        self.airingDate = airingDate
        self.duration = duration
    }

    public init(id: String, title: String, fromDate: Date, toDate: Date) {
        self.id = id
        self.title = title
        self.airingDate = fromDate

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: fromDate, to: toDate)
        let (hour, minute, second) = (components.hour ?? 0, components.minute ?? 0, components.second ?? 0)
        self.duration = TimeInterval(hour * 60 * 60 + minute * 60 + second)
    }

}

extension Event: Hashable, Equatable, Comparable {
    public var hashValue: Int {
        return id.hashValue
    }
}

public func ==(lhs: Event, rhs: Event) -> Bool {
    return lhs.id == rhs.id
}

public func <(lhs: Event, rhs: Event) -> Bool {
    return lhs.airingDate < rhs.airingDate
}
