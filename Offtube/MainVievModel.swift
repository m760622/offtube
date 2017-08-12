//
//  MainVievModel.swift
//  Offtube
//
//  Created by Dirk Gerretz on 15.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import UIKit
import CoreData

class MainViewModel: NSObject {

    // Properties
    let manager = VideoManager()
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var videos: Array<Video>?
    weak var viewController: MainViewController?

    override init() {
        super.init()

        // for testing purposes only
        // deleteAllVideos()

        manager.ytClient.delegate = self
        manager.delegate = self
        videos = fetchVideos()!

        for video in videos! {
            updateDownloadStatus(video: video)
        }
    }

    func updateDownloadStatus(video: Video) {
        let status = video.downloadComplete
        let exists = VideoManager.fileExists(url: URL(string: video.fileLocation!)!)

        if status && !exists {
            video.downloadComplete = false
        }

        if !status && exists {
            video.downloadComplete = true
        }
    }

    func fetchVideos() -> Array<Video>? {

        do {
            return try context.fetch(Video.fetchRequest()) as [Video]
        } catch {
            print("*** Fetching failed. Returning empt array. Error: \(error)")
        }
        return nil
    }

    func saveContext() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.saveContext()
    }

    func deleteAllVideos() {
        clearContext(context)
        videos = fetchVideos()!
        saveContext()
        VideoManager.clearTmpFolder()
        viewController?.tableView.reloadData()
    }

    func delete(video: Video) {
        VideoManager.delete(file: video.thumbnailUrl!)
        VideoManager.delete(file: video.fileLocation!)
        context.delete(video)
        videos = fetchVideos()
        saveContext()
    }

    func clearContext(_ context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        do {
            let videos = try context.fetch(fetchRequest) as! [NSManagedObject]

            for video in videos {
                context.delete(video)
            }
        } catch {
            print(error)
        }
    }

    func searchArrayForVideoBy(id: String) -> Video? {

        for video in videos! {
            if video.id == id {
                return video
            }
        }
        return nil
    }

    func count(context: NSManagedObjectContext) -> Int {
        do {
            return try context.count(for: Video.fetchRequest())
        } catch {
            // returning 0 in case of error to avoid crash
            print("error: \(error)")
            return 0
        }
    }

    func downloadImageAt(_ url: URL) -> UIImage {
        let data = try? Data(contentsOf: url)

        if let imageData = data {
            return UIImage(data: imageData)!
        } else {
            return UIImage(named: "Thumbnail")!
        }
    }

    func issueOneButtonAlert(_ message: String) {

        let alertController = UIAlertController(title: ":-(", message: message, preferredStyle: UIAlertControllerStyle.alert)

        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (_: UIAlertAction) -> Void in
        }
        alertController.addAction(okAction)
        viewController?.present(alertController, animated: true, completion: nil)
    }

    func timeStringFromSeonds(_ sec: Int64) -> String {
        let time = VideoManager.secondsToHoursMinutesSeconds(seconds: sec)

        var hours = "0"
        if time.0 < 10 {
            hours = "0\(time.0)"
        } else {
            hours = "\(time.0)"
        }

        var minutes = "0"
        if time.1 < 10 {
            minutes = "0\(time.1)"
        } else {
            minutes = "\(time.1)"
        }

        var seconds = "0"
        if time.2 < 10 {
            seconds = "0\(time.2)"
        } else {
            seconds = "\(time.2)"
        }

        return "\(hours):\(minutes):\(seconds)"
    }
}

extension MainViewModel: MainViewControllerProtocol {

    func requestVideo(url: String) {

        guard let url = URL(string: url) else {
            print("Search string is not a valid URL.")
            return
        }

        viewController?.searchBar.isUserInteractionEnabled = false

        if let video = manager.video(url: url) {
            saveContext()
            videos?.append(video)
        }

        viewController?.tableView.reloadData()
        viewController?.searchBar.isUserInteractionEnabled = true
    }

    func reloadVideo(index: Int) {
        let oldVideo = videos?[index]

        if oldVideo?.downloadComplete == true {
            print("Video is complete and will start playing now. Nothing to do here.")
            return
        }

        let ytUrl = URL(string: oldVideo!.youtubeUrl!)!

        // 1.) be sure to delete the old video before re-loading it
        delete(video: oldVideo!)

        // 2.) re-aquire entire video and replace the old one
        _ = manager.video(url: ytUrl)
        videos = fetchVideos()
        viewController?.tableView.reloadData()
    }
}

extension MainViewModel: UITableViewDataSource {

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {

        if (videos?.count)! > 0 {
            return (videos?.count)!
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoCell

        let video = videos?[indexPath.row]

        // Configure the cell...
        cell.title.text = video?.title
        cell.videoDescription.text = video?.details

        if Int((video?.timePlayed)!) > 0 {
            let remaining = timeStringFromSeonds(Int64((video?.timeRemaining)!))
            let duration = timeStringFromSeonds((video?.duration)!)
            cell.duration.text = remaining + " (\(duration))"
        } else {
            cell.duration.text = timeStringFromSeonds((video?.duration)!)
        }

        if let thumbnail = video?.thumbnailUrl {
            if let url = URL(string: thumbnail) {
                cell.thumbnail.image = downloadImageAt(url)
            }
        }

        if video?.downloadComplete == true {
            cell.downloadStatus.tintColor = UIColor(red: 0.20, green: 0.53, blue: 0.22, alpha: 1.00)
            cell.downloadStatus.alpha = 0.5
        } else {
            cell.downloadStatus.tintColor = .black
            cell.downloadStatus.alpha = 0.1
        }
        return cell
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            delete(video: (videos?[indexPath.row])!)
            viewController?.tableView.reloadData()
        }
    }
}

extension MainViewModel: YoutubeClientProtocol {

    func didCompleteRequestforFile(response: String, localUrl: URL) {

        if response == "SUCCESS" {
            print("*** Response: Success")
        } else if response == "FAILURE" {
            print("*** Response: Failure")
            for video in videos! {
                if video.thumbnailUrl == localUrl.absoluteString ||
                    video.fileLocation == localUrl.absoluteString {
                    delete(video: video)
                }
            }
        }

        if localUrl.absoluteString.hasSuffix(".mp4") {
            MainViewController.displayNetworkIndicator(false)
        }

        saveContext()
        viewController?.tableView.reloadData()
    }
}

extension MainViewModel: VideoManagerProtocol {

    func noCompatibleVideoFound(_ reason: String) {
        issueOneButtonAlert(reason)
    }
}
