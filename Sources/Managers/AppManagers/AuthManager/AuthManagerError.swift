//
//  File.swift
//  
//
//  Created by Арман Чархчян on 16.04.2022.
//

import Foundation

public enum AuthManagerError: LocalizedError {
    
    case another(error: Error)
    case profile(value: Profile)
    
    public enum Profile {
        case emptyProfile
    }
    
    public var errorDescription: String? {
        switch self {
        case .another(let error):
            return error.localizedDescription
        case .profile(let value):
            switch value {
            case .emptyProfile:
                return "Ошибка получения данных"
            }
        }
    }
}
