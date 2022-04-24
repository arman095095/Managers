//
//  ProfileModel.swift
//  
//
//  Created by Арман Чархчян on 16.04.2022.
//

import Foundation
import NetworkServices

public protocol ProfileModelProtocol {
    var userName: String { get set }
    var info: String { get set }
    var sex: String { get set }
    var imageUrl: String { get set }
    var id: String { get set }
    var country: String { get set }
    var city: String { get set }
    var birthday: String { get set }
    var removed: Bool { get set }
    var online: Bool { get set }
    var lastActivity: Date? { get set }
    var postsCount: Int { get set }
}

public struct ProfileModel: ProfileModelProtocol {
    public var userName: String
    public var info: String
    public var sex: String
    public var imageUrl: String
    public var id: String
    public var country: String
    public var city: String
    public var birthday: String
    public var removed: Bool
    public var online: Bool
    public var lastActivity: Date?
    public var postsCount: Int
    
    init(profile: ProfileNetworkModelProtocol) {
        self.userName = profile.userName
        self.info = profile.info
        self.sex = profile.sex
        self.imageUrl = profile.imageUrl
        self.id = profile.id
        self.country = profile.country
        self.city = profile.city
        self.birthday = profile.birthday
        self.removed = profile.removed
        self.online = profile.online
        self.lastActivity = profile.lastActivity
        self.postsCount = profile.postsCount
    }
}
