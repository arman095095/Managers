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
    
    public enum Block: LocalizedError {
        case cantBlock
        case cantUnblock
        public var errorDescription: String? {
            switch self {
            case .cantBlock:
                return "Не удалось заблокировать пользователя"
            case .cantUnblock:
                return "Не удалось разблокировать пользователя"
            }
        }
    }
    
    public enum Remove: LocalizedError {
        case cantRemove
        case cantRecover
        public var errorDescription: String? {
            switch self {
            case .cantRemove:
                return "Ошибка при попытке удалить профиль"
            case .cantRecover:
                return "Ошибка при попытке восстановления профиля"
            }
        }
    }
    
    public enum Profile: LocalizedError {
        case emptyProfile
        case profileRemoved
        case another(error: Error)
        public var errorDescription: String? {
            switch self {
            case .emptyProfile:
                return "Ошибка получения данных"
            case .profileRemoved:
                return "Вы удалили профиль"
            case .another(error: let error):
                return error.localizedDescription
            }
        }
    }
}

