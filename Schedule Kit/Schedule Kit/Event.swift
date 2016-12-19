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
    public let duration: Duration

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
