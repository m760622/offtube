//
//  YoutubeClient.swift
//  Garage
//
//  Created by Dirk Gerretz on 29/12/2016.
//  Copyright © 2016 [code2app];. All rights reserved.
//

import Foundation
import Alamofire
import Alamofire_Synchronous
import SwiftyJSON

protocol YoutubeClientProtocol: class {
    func didCompleteRequestforFile(response: String, localUrl: URL)
}

class YoutubeClient: NSObject {

    typealias ResponseHandler = (DataResponse<Any>) -> Void

    // MARK: - Properties
    weak var delegate: YoutubeClientProtocol?
    let apiKey = "AIzaSyBmXvvROXcDA0dsuA7UzfequF5_QM2YYvQ"

    // the base url for the Youtube API
    var apiUrl: String?

    init(apiUrl: String?) {
        self.apiUrl = apiUrl
    }

    // this returns additional information on the video (title, thumbnail location, description)
    func getVideoDetails(videoId: String) -> Dictionary<String, String>? {

        let parameters: [String: Any] = [
            "part": "snippet, statistics",
            "fields": "items(snippet(thumbnails(default),description,title))",
            "key": "AIzaSyBmXvvROXcDA0dsuA7UzfequF5_QM2YYvQ",
            "id": videoId,
        ]

        if let response = syncHttpRequestForJson(url: apiUrl!, method: .get, parameters: parameters) {
            switch response.result {
            case let .success(value):
                let json = JSON(value)
                print("JSON: \(json)")
                var details = [String: String]()
                details["title"] = json["items"][0]["snippet"]["title"].string
                details["description"] = json["items"][0]["snippet"]["description"].string
                details["thumbnailUrl"] = json["items"][0]["snippet"]["thumbnails"]["default"]["url"].string
                return details
            case let .failure(error):
                print(error)
            }
        }
        return nil
    }

    // this gets the duration of the video
    func getVideoDuration(videoId: String) -> Int? {

        let parameters: [String: Any] = [
            "part": "contentDetails",
            "key": "AIzaSyBmXvvROXcDA0dsuA7UzfequF5_QM2YYvQ",
            "id": videoId,
        ]

        if let response = syncHttpRequestForJson(url: apiUrl!, method: .get, parameters: parameters) {
            switch response.result {
            case let .success(value):
                let json = JSON(value)
                let ptDuration = json["items"][0]["contentDetails"]["duration"].string
                return ptDuration?.convertYoutubeDurationToSec()
            case let .failure(error):
                print(error)
            }
        }
        return nil
    }

    // this gets the streaming information (URL's, quality,...)
    func getStreamingDetails(_ id: String) -> String? {

        let targetUrl = "https://www.youtube.com/get_video_info"
        let parameters: [String: Any] = ["video_id": id]

        if let response = syncHttpRequestForString(url: targetUrl, method: .get, parameters: parameters) {
            return response.result.value
        }
        return nil
    }

    func prepareForDownload(fileName: String) -> URL {
        // create and return an URL at wich to persist the file
        let tmpFolder = NSTemporaryDirectory()
        let fileUrl = URL(fileURLWithPath: tmpFolder.appending(fileName))
        print("*** file: \(String(describing: fileUrl))")
        return fileUrl
    }

    func downloadFile(fromUrl: URL, to localUrl: URL, completion: @escaping (Any?) -> Void) {

        // won't attempt to download if  already exists
        if VideoManager.fileExists(url: localUrl) {
            delegate?.didCompleteRequestforFile(response: "SUCCESS", localUrl: localUrl)
            completion(nil)
            return
        }

        let session = URLSession.shared
        let request = URLRequest(url: fromUrl)

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if !(error != nil) {
                // print this print to console for debugging
                // let string = NSString(data: data!, encoding: 0)
                print("*** downloading...")
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("*** Stauts code \(httpResponse.statusCode)")

                DispatchQueue.main.async {

                    if httpResponse.statusCode == 200 {
                        self.saveVideo(filePath: localUrl, data: data!)
                        self.delegate?.didCompleteRequestforFile(response: "SUCCESS", localUrl: localUrl)
                    } else {
                        self.delegate?.didCompleteRequestforFile(response: "FAILURE", localUrl: localUrl)
                    }
                }
            }

            // do whatever the caller expects upon completion
            completion(nil)
        })
        task.resume()
    }

    func saveVideo(filePath: URL, data: Data) {
        do {
            try data.write(to: filePath, options: .atomicWrite)
            print("*** file saved at: \(filePath)")
        } catch {
            print("*** saving video file failed : \(error)")
        }
    }

    func syncHttpRequestForString(url: String, method _: HTTPMethod, parameters: [String: Any]?) -> DataResponse<String>? {
        return Alamofire.request(url, parameters: parameters)
            .validate(statusCode: 200 ..< 300)
            .responseString()
    }

    func syncHttpRequestForJson(url: String, method _: HTTPMethod, parameters: [String: Any]?) -> DataResponse<Any>? {
        return Alamofire.request(url, parameters: parameters)
            .validate(statusCode: 200 ..< 300)
            .responseJSON()
    }

    func asyncHttpRequest(url: String, method: HTTPMethod, parameters: [String: Any]?, completionHandler: @escaping ResponseHandler) {
        Alamofire.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .validate(statusCode: 200 ..< 300)
            .responseJSON(completionHandler: completionHandler)
    }
}

extension String {
    func convertYoutubeDurationToSec() -> Int {

        // hours, min, sec
        var time = (0, 0, 0)

        let formattedDuration = replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: ":")
            .replacingOccurrences(of: "M", with: ":")
            .replacingOccurrences(of: "S", with: "")

        let components = formattedDuration.components(separatedBy: ":")
        switch components.count {
        case 1:
            time.2 = Int(components[0])!
        case 2:
            time.2 = Int(components[1])!
            time.1 = Int(components[0])!
        default:
            time.2 = Int(components[2])!
            time.1 = Int(components[1])!
            time.0 = Int(components[0])!
        }

        let durationSec = ((time.0 * 3600) + (time.1 * 60) + time.2)
        return durationSec
    }
}
