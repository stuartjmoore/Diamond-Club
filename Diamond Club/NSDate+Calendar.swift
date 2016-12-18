//
//  NSDate+Calendar.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 11/8/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

extension Date {

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var dateString: String {
        switch daysSeparatingToday {
        case -1:
            return "Yesterday"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            let formatter = DateFormatter(dateFormat: "EEEE")
            return formatter.string(from: self)
        }
    }

    var startOfDay: Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: self)
    }

    var startOfPreviousDay: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(day: -1)

        let startOfDay = calendar.startOfDay(for: self)
        let previousDay = calendar.date(byAdding: components, to: startOfDay)

        return previousDay ?? self
    }

    var endOfWeek: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(weekOfYear: 1, second: -1)

        let startOfDay = calendar.startOfDay(for: self)
        let endOfWeek = calendar.date(byAdding: components, to: startOfDay)

        return endOfWeek ?? self
    }

    var daysSeparatingToday: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: Date().startOfDay, to: startOfDay)

        return components.day ?? 0
    }

    func daysSeparatingDate(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: date.startOfDay, to: startOfDay)

        return components.day ?? 0
    }

}

extension DateFormatter {

    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }

}

extension DateComponents {

    init(day: Int) {
        self.init()
        self.day = day
    }

    init(weekOfYear: Int, second: Int) {
        self.init()
        self.weekOfYear = weekOfYear
        self.second = second
    }
    
}
