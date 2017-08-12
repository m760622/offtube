//
//  YoutubeClientTest.swift
//  Garage-LatestTests
//
//  Created by Dirk Gerretz on 16.04.17.
//  Copyright © 2017 [code2app];. All rights reserved.
//

import XCTest
import Alamofire
import Alamofire_Synchronous

@testable import Offtube

class YoutubeClientTest: BaseTest {

    var expectationDelegate: XCTestExpectation?
    var didCompleteRequestforFileWasCalled = false
    var didCompleteRequestForVideoDetailsWasCalled = false
    let defaultTimeout: TimeInterval = 5.0
    let ytClient = YoutubeClient(apiUrl: "https://www.googleapis.com/youtube/v3/videos")
    let manager = VideoManager()
    let targetId = "ucZl6vQ_8Uo"
    let targetUrl = URL(string: "https://www.youtube.com/watch?v=ucZl6vQ_8Uo")
    let shortTargetUrl = URL(string: "https://youtu.be/ucZl6vQ_8Uo")
    var json: Dictionary<String, Any>?

    override func setUp() {
        didCompleteRequestforFileWasCalled = false
        didCompleteRequestForVideoDetailsWasCalled = false
        json = nil
        ytClient.delegate = self
    }

    func test_GetVideoDetails() {
        let title = "Audio Video Sync Test"
        let description = "YouTube audio is late on a few platforms/computers we tested.\nPlease let us know how the sync is for you using our video utility! More Apple Juice Coming Soon! Thanks!  DJO\n\nVideo Details:\n30 FPS, AVC Main Concept compression, 44.1 Khz Audio."
        let url = "https://i.ytimg.com/vi/ucZl6vQ_8Uo/default.jpg"

        let details = ytClient.getVideoDetails(videoId: targetId)
        XCTAssert(details?["title"] == title, "incorrect title for video")
        XCTAssert(details?["description"] == description, "incorrect description for video")
        XCTAssert(details?["thumbnailUrl"] == url, "incorrect thumbnail URL for video")
    }

    func test_GetVideoDuration() {
        let duration = ytClient.getVideoDuration(videoId: targetId)
        XCTAssertTrue(duration == 64, "incorrect duration for video")
    }

    func test_GetStreamingDetails() {
        let rawInfo = ytClient.getStreamingDetails(targetId)
        XCTAssertNotNil(rawInfo, "No video details retrieved")
        XCTAssertFalse(rawInfo == "", "No video details retrieved")
        XCTAssertTrue((rawInfo?.characters.count)! > 100, "Retrieved string appears insufficient")
    }

    func test_PrepareDownload() {
        let url = ytClient.prepareForDownload(fileName: "airplane.png")
        XCTAssertTrue((url.absoluteString).contains("/tmp/airplane.png"))
    }

    func test_DownloadVideo() {
        let exp = expectation(description: "download video")
        let video = manager.video(url: targetUrl!)
        let localUrl = ytClient.prepareForDownload(fileName: (targetId + ".mp4"))
        let url = URL(string: (video?.streamingUrl!)!)
        ytClient.downloadFile(fromUrl: url!,
                              to: localUrl,
                              completion: { _ in
                                  exp.fulfill()
        })
        waitForExpectations(timeout: 30, handler: { _ in
            XCTAssertNotNil(localUrl, "File location is nil")
            XCTAssertTrue(VideoManager.fileExists(url: localUrl), "Video not found at URL")
            VideoManager.clearTmpFolder()
        })
    }

    func test_DownloadThumbnailFromUrl() {
        let url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")

        XCTAssertNotNil(url!, "File location is nil")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Thumbnail not found at URL")
        VideoManager.clearTmpFolder()
    }

    func test_AsyncHttpRequest() {
        let exp = expectation(description: "GET httpRequest timed out")
        ytClient.asyncHttpRequest(url: "https://www.google.com", method: .get, parameters: nil) { response in
            XCTAssertTrue(response.response?.statusCode == HTTPStatusCode.OK.rawValue, "Staus code != 200")
            exp.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }

    func test_SyncHttpRequestForString() {
        let targetUrl = "https://www.google.com"
        let response = ytClient.syncHttpRequestForString(url: targetUrl, method: .get, parameters: nil)
        let statusCode = response?.response?.statusCode
        XCTAssertTrue(statusCode == HTTPStatusCode.OK.rawValue, "Staus code != 200")
    }

    func test_SyncHttpRequestForJson() {
        let targetUrl = "https://jsonplaceholder.typicode.com/users"
        let response = ytClient.syncHttpRequestForJson(url: targetUrl, method: .get, parameters: nil)
        let statusCode = response?.response?.statusCode
        XCTAssertTrue(statusCode == HTTPStatusCode.OK.rawValue, "Staus code != 200")
    }

    func test_durationFromYoutubeDurationFormat() {
        XCTAssertTrue("PT3H2M31S".convertYoutubeDurationToSec() == 10951, "Incorrect duration returned")
        XCTAssertTrue("PT1M4S".convertYoutubeDurationToSec() == 64, "Incorrect duration returned")
        XCTAssertTrue("PT31S".convertYoutubeDurationToSec() == 31, "Incorrect duration returned")
    }

    func test_DownloadFileDelgateMethodCalled() {
        expectationDelegate = expectation(description: "Delegate test timeout")

        let url = URL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")
        let localUrl = ytClient.prepareForDownload(fileName: (targetId + ".jpg"))
        ytClient.downloadFile(fromUrl: url!,
                              to: localUrl,
                              completion: { _ in })

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertTrue(didCompleteRequestforFileWasCalled, "delegate method not invoked")
    }

    func test_GetDetailsDelgateMethodCalled() {
        expectationDelegate = expectation(description: "Delegate test timeout")

        let url = URL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")
        let localUrl = ytClient.prepareForDownload(fileName: (targetId + ".jpg"))
        ytClient.downloadFile(fromUrl: url!,
                              to: localUrl,
                              completion: { _ in })

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertTrue(didCompleteRequestforFileWasCalled, "delegate method not invoked")
    }
}

extension YoutubeClientTest: YoutubeClientProtocol {

    // MARK: YoutubeClient Protocol
    func didCompleteRequestforFile(response: String, localUrl: URL) {
        XCTAssertNotNil(localUrl, "URL shouldn't be nil")
        if response == "SUCCESS" { didCompleteRequestforFileWasCalled = true }
        expectationDelegate?.fulfill()
    }
}
