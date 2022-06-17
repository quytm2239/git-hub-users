//
//  RUserItem.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import Foundation

protocol IUserProfileDisplayData {
    func getName() -> String
    func getNote() -> String
    func getFollowers() -> String
    func getFollowing() -> String
    func getSummary() -> String
    func getAvatarUrl() -> String?
}

class RUserItem : Codable {
    var login : String = ""
    var userId : Int64 = 0
    var avatarUrl : String?
    var type : String?
    var siteAdmin : Bool?
    
    var name : String?
    var email : String?
    var company : String?
    var blog : String?
    var bio : String?
    var twitterUsername : String?
    
    var followers : Int32?
    var following : Int32?
    
    var location : String?
    var hireable : Bool?
    var htmlUrl : String?
    var reposUrl : String?
    var createdAt : String?
    var updatedAt : String?
            
    init() {}
    
    // customized field for Note in profile
    var note = ""
    var isSeen = false
    var isProfileLoaded = false
    
    var avatarUrlToLoad: String? {
        guard let needLoadImgUrl = self.avatarUrl, !needLoadImgUrl.isEmpty else  { return nil }
        return needLoadImgUrl
    }

    enum CodingKeys: String, CodingKey {
        case login = "login"
        case userId = "id"
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case reposUrl = "repos_url"
        case type = "type"
        case siteAdmin = "site_admin"
        case name = "name"
        case company = "company"
        case blog = "blog"
        case location = "location"
        case email = "email"
        case hireable = "hireable"
        case bio = "bio"
        case twitterUsername = "twitter_username"
        case followers = "followers"
        case following = "following"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        login = try values.decode(String.self, forKey: .login)
        userId = try values.decode(Int64.self, forKey: .userId)
        avatarUrl = try values.decodeIfPresent(String.self, forKey: .avatarUrl)
        htmlUrl = try values.decodeIfPresent(String.self, forKey: .htmlUrl)
        reposUrl = try values.decodeIfPresent(String.self, forKey: .reposUrl)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        siteAdmin = try values.decodeIfPresent(Bool.self, forKey: .siteAdmin)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        company = try values.decodeIfPresent(String.self, forKey: .company)
        blog = try values.decodeIfPresent(String.self, forKey: .blog)
        location = try values.decodeIfPresent(String.self, forKey: .location)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        hireable = try values.decodeIfPresent(Bool.self, forKey: .hireable)
        bio = try values.decodeIfPresent(String.self, forKey: .bio)
        twitterUsername = try values.decodeIfPresent(String.self, forKey: .twitterUsername)
        followers = try values.decodeIfPresent(Int32.self, forKey: .followers)
        following = try values.decodeIfPresent(Int32.self, forKey: .following)
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try values.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

extension RUserItem {
    static func build(with lUser: LUserItem) -> RUserItem {
        let user = RUserItem()
        user.userId = lUser.userId
        user.login = lUser.login ?? ""
        user.avatarUrl = lUser.avatarUrl
        user.type = lUser.type
        user.siteAdmin = lUser.siteAdmin
        
        user.name = lUser.name
        user.email = lUser.email
        user.company = lUser.company
        user.blog = lUser.blog
        user.bio = lUser.bio
        user.twitterUsername = lUser.twitterUsername

        user.following = lUser.following
        user.followers = lUser.followers
        
        user.note = lUser.note ?? ""
        user.isSeen = lUser.isSeen
        user.isProfileLoaded = lUser.isProfileLoaded
        
        return user
    }
    
    func update(remote item: RUserItem) {
        self.userId = item.userId
        self.login = item.login
        self.avatarUrl = item.avatarUrl
        self.type = item.type
        self.siteAdmin = item.siteAdmin
        
        self.name = item.name
        self.email = item.email
        self.company = item.company
        self.blog = item.blog
        self.bio = item.bio
        self.twitterUsername = item.twitterUsername

        self.following = item.following
        self.followers = item.followers
    }
}

extension RUserItem: IUserProfileDisplayData {
    func getName() -> String {
        return self.name ?? self.login
    }
    
    func getNote() -> String {
        return self.note
    }
    
    func getFollowers() -> String {
        return Formatter.formatNumber(Double(self.followers ?? 0), maxFrac: 0)
    }
    
    func getFollowing() -> String {
        return Formatter.formatNumber(Double(self.following ?? 0), maxFrac: 0)
    }
    
    func getSummary() -> String {
        let breakLine = "\n"
        let head = "Name: \(self.name ?? "--")"
        let summary = head
            .appending(breakLine).appending("Bio: \(self.bio ?? "--")")
            .appending(breakLine).appending("Company: \(self.company ?? "--")")
            .appending(breakLine).appending("Blog: \(self.blog ?? "--")")
            .appending(breakLine).appending("Type: \(self.type ?? "--")")
            .appending(breakLine).appending("Is site admin? \(self.siteAdmin ?? false ? "Yes" : "No" )")
            .appending(breakLine).appending("Type: \(self.type ?? "--")")
            .appending(breakLine).appending("Email: \(self.email ?? "--")")
            .appending(breakLine).appending("Twitter: \(self.twitterUsername ?? "--")")

        return summary
    }
    
    func getAvatarUrl() -> String? {
        return self.avatarUrlToLoad
    }
}
