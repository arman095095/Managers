//
//  AccountModel.swift
//  
//
//  Created by Арман Чархчян on 16.04.2022.
//

import Foundation
import ModelInterfaces

public final class AccountModel: AccountModelProtocol {
    public var blockedIds: Set<String>
    public var friendIds: Set<String>
    public var requestIds: Set<String>
    public var waitingsIds: Set<String>
    public var profile: ProfileModelProtocol

    public init(profile: ProfileModelProtocol,
                blockedIDs: Set<String>,
                friendIds: Set<String>,
                waitingsIds: Set<String>,
                requestIds: Set<String>) {
        self.profile = profile
        self.blockedIds = blockedIDs
        self.requestIds = requestIds
        self.friendIds = friendIds
        self.waitingsIds = waitingsIds
    }
    
    public init?(account: Account?) {
        guard let account = account,
              let profile = account.profile,
              let profile = ProfileModel(profile: profile) else { return nil }
        self.blockedIds = account.blockedIDs ?? []
        self.waitingsIds = account.waitingsIDs ?? []
        self.requestIds = account.requestIDs ?? []
        self.friendIds = account.friendIDs ?? []
        self.profile = profile
    }
}
