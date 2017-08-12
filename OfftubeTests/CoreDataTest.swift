//
//  CoreDataTest.swift
//  Offtube
//
//  Created by Dirk Gerretz on 18.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import XCTest
import CoreData

@testable import Offtube

class CoreDataTest: BaseTest {

    func test_AddObject() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        XCTAssertNotNil(delegate)

        let context = delegate.persistentContainer.viewContext
        XCTAssertNotNil(context)

        let model = MainViewModel()
        var objects: Array<Video>? = model.fetchVideos()
        XCTAssertNotNil(objects)

        let initialCount = model.count(context: context)
        let newVideo = NSEntityDescription.insertNewObject(forEntityName: "Video", into: context) as! Video
        XCTAssertNotNil(newVideo)
        XCTAssertTrue(model.count(context: context) == initialCount + 1, "Unexpected number of objects in context")

        XCTAssertTrue(objects!.count == (model.count(context: context) - 1), "Unexpected number of objects in array")

        objects?.append(newVideo)
        XCTAssertTrue(objects!.count == model.count(context: context), "Unexpected number of objects in array")
    }
}
