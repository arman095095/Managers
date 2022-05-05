//
//  File.swift
//  
//
//  Created by Арман Чархчян on 29.04.2022.
//

import Foundation
import Swinject

public final class ManagersAssembly: Assembly {
    
    public init() { }
    
    public func assemble(container: Container) {
        KeychainServiceAssembly().assemble(container: container)
        UserDefaultsServiceAssembly().assemble(container: container)
        CoreDataServiceAssembly().assemble(container: container)
        AccountCacheServiceAssembly().assemble(container: container)
        QuickAccessManagerAssembly().assemble(container: container)
        AuthManagerAssembly().assemble(container: container)
        AccountManagerAssembly().assemble(container: container)
        ProfilesManagerAssembly().assemble(container: container)
        PostsManagerAssembly().assemble(container: container)
    }
}
