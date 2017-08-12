//
//  MainViewModelTest.swift
//  Offtube
//
//  Created by Dirk Gerretz on 15.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import XCTest

@testable import Offtube

class MainViewModelTest: BaseTest {

    // MARK: Properties
    var expectationDelegate: XCTestExpectation?

    // MARK: Setup
    override func setUp() {
        super.setUp()
        model.manager.ytClient.delegate = self
    }

    // MARK: Tests
    func test_RequestVideo() {
        let targetUrl = "https://www.youtube.com/watch?v=ucZl6vQ_8Uo"

        XCTAssertNotNil(model.manager, "Model has no VideoManager")

        let initalCountModel = model.videos?.count
        model.requestVideo(url: targetUrl)
        XCTAssertTrue(model.videos?.count == (initalCountModel! + 1), "Video count is incorrect")
    }

    func test_GetImageAtWebUrl() {
        let url = URL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")
        let image = model.downloadImageAt(url!)
        XCTAssertNotNil(image, "Image should not be nil")
    }

    func test_GetImageAtLocalUrl() {
        let url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        let image = model.downloadImageAt(url!)
        XCTAssertNotNil(image, "Image should not be nil")
    }

    func test_DefaultImage() {
        let url = URL(string: "https://www.gerretz.de")
        let image = model.downloadImageAt(url!)
        XCTAssertNotNil(image, "Image should not be nil")
    }

    func test_getVideoFromId() {
        var video = model.searchArrayForVideoBy(id: "ucZl6vQ_8Uo")
        XCTAssertNil(video, "Video should be nil")

        let targetUrl = "https://www.youtube.com/watch?v=ucZl6vQ_8Uo"
        model.requestVideo(url: targetUrl)

        video = model.searchArrayForVideoBy(id: "ucZl6vQ_8Uo")
        XCTAssertNotNil(video, "Video should not be nil")
    }

    func test_numberOfRowsInSection() {

        guard let sut = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MainViewController") as? MainViewController
        else {
            XCTFail("Could not instantiate vc from Main storyboard")
            return
        }
        _ = sut.view

        XCTAssertNotNil(sut.searchBar, "SearchBar is nil")
        XCTAssertNotNil(sut.model, "Model is nil")
        XCTAssertTrue(sut.model.videos?.count == 0, "Incorrect count of videos in arrray")
        XCTAssertNotNil(sut.tableView, "TableView is nil")
        XCTAssertTrue(sut.tableView.numberOfSections == 1, "TableView shows incorrect number of sections")
        XCTAssertTrue(sut.tableView.numberOfRows(inSection: 0) == 0, "TableView shows incorrect number of rwos in sections 0")

        let targetUrl = "https://www.youtube.com/watch?v=ucZl6vQ_8Uo"
        sut.model.requestVideo(url: targetUrl)

        XCTAssertTrue(sut.model.videos?.count == 1, "Incorrect count of videos in arrray")
        XCTAssertTrue(sut.tableView.numberOfRows(inSection: 0) == 1, "TableView shows incorrect number of rwos in sections 0")
    }

    func test_DeleteAllVideos() {
        XCTAssertNotNil(model.manager, "Model has no VideoManager")
        XCTAssertTrue(model.videos?.count == 0, "Video count should be 0")

        let targetUrl = "https://www.youtube.com/watch?v=ucZl6vQ_8Uo"
        model.requestVideo(url: targetUrl)
        model.requestVideo(url: targetUrl)
        XCTAssertTrue(model.videos?.count == 2, "Video count should be 2")

        model.deleteAllVideos()
        XCTAssertTrue(model.videos?.count == 0, "Video count should be 0")
    }

    func test_DeleteVideo() {
        XCTAssertNotNil(model.manager, "Model has no VideoManager")
        XCTAssertTrue(model.videos?.count == 0, "Video count should be 0")

        let targetUrl = "https://www.youtube.com/watch?v=ucZl6vQ_8Uo"
        model.requestVideo(url: targetUrl)
        XCTAssertTrue(model.videos?.count == 1, "Video count should be 1")

        if let video = model.videos?.first {
            model.delete(video: video)
            XCTAssertTrue(model.videos?.count == 0, "Video count should be 0")
        }
    }

    func test_FetchVideos() {
        model.videos = nil
        XCTAssertNil(model.videos, "Videos should be nil")
        model.videos = model.fetchVideos()
        XCTAssertNotNil(model.videos, "Videos should not be nil")
    }

    func test_UpdateDownloadStatus() {
        let video = Helper.createVideoObject()
        XCTAssertTrue(video.downloadComplete, "Download status should be true")

        model.updateDownloadStatus(video: video)
        XCTAssertFalse(video.downloadComplete, "Download status should be false")

        _ = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "mp4")
        model.updateDownloadStatus(video: video)
        XCTAssertTrue(video.downloadComplete, "Download status should be true")
    }

    func test_reloadVideo() {
        expectationDelegate = expectation(description: "re-download video")
        let video = Helper.createVideoObject()
        video.downloadComplete = false
        model.videos!.append(video)

        model.reloadVideo(index: 0)

        waitForExpectations(timeout: 15, handler: { _ in
            let url = URL(string: NSTemporaryDirectory().appending("ucZl6vQ_8Uo.mp4"))
            XCTAssertTrue(VideoManager.fileExists(url: url!), "Video not found at URL")
            for video in self.model.videos! {
                if video.id == "ucZl6vQ_8Uo" {
                    XCTAssert(true, "Didn't find video in videos array")
                }
            }
        })
    }

    func test_fomrattedTimeString() {
        var timeString = model.timeStringFromSeonds(Int64(31))
        XCTAssertTrue(timeString == "00:00:31", "Incorrect time fomrat: \(timeString)")

        timeString = model.timeStringFromSeonds(Int64(64))
        XCTAssertTrue(timeString == "00:01:04", "Incorrect time fomrat: \(timeString)")

        timeString = model.timeStringFromSeonds(Int64(10951))
        XCTAssertTrue(timeString == "03:02:31", "Incorrect time fomrat: \(timeString)")
    }

    func test_deleteVideoOnFailure() {
        let video = Helper.createVideoObject()
        model.videos?.append(video)
        let url = URL(string: video.fileLocation!)
        XCTAssertTrue(model.videos?.count == 1, "Videos count should be 1")
        model.didCompleteRequestforFile(response: "FAILURE", localUrl: url!)
        XCTAssertTrue(model.videos?.count == 0, "Videos count should be 0")
    }
}

extension MainViewModelTest: YoutubeClientProtocol {

    func didCompleteRequestforFile(response _: String, localUrl: URL) {
        if localUrl.absoluteString.hasSuffix(".mp4") {
            expectationDelegate?.fulfill()
        }
    }
}
