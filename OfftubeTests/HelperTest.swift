//
//  HelperTest.swift
//  Offtube
//
//  Created by Dirk Gerretz on 24.07.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import XCTest

@testable import Offtube

class HelperTest: BaseTest {

    func test_InjectFileToFolder() {
        let url = Helper.injectFileToTmpFolder(prefix: "ucZl6vQ_8Uo", suffix: "jpg")
        XCTAssertTrue(VideoManager.fileExists(url: url!), "Injected file doesn't exist")
    }
}
