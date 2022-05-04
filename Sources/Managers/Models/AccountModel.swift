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
    public var profile: ProfileModelProtocol

    public init(profile: ProfileModelProtocol,
                blockedIDs: Set<String>) {
        self.profile = profile
        self.blockedIds = blockedIDs
    }
    
    public init?(account: Account?) {
        guard let account = account,
              let profile = account.profile,
              let profile = ProfileModel(profile: profile) else { return nil }
        self.blockedIds = account.blockedIDs ?? []
        self.profile = profile
    }
}
