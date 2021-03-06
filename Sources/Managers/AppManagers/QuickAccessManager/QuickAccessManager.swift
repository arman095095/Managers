
import Services

public protocol QuickAccessManagerProtocol: AnyObject {
    var userID: String? { get set }
    func clearAll()
}

final class QuickAccessManager {
    private let keychainService: KeychainServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    
    init(keychainService: KeychainServiceProtocol,
         userDefaultsService: UserDefaultsServiceProtocol) {
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
    }
}

extension QuickAccessManager: QuickAccessManagerProtocol {
    
    public var userID: String? {
        get {
            guard userRemembered else { return nil }
            guard case let .success(data) = keychainService.getData(for: .userID) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            guard let newValue = newValue else {
                userRemembered = false
                keychainService.removeItem(.userID)
                return
            }
            guard let data = newValue.data(using: .utf8) else { return }
            keychainService.store(data: data, for: .userID)
            userRemembered = true
        }
    }
    
    public func clearAll() {
        keychainService.clear()
        userDefaultsService.clear()
    }
}

private extension QuickAccessManager {
    
    var userRemembered: Bool {
        get {
            userDefaultsService.getData(item: .userRemembered) as? Bool ?? false
        }
        set {
            userDefaultsService.store(newValue, item: .userRemembered)
        }
    }
    
    func clearSecurityStorage() {
        keychainService.clear()
    }
    
    func clearUserSettings() {
        userDefaultsService.clear()
    }
}
