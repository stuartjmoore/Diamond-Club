//
//  NSNumber+UIPressType.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/16/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation
import AVKit

extension NSNumber {

    static var upArrow: NSNumber {
        return NSNumber(integerLiteral: UIPressType.upArrow.rawValue)
    }

    static var leftArrow: NSNumber {
        return NSNumber(integerLiteral: UIPressType.leftArrow.rawValue)
    }

    static var downArrow: NSNumber {
        return NSNumber(integerLiteral: UIPressType.downArrow.rawValue)
    }

    static var rightArrow: NSNumber {
        return NSNumber(integerLiteral: UIPressType.rightArrow.rawValue)
    }

    static var menu: NSNumber {
        return NSNumber(integerLiteral: UIPressType.menu.rawValue)
    }

    static var playPause: NSNumber {
        return NSNumber(integerLiteral: UIPressType.playPause.rawValue)
    }

    static var select: NSNumber {
        return NSNumber(integerLiteral: UIPressType.select.rawValue)
    }
    
}
