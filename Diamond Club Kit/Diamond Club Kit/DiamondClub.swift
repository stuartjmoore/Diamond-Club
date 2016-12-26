//
//  DiamondClub.swift
//  Diamond Club
//
//  Created by Stuart Moore on 12/10/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation
import UIKit.UIImage

private let hostPath = "http://diamondclub.tv"
private let apiPath = "api"
private let userAgentValue = "diamondclub/appletv"

private let allChannelsURL = URL(string: "\(hostPath)/\(apiPath)/statusv2.php")!
private let liveChannelsURL = URL(string: "\(hostPath)/\(apiPath)/channelsv2.php")!
private let twentyFourSevenURL = URL(string: "https://ingest.diamondclub.tv/high/dctv.m3u8")!

private let allChannelsKey = "livestreams"
private let liveChannelsKey = "assignedchannels"

public struct DiamondClub {

    public static func iconURL(for channel: Int) -> URL {
        return URL(string: "\(hostPath)/\(apiPath)/hlsredirect.php?c=\(channel)&i=1")!
    }

    public static func streamURL(for channel: Int) -> URL {
        return URL(string: "\(hostPath)/\(apiPath)/hlsredirect.php?c=\(channel)")!
    }

    public static func getLiveChannels(completion: @escaping ([Channel]) -> Void) {
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: liveChannelsURL)
        request.setValue(userAgentValue, forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return print("No data") }
            guard let JSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return print("No JSON") }
            guard let channelsJSON = JSON?[liveChannelsKey] as? [[String: Any]] else { return print("No `\(liveChannelsKey)`") }

            let channels: [Channel] = [.TwentyFourSeven] + channelsJSON.flatMap(Channel.init)

            dump(channels)

            DispatchQueue.main.async {
                completion(channels)
            }
        }

        task.resume()
    }

    public static func getChannelIcon(for channel: Int, completion: @escaping (UIImage) -> Void) {
        guard channel > 0 else {
            return completion(#imageLiteral(resourceName: "twentyFourSeven"))
        }

        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: DiamondClub.iconURL(for: channel))
        request.setValue(userAgentValue, forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return print("No data") }
            guard let image = UIImage(data: data) else { return print("No image") }

            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
    
}

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
