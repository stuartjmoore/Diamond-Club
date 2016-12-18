//
//  ScheduleClient.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/15/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

private let calendarId = "a5jeb9t5etasrbl6dt5htkv4to%40group.calendar.google.com"

class ScheduleClient {

    fileprivate static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: configuration)
    }()

    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // RFC3339
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter
    }()

    func week(_ completion: @escaping (([[Event]]) -> Void)) {
        let startDate = Date() // .startOfPreviousDay
        let endDate = startDate.endOfWeek

        eventsStartingFromDate(startDate, toDate: endDate, completion: completion)
    }

    func nextEpisode(_ completion: @escaping (([Event]) -> Void)) {
        eventsStartingFromDate(Date(), count: 2) { (scheduled) in
            completion(scheduled.flatMap({ $0 }))
        }
    }

    fileprivate func eventsStartingFromDate(_ startDate: Date, toDate endDate: Date? = nil, count: Int? = nil, completion: @escaping (([[Event]]) -> Void)) {
        guard let keysFilepath = Bundle.main.path(forResource: "Keys", ofType:"plist"),
              let allKeys = NSDictionary(contentsOfFile: keysFilepath) as? [String:AnyObject],
              let keys = allKeys["Google"] as? [String:String],
              let apiKey = keys["api-key"], let referer = keys["referer"] else {
            return print("Unable to get Google key or referer.")
        }

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")
        let timeMin = dateFormatter.string(from: startDate)

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
            let timeMax = dateFormatter.string(from: endDate)
            components?.queryItems?.append(URLQueryItem(name: "timeMax", value: timeMax))
        }

        if let count = count {
            components?.queryItems?.append(URLQueryItem(name: "maxResults", value: String(count)))
        }

        guard let url = components?.url else {
            return print("Unable to create URL.")
        }

        let session = ScheduleClient.session
        var request = URLRequest(url: url)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) { (data, response, error) in
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

            var scheduled: [[Event]] = [[],[],[],[],[],[],[]]

            for item in items {
                guard let itemId = item["id"] as? String else {
                    return print("No item schedule id.")
                }

                guard let itemTitle = item["summary"] as? String else {
                    return print("No item schedule title.")
                }

                guard let itemStart = item["start"] as? [String: Any], let itemStartDateString = itemStart["dateTime"] as? String,
                      let itemStartDate = self.dateFormatter.date(from: itemStartDateString) else {
                        return print("No item schedule start date.")
                }

                guard let itemEnd = item["end"] as? [String: Any], let itemEndDateString = itemEnd["dateTime"] as? String,
                      let itemEndDate = self.dateFormatter.date(from: itemEndDateString) else {
                        return print("No item schedule end date.")
                }

                let duration = Duration(fromDate: itemStartDate, toDate: itemEndDate)
                let event = Event(id: itemId, title: itemTitle, airingDate: itemStartDate, duration: duration)
                let sectionIndex = event.airingDate.daysSeparatingDate(startDate)

                if sectionIndex >= scheduled.count {
                    scheduled.append([event])
                } else {
                    scheduled[sectionIndex].append(event)
                }

                dump(scheduled)
            }
            
            DispatchQueue.main.async {
                completion(scheduled)
            }
        }
        
        task.resume()
    }

}
