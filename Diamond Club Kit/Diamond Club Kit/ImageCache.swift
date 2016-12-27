//
//  ImageCache.swift
//  Diamond Club Kit
//
//  Created by Stuart Moore on 12/27/16.
//  Copyright © 2016 Stuart J. Moore. All rights reserved.
//

import Foundation

internal class ImageCache: NSCache<AnyObject, AnyObject> {

    fileprivate let queue = DispatchQueue(label: "com.stuartjmoore.diamond-club-kit.image-queue", attributes: .concurrent)

    fileprivate var cacheURL: URL? {
        guard let directoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true).last else {
            return nil
        }

        return URL(fileURLWithPath: directoryPath).appendingPathComponent(name)
    }

    convenience init(name: String, totalCostLimit: Int = 0, countLimit: Int = 0, evictsObjectsWithDiscardedContent: Bool = true) {
        self.init()

        self.name = name
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
        self.evictsObjectsWithDiscardedContent = evictsObjectsWithDiscardedContent

        if let cachePath = cacheURL?.path {
            var isDirectory = ObjCBool(false)

            if FileManager().fileExists(atPath: cachePath, isDirectory: &isDirectory) == false, let cacheURL = cacheURL {
                do {
                    try FileManager().createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("NSFileManager createDirectoryAtURL error.")
                }
            } else if !isDirectory.boolValue {
                print("Caches is a file!?")
            }
        }
    }

    subscript(key: AnyObject) -> AnyObject? {
        get {
            var object: AnyObject? = nil

            queue.sync {
                object = self.object(forKey: key)

                if object == nil, let keyPath = self.URLForKey(key)?.path, let archivedObject = NSKeyedUnarchiver.unarchiveObject(withFile: keyPath) {
                    object = archivedObject as AnyObject?

                    self.queue.async(flags: .barrier) {
                        self.setObject(archivedObject as AnyObject, forKey: key)
                    }
                }
            }

            return object
        } set(newObject) {
            queue.async(flags: .barrier) {
                if let object = newObject {
                    self.setObject(object, forKey: key)

                    if let keyPath = self.URLForKey(key)?.path, NSKeyedArchiver.archiveRootObject(object, toFile: keyPath) == false {
                        print("Unable to archive \(object) to \(keyPath)")
                    }
                } else {
                    self.removeObject(forKey: key)

                    if let keyURL = self.URLForKey(key) {
                        do {
                            try FileManager().removeItem(at: keyURL)
                        } catch {
                            print("NSFileManager removeItemAtURL error.")
                        }
                    }
                }
            }
        }
    }

    fileprivate func URLForKey(_ key: AnyObject) -> URL? {
        guard let encodedKey = String(describing: key).addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }

        return cacheURL?.appendingPathComponent(encodedKey)
    }

}
