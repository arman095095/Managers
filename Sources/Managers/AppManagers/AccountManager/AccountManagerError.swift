//
//  File.swift
//  
//
//  Created by Арман Чархчян on 26.04.2022.
//

import Foundation

public enum AccountManagerError: LocalizedError {
    
    case another(error: Error)
    case profile(value: Profile)
    case remove(value: Remove)
    case blocking(value: Block)
    
    public enum Block {
        case cantBlock
        case cantUnblock
    }
    
    public enum Remove {
        case cantRemove
    }
    
    public enum Profile {
        case emptyProfile
        case profileRemoved
    }
    
    public var errorDescription: String? {
        switch self {
        case .another(let error):
            return error.localizedDescription
        case .profile(let value):
            switch value {
            case .emptyProfile:
                return "Ошибка получения данных"
            case .profileRemoved:
                return "Вы удалили профиль"
            }
        case .remove(value: let value):
            switch value {
            case .cantRemove:
                return "Ошибка при попытке удалить профиль"
            }
        case .blocking(value: let value):
            switch value {
            case .cantBlock:
                return "Не удалось заблокировать пользователя"
            case .cantUnblock:
                return "Не удалось разблокировать пользователя"
            }
        }
    }
}
