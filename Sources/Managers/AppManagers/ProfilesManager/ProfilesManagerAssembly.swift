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
        container.register(ProfilesManagerProtocol.self) { r in
            guard let profilesService = r.resolve(ProfilesServiceProtocol.self) else { fatalError(ErrorMessage.dependency.localizedDescription) }
            return ProfilesManager(profileService: profilesService)
        }
    }
}
