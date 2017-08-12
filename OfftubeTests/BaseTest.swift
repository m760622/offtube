//
//  BaseTest.swift
//  Offtube
//
//  Created by Dirk Gerretz on 25.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import XCTest
@testable import Offtube

class BaseTest: XCTestCase {

    let model = MainViewModel()

    override func setUp() {
        super.setUp()
        model.deleteAllVideos()
    }

    override func tearDown() {
        model.deleteAllVideos()
        super.tearDown()
    }
}
