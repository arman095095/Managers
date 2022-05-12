//
//  ProfilesManagerAssembly.swift
//  
//
//  Created by Арман Чархчян on 22.04.2022.
//

import Foundation
import Swinject
import NetworkServices

public final class ProfilesManagerAssembly: Assembly {
    
    public init() { }
    
    public func assemble(container: Container) {
        container.register(UsersManagerProtocol.self) { r in
            guard let profilesService = r.resolve(ProfilesServiceProtocol.self), let userID = r.resolve(QuickAccessManagerProtocol.self)?.userID else { fatalError(ErrorMessage.dependency.localizedDescription) }
            return ProfilesManager(accountID: userID, profileService: profilesService)
        }.implements(ProfileInfoManagerProtocol.self).inObjectScope(.weak)
    }
}
