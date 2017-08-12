//
//  VideoManager.swift
//  Offtube
//
//  Created by Dirk Gerretz on 04.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

// GitHub: https://github.com/sonsongithub/YouTubeGetVideoInfoAPIParser

import Foundation
import YouTubeGetVideoInfoAPIParser
import CoreData

protocol VideoManagerProtocol: class {
    func noCompatibleVideoFound(_ reason: String)
}

class VideoManager: NSObject {

    // MARK: - Properties
    weak var delegate: VideoManagerProtocol?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let ytClient = YoutubeClient(apiUrl: "https://www.googleapis.com/youtube/v3/videos")

    func video(url: URL) -> Video? {

        let video = NSEntityDescription.insertNewObject(forEntityName: "Video", into: context) as! Video

        // set default values
        video.timePlayed = 0.0
        video.timeRemaining = 0.0
        video.downloadComplete = false
        video.youtubeUrl = url.absoluteString

        // extract the video ID from the regular Youtube URL
        guard let id = VideoManager.idFromUrl(url: url) else {
            delegate?.noCompatibleVideoFound("URL doesn't appear to be a Youtube URL")
            return nil
        }

        video.id = id

        // get the raw info on the video from Youtube
        let rawInfo = ytClient.getStreamingDetails(id)

        // retrieve streaming URL & encoding type
        let info = convertVideoInfo(info: rawInfo!)

        if info == nil {
            delegate?.noCompatibleVideoFound("No iOS compatible video format was found.")
            return nil
        }

        video.streamingUrl = (info?.url)?.absoluteString
        video.type = (info?.type)!

        // retrieve additional information (duration, title, ...)
        if let details = ytClient.getVideoDetails(videoId: id) {
            video.title = details["title"]!
            video.details = details["description"]!
            video.thumbnailUrl = details["thumbnailUrl"]
        }

        if let duration = ytClient.getVideoDuration(videoId: id) {
            video.duration = Int64(duration)
        }

        // prep for download
        guard video.title != nil else {
            print("*** Can't download video. No title available.")
            return nil
        }

        MainViewController.displayNetworkIndicator(true)
        let localFilePath = ytClient.prepareForDownload(fileName: (video.id! + ".mp4"))
        video.fileLocation = localFilePath.absoluteString

        // download video
        guard let streamingUrl = URL(string: video.streamingUrl!) else {
            print("*** Insufficient parameters to execute download")
            return nil
        }

        ytClient.downloadFile(fromUrl: streamingUrl, to: localFilePath, completion: { _ in
            video.downloadComplete = true
        })

        // download thumbnail
        guard let thumbnailUrl = URL(string: video.thumbnailUrl!) else {
            print("*** Can't download thumbnail. No url available.")
            return nil
        }

        let thumbnailFilePath = ytClient.prepareForDownload(fileName: (video.id! + ".jpg"))
        video.fileLocation = localFilePath.absoluteString

        ytClient.downloadFile(fromUrl: thumbnailUrl, to: thumbnailFilePath, completion: { _ in
            video.thumbnailUrl = thumbnailFilePath.absoluteString
        })

        // return NSManagedObject including all infos on the video
        return video
    }

    func convertVideoInfo(info: String) -> (url: URL, type: String)? {
        do {
            let maps = try FormatStreamMapFromString(info)

            for map in maps {
                if map.quality == .medium &&
                    map.type.contains("mp4") {
                    return (map.url, map.type)
                }
            }
        } catch {
            print("*** Error: couldn't convert to URL/type")
        }
        return nil
    }

    // MARK: Static Functions
    static func idFromUrl(url: URL) -> String? {
        if url.absoluteString.contains("https://youtu.be/") {
            return idFromShortUrl(url: url)
        } else if url.absoluteString.contains("https://www.youtube.com/watch") {
            return idFromRegularUrl(url: url)
        }
        return nil
    }

    static func idFromRegularUrl(url: URL, param: String = "v") -> String? {
        guard let url = URLComponents(string: url.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    static func idFromShortUrl(url: URL) -> String? {
        return (url.absoluteString).components(separatedBy: "https://youtu.be/").last
    }

    static func delete(file: String) {

        let fileManager = FileManager.default
        let url = URL(string: file)

        do {
            // Check if file exists
            if VideoManager.fileExists(url: url!) {
                // Delete file
                try fileManager.removeItem(atPath: (url?.path)!)
                print("*** Deleted file at path: \(file)")
            } else {
                print("*** File does not exist: \(file)")
            }
        } catch let error as NSError {
            print("*** An error took place: \(error)")
        }
    }

    static func clearTmpFolder() {
        let fileManager = FileManager.default
        let tmpFolder = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tmpFolder)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tmpFolder + filePath)
            }
        } catch {
            print("*** Could not clear temp folder: \(error)")
        }
    }

    static func fileExists(url: URL) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            return true
        }
        return false
    }

    static func secondsToHoursMinutesSeconds(seconds: Int64) -> (Int, Int, Int) {
        let secondsInt = Int(truncatingBitPattern: seconds)
        return (secondsInt / 3600, (secondsInt % 3600) / 60, (secondsInt % 3600) % 60)
    }
}
