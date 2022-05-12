//
//  File.swift
//  
//
//  Created by Арман Чархчян on 06.05.2022.
//

import Foundation
import Swinject
import ModelInterfaces
import NetworkServices
import Services

public final class CommunicationManagerAssembly: Assembly {
    public init() { }
    public func assemble(container: Container) {
        container.register(InitialCommunicationManagerProtocol.self) { r in
            guard let accountService = r.resolve(AccountServiceProtocol.self),
                  let requestsService = r.resolve(RequestsServiceProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let cacheService = r.resolve(CommunicationCacheServiceProtocol.self),
                  let accountID = quickAccessManager.userID,
                  let account = r.resolve(AccountModelProtocol.self) else { fatalError(ErrorMessage.dependency.localizedDescription)
                
            }
            return CommunicationManager(accountID: accountID,
                                        account: account,
                                        accountService: accountService,
                                        cacheService: cacheService,
                                        profileService: profileService,
                                        requestsService: requestsService)
        }.implements(BlockingManagerProtocol.self,
                     ProfileStateDeterminator.self,
                     ChatsAndRequestsManagerProtocol.self).inObjectScope(.weak)
    }
}
