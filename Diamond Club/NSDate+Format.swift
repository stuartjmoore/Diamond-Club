//
//  NSDate+Format.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/26/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation

extension Date {

    public var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    public var dateString: String {
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

}
