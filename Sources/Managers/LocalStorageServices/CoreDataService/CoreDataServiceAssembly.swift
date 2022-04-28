//
//  CoreDataServiceAssembly.swift
//  
//
//  Created by Арман Чархчян on 25.04.2022.
//

import Foundation
import Swinject

public enum CoreDataServiceAssembly {

    private enum FileNames: String {
        case model = "Model"
    }
    
    private enum FileExtensions: String {
        case model = ".momd"
    }
    
    public static func assemble(container: Container) {
        container.register(CoreDataServiceProtocol.self) { r in
            CoreDataService(info: .package(fileName: FileNames.model.rawValue,
                                           fileExtension: FileExtensions.model.rawValue))
        }
    }
}
