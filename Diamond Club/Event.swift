//
//  Event.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

struct Event {

    let id: String
    let title: String
    let airingDate: Date
    let duration: Duration

}

extension Event: Hashable, Equatable, Comparable {
    var hashValue: Int {
        return id.hashValue
    }
}

func ==(lhs: Event, rhs: Event) -> Bool {
    return lhs.id == rhs.id
}

func <(lhs: Event, rhs: Event) -> Bool {
    return lhs.airingDate < rhs.airingDate
}
