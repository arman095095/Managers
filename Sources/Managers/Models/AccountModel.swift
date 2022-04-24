//
//  AccountModel.swift
//  
//
//  Created by Арман Чархчян on 16.04.2022.
//

import Foundation

public protocol AccountModelProtocol: AnyObject {
    var profile: ProfileModelProtocol { get set }
    var blockedIds: Set<String> { get set }
}

public final class AccountModel: AccountModelProtocol {
    public var blockedIds: Set<String>
    public var profile: ProfileModelProtocol
    
    public init(profile: ProfileModelProtocol,
                blockedIDs: Set<String>) {
        self.profile = profile
        self.blockedIds = blockedIDs
    }
}
