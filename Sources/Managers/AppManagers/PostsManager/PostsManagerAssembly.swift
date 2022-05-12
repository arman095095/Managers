//
//  File.swift
//  
//
//  Created by Арман Чархчян on 02.05.2022.
//

import Foundation
import Swinject
import NetworkServices

public final class PostsManagerAssembly: Assembly {
    
    public init() { }
    
    public func assemble(container: Container) {
        container.register(PostsManagerProtocol.self) { r in
            guard let remoteStorage = r.resolve(RemoteStorageServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self),
                  let postsServices = r.resolve(PostsServiceProtocol.self),
                  let accountID = quickAccessManager.userID else { fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return PostsManager(accountID: accountID,
                                postsService: postsServices,
                                remoteStorage: remoteStorage,
                                profilesService: profileService)
        }.inObjectScope(.weak)
    }
}
