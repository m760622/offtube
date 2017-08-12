//
//  Video+CoreDataProperties.swift
//
//
//  Created by Dirk Gerretz on 30.07.17.
//
//

import Foundation
import CoreData

extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var details: String?
    @NSManaged public var downloadComplete: Bool
    @NSManaged public var duration: Int64
    @NSManaged public var fileLocation: String?
    @NSManaged public var id: String?
    @NSManaged public var streamingUrl: String?
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var timePlayed: Double
    @NSManaged public var timeRemaining: Double
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var youtubeUrl: String?
}
