//
//  UIImage+URL.swift
//  Diamond Club Kit
//
//  Created by Stuart Moore on 12/27/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation
import UIKit.UIImage

extension UIImage {

    typealias ImageCompletion = (UIImage) -> Void

    fileprivate static let cache = ImageCache(name: "com.stuartjmoore.diamond-club-kit.image-cache", countLimit: 350)
    fileprivate static var completions: [URL:[ImageCompletion]] = [:]

    fileprivate static let observerKey = "com.stuartjmoore.diamond-club-kit.image-did-change"

    fileprivate static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 5
        return URLSession(configuration: configuration)
    }()

    class func from(URL url: URL) -> UIImage? {
        return cache[url as AnyObject] as? UIImage
    }

    class func from(URL url: URL, completion: @escaping ImageCompletion) {
        if let posterImage = cache[url as AnyObject] as? UIImage {
            completion(posterImage)
            return
        }

        guard completions[url] == nil else {
            completions[url]?.append(completion)
            return
        }

        completions[url] = [completion]

        var request = URLRequest(url: url)
        request.setValue(userAgentValue, forHTTPHeaderField: "User-Agent")

        let task = UIImage.session.dataTask(with: request, completionHandler: { (data, response, error) in
            do {
                guard error == nil else {
                    return print(error!)
                }

                guard let data = data else {
                    return print("No image data.")
                }

                guard let posterImage = UIImage(data: data) else {
                    return print("Unable to create image from data.")
                }

                cache[url as AnyObject] = posterImage

                DispatchQueue.main.async {
                    completions[url]?.forEach({ $0(posterImage) })
                    completions[url] = nil
                }
            }
        }) 
        
        task.resume()
    }

    // MARK: -

    class func saveImage(_ image: UIImage, forURL url: URL) {
        cache[url as AnyObject] = image
        NotificationCenter.default.post(name: Notification.Name(rawValue: UIImage.observerKey), object: url, userInfo: ["image": image])
    }

    class func observeImageForURL(_ url: URL, block: @escaping (_ image: UIImage) -> Void) -> AnyObject {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: UIImage.observerKey), object: url, queue: nil) { (notification) in
            if let image = notification.userInfo?["image"] as? UIImage {
                block(image)
            }
        }
    }

    class func removeObserver(_ observer: AnyObject?) {
        if let imageObserver = observer {
            NotificationCenter.default.removeObserver(imageObserver)
        }
    }

}
