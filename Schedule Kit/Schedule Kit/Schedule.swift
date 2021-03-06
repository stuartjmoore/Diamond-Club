//
//  ScheduleClient.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/15/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

private let calendarId = "a5jeb9t5etasrbl6dt5htkv4to%40group.calendar.google.com"

private let ScheduleSession: URLSession = {
    let configuration: URLSessionConfiguration = .ephemeral
    configuration.httpMaximumConnectionsPerHost = 1
    return URLSession(configuration: configuration)
}()

private let RFC3339DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    formatter.timeZone = TimeZone(identifier: "America/New_York")
    return formatter
}()

public class ScheduleClient {

    public static func fromNow(_ completion: @escaping (([[Event]]) -> Void)) {
        let startDate = Date()
        let endDate = startDate.endOfWeek

        events(startDate: startDate, toDate: endDate, completion: completion)
    }

    public static func nextEpisode(_ completion: @escaping (([Event]) -> Void)) {
        events(startDate: Date(), count: 2) { (scheduled) in
            completion(scheduled.flatMap({ $0 }))
        }
    }

    fileprivate static func events(startDate: Date, toDate endDate: Date? = nil, count: Int? = nil, completion: @escaping (([[Event]]) -> Void)) {
        guard let keysFilepath = Bundle.main.path(forResource: "Keys", ofType:"plist"),
              let allKeys = NSDictionary(contentsOfFile: keysFilepath) as? [String:AnyObject],
              let keys = allKeys["Google"] as? [String:String],
              let apiKey = keys["api-key"], let referer = keys["referer"] else {
            return print("Unable to get Google key or referer.")
        }

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")
        let timeMin = RFC3339DateFormatter.string(from: startDate)

        components?.queryItems = [
            URLQueryItem(name: "alwaysIncludeEmail", value: "false"),
            URLQueryItem(name: "showHiddenInvitations", value: "false"),
            URLQueryItem(name: "showDeleted", value: "false"),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeZone", value: "America/New_York"),
            URLQueryItem(name: "fields", value: "items(description,end,hangoutLink,id,start,summary)"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        if let endDate = endDate {
            let timeMax = RFC3339DateFormatter.string(from: endDate)
            components?.queryItems?.append(URLQueryItem(name: "timeMax", value: timeMax))
        }

        if let count = count {
            components?.queryItems?.append(URLQueryItem(name: "maxResults", value: String(count)))
        }

        guard let url = components?.url else {
            return print("Unable to create URL.")
        }

        var request = URLRequest(url: url)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = ScheduleSession.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return print(error ?? "error")
            }

            guard let data = data else {
                return print("No schedule data.")
            }

            guard let JSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return print("Schedule JSON parse failed.")
            }

            guard let items = JSON?["items"] as? [[String: Any]] else {
                return print("No schedule items.")
            }

            var scheduled: [[Event]] = []

            for item in items {
                guard let itemId = item["id"] as? String else {
                    return print("No item schedule id.")
                }

                guard let itemTitle = item["summary"] as? String else {
                    return print("No item schedule title.")
                }

                guard let itemStart = item["start"] as? [String: Any], let itemStartDateString = itemStart["dateTime"] as? String,
                      let itemStartDate = RFC3339DateFormatter.date(from: itemStartDateString) else {
                        return print("No item schedule start date.")
                }

                guard let itemEnd = item["end"] as? [String: Any], let itemEndDateString = itemEnd["dateTime"] as? String,
                      let itemEndDate = RFC3339DateFormatter.date(from: itemEndDateString) else {
                        return print("No item schedule end date.")
                }

                let event = Event(id: itemId, title: itemTitle, fromDate: itemStartDate, toDate: itemEndDate)
                let sectionIndex = event.airingDate.daysSeparatingDate(startDate)

                scheduled += Array(repeating: [], count: max(0, sectionIndex - scheduled.count))

                if sectionIndex >= scheduled.count {
                    scheduled.append([event])
                } else {
                    scheduled[sectionIndex].append(event)
                }
            }
            
            DispatchQueue.main.async {
                completion(scheduled)
            }
        }
        
        task.resume()
    }

}
