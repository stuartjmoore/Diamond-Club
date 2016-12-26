//
//  Channel.swift
//  Diamond Club Kit
//
//  Created by Stuart Moore on 12/26/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation

public struct Channel {

    public let id: Int
    public let number: Int
    public let title: String
    public let imageURL: URL?
    public let description: String?
    public let currentGame: String?

    public init?(JSON: [String: Any]) {
        guard let id = JSON["streamid"] as? Int else { return nil }
        guard let number = JSON["channel"] as? Int else { return nil }

        let alias = JSON["friendlyalias"] as? String
        let name = JSON["channelname"] as? String
        let title = alias?.isEmpty == false ? alias! : name?.isEmpty == false ? name! : "[unnamed]"

        let description = JSON["twitch_yt_description"] as? String
        let currentGame = JSON["twitch_currentgame"] as? String

        let imageHDString = JSON["imageassethd"] as? String
        let imageSDString = JSON["imageasset"] as? String
        let imageString = imageHDString?.isEmpty == false ? imageHDString : imageSDString?.isEmpty == false ? imageSDString : nil

        self.id = id
        self.number = number
        self.title = title
        self.imageURL = imageString?.isEmpty == false ? URL(string: imageString!) : nil
        self.description = description?.isEmpty == false ? description : nil
        self.currentGame = currentGame?.isEmpty == false ? currentGame : nil
    }

    public init(id: Int, number: Int, title: String, imageURL: URL?, description: String?, currentGame: String?) {
        self.id = id
        self.number = number
        self.title = title
        self.imageURL = imageURL
        self.description = description
        self.currentGame = currentGame
    }

    public static let TwentyFourSeven = Channel(id: 0, number: 0, title: "24/7", imageURL: nil, description: nil, currentGame: nil)
    
}

extension Channel: Equatable {

    public static func ==(lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
    
}
