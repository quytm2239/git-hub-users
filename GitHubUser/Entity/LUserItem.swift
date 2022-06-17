//
//  LUserItem.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation
import CoreData

public class LUserItem: NSManagedObject {

}

extension LUserItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LUserItem> {
        return NSFetchRequest<LUserItem>(entityName: "UserItem")
    }

    @NSManaged public var userId: Int64
    @NSManaged public var login: String?
    @NSManaged public var avatarUrl: String?
    @NSManaged public var type: String?
    @NSManaged public var siteAdmin: Bool
    
    @NSManaged public var name: String?
    @NSManaged public var bio: String?
    @NSManaged public var company: String?
    @NSManaged public var email: String?
    @NSManaged public var twitterUsername: String?

    @NSManaged public var followers: Int32
    @NSManaged public var following: Int32
    
    @NSManaged public var isProfileLoaded: Bool
    @NSManaged public var note: String?

    @NSManaged public var blog: String?
    @NSManaged public var repoUrl: String?

    @NSManaged public var updatedAt: Double
    @NSManaged public var createdAt: Double
    @NSManaged public var isSeen: Bool

}

extension LUserItem : Identifiable {

}

extension LUserItem {
    static let maxNoteLength = 300
    func updateFully(with data: RUserItem) {
        self.login = data.login
        self.userId = data.userId
        self.avatarUrl = data.avatarUrl
        self.type = data.type
        self.siteAdmin = data.siteAdmin ?? false
        
        self.name = data.name
        self.bio = data.bio
        self.company = data.company
        self.email = data.email
        self.twitterUsername = data.twitterUsername

        self.followers = data.followers ?? 0
        self.following = data.following ?? 0
        
        self.blog = data.blog
        self.repoUrl = data.reposUrl
        
        self.isSeen = data.isSeen
        self.isProfileLoaded = data.isProfileLoaded
    }
    
    func updateAsListItem(with data: RUserItem) {
        self.login = data.login
        self.userId = data.userId
        self.avatarUrl = data.avatarUrl
        self.type = data.type
        self.siteAdmin = data.siteAdmin ?? false
    }
    
    static func isValidNoteLength(_ value: String) -> Bool {
        return value.count <= maxNoteLength
    }
}
