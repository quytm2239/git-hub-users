//
//  LRemoteImage.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation
import CoreData

@objc(LRemoteImage)
public class LRemoteImage: NSManagedObject {

}

extension LRemoteImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LRemoteImage> {
        return NSFetchRequest<LRemoteImage>(entityName: "RemoteImage")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var img_data: Data?
    @NSManaged public var img_url: String?
    @NSManaged public var user_id: Int64

}

extension LRemoteImage : Identifiable {

}
