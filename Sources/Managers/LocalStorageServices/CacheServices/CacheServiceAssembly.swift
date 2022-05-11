//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation
import Swinject
import Services

public final class AccountCacheServiceAssembly: Assembly {

    public init() { }
    
    public func assemble(container: Container) {
        container.register(AccountCacheServiceProtocol.self) { r in
            guard let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let accountID = r.resolve(QuickAccessManagerProtocol.self)?.userID else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return CacheService(coreDataService: coreDataService, accountID: accountID)
        }.implements(CommunicationCacheServiceProtocol.self)
    }
}
