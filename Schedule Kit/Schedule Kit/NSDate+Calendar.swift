//
//  NSDate+Calendar.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 11/8/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

public extension Date {

    public var startOfDay: Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: self)
    }

    public var startOfPreviousDay: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(day: -1)

        let startOfDay = calendar.startOfDay(for: self)
        let previousDay = calendar.date(byAdding: components, to: startOfDay)

        return previousDay ?? self
    }

    public var endOfWeek: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(weekOfYear: 1, second: -1)

        let startOfDay = calendar.startOfDay(for: self)
        let endOfWeek = calendar.date(byAdding: components, to: startOfDay)

        return endOfWeek ?? self
    }

    public var daysSeparatingToday: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: Date().startOfDay, to: startOfDay)

        return components.day ?? 0
    }

    public func daysSeparatingDate(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: date.startOfDay, to: startOfDay)

        return components.day ?? 0
    }

}

extension DateFormatter {

    public convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }

}

extension DateComponents {

    public init(day: Int) {
        self.init()
        self.day = day
    }

    public init(weekOfYear: Int, second: Int) {
        self.init()
        self.weekOfYear = weekOfYear
        self.second = second
    }
    
}
