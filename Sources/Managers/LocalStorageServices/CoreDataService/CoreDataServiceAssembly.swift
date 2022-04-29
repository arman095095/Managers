//
//  CoreDataServiceAssembly.swift
//  
//
//  Created by Арман Чархчян on 25.04.2022.
//

import Foundation
import Swinject

public final class CoreDataServiceAssembly: Assembly {

    private enum FileNames: String {
        case model = "Model"
    }
    
    private enum FileExtensions: String {
        case model = ".momd"
    }
    
    public init() { }
    
    public func assemble(container: Container) {
        container.register(CoreDataServiceProtocol.self) { r in
            CoreDataService(info: .package(fileName: FileNames.model.rawValue,
                                           fileExtension: FileExtensions.model.rawValue))
        }
    }
}
