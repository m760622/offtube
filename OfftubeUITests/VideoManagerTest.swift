//
//  VideoManagerTest.swift
//  Offtube
//
//  Created by Dirk Gerretz on 04.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import XCTest
import YouTubeGetVideoInfoAPIParser

@testable import Offtube

class VideoManagerTest: BaseTest {

    var expectationDelegate: XCTestExpectation?
    let targetId = "ucZl6vQ_8Uo"
    let regularUrl = URL(string: "https://www.youtube.com/watch?v=ucZl6vQ_8Uo")
    let shortUrl = URL(string: "https://youtu.be/ucZl6vQ_8Uo")
    let manager = VideoManager()
    let ytClient = YoutubeClient(apiUrl: "https://www.googleapis.com/youtube/v3/videos")

    override func setUp() {
        super.setUp()
        manager.delegate = self
    }

    func test_RetrieveStreamingUrl() {
        let target = (manager.convertVideoInfo(info: Helper.rawVideoInfoPositivePath))
        XCTAssertTrue(((target?.url.absoluteString)?.characters.count)! > 10, "URL doesn't appear valid")
        XCTAssertTrue(((target?.type)?.contains("video/mp4"))!, "Type doesn't appear valid")
    }

    func test_NoStreamingUrlAvailable() {
        let target = (manager.convertVideoInfo(info: Helper.rawVideoInfoNegativePath))
        XCTAssertNil(target, "Target should be nil")
    }

    func test_IdFromUrl() {
        // test short URL
        var id = VideoManager.idFromUrl(url: shortUrl!)
        XCTAssertTrue(id == targetId, "Returned ID doen't appear valid")

        // test regular URL
        id = VideoManager.idFromUrl(url: regularUrl!)
        XCTAssertTrue(id == targetId, "Returned ID doen't appear valid")
    }

    func test_IdFromRegularUrl() {
        let id = VideoManager.idFromRegularUrl(url: regularUrl!)
        XCTAssertTrue(id == targetId, "ID doesn't match target ID")
    }

    func test_IdFromShortUrl() {
        let id = VideoManager.idFromShortUrl(url: shortUrl!)
        XCTAssertTrue(id == targetId, "ID doesn't match target ID")
    }

    func test_VideoValues() {
        let video = manager.video(url: regularUrl!)
        XCTAssertNotNil(video?.title, "Video seems to have no title")
        XCTAssertNotNil(video?.id, "Video seems to have no ID")
        XCTAssertNotNil(video?.streamingUrl, "Streaming URL is nil")
        XCTAssertNotNil(video?.duration, "Video seems to have no duration")
        XCTAssertNotNil(video?.timeRemaining, "Time remaining is nil")
        XCTAssertTrue(video?.timeRemaining == 0.0, "Time remaining is not 0.0")
        XCTAssertNotNil(video?.timePlayed, "Time played is nil")
        XCTAssertTrue(video?.timePlayed == 0.0, "Time played is not 0.0")
        XCTAssertNotNil(video?.youtubeUrl, "Youtube URL is nil")
        XCTAssertNotNil(video?.fileLocation, "File location is nil")
        XCTAssertNotNil(video?.type, "Video seems to have no type")
        XCTAssertNotNil(video?.thumbnailUrl, "Thumbnail location is nil")
        XCTAssertNotNil(video?.details, "Video seems to have no description")
        XCTAssertFalse((video?.downloadComplete)!, "'Download Complete' shoulb be False but is True")
    }

    func test_FetchVideo() {
        let model = MainViewModel()
        let videos = model.fetchVideos()
        XCTAssertNotNil(videos)
    }

    func test_GetDocsFolder() {
        let tmpFolder = NSTemporaryDirectory()
        XCTAssertNotNil(tmpFolder, "URL is nil")
        XCTAssertTrue(tmpFolder.hasSuffix("/tmp/"), "function return wrong folder")
    }

    func test_ClearTmpFolder() {
        var url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")

        url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "mp4")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")
        let tmpFolder = NSTemporaryDirectory()
        VideoManager.clearTmpFolder()

        do {
            let filePaths = try (FileManager.default).contentsOfDirectory(atPath: tmpFolder)
            XCTAssertTrue(filePaths.count == 0, "File count should be zero")
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_DeleteSingleFile() {
        let url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")

        VideoManager.delete(file: (url?.absoluteString)!)
        XCTAssertFalse(VideoManager.fileExists(url: url!), "File still exists")
    }

    func test_FileExists() {
        let url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")
        VideoManager.delete(file: (url?.absoluteString)!)
        XCTAssertFalse(VideoManager.fileExists(url: url!), "Injected file shouldn't exist")
    }

    func test_Delegate() {
        expectationDelegate = expectation(description: "Call delegate")
        noCompatibleVideoFound("Test Message")

        waitForExpectations(timeout: 3, handler: {
            _ in
            XCTAssert(true, "Delegate method was not hit")
        })
    }

    func test_secondsToHoursMinutesSeconds() {
        var formatedTime = VideoManager.secondsToHoursMinutesSeconds(seconds: 10951)
        XCTAssertTrue(formatedTime == (3, 2, 31), "Fomrated time incorrect")

        formatedTime = VideoManager.secondsToHoursMinutesSeconds(seconds: 64)
        XCTAssertTrue(formatedTime == (0, 1, 4), "Fomrated time incorrect")

        formatedTime = VideoManager.secondsToHoursMinutesSeconds(seconds: 31)
        XCTAssertTrue(formatedTime == (0, 0, 31), "Fomrated time incorrect")
    }
}

extension VideoManagerTest: VideoManagerProtocol {
    func noCompatibleVideoFound(_: String) {
        expectationDelegate?.fulfill()
    }
}
