
import CoreData

public protocol QuickAccessManagerProtocol: AnyObject {
    var userID: String? { get set }
    var profileRemoved: Bool { get set }
    func clearAll()
}

final public class QuickAccessManager {
    private let keychainService: KeychainServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    
    public init(keychainService: KeychainServiceProtocol,
                userDefaultsService: UserDefaultsServiceProtocol) {
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
    }
}

extension QuickAccessManager: QuickAccessManagerProtocol {
    
    public var profileRemoved: Bool {
        get {
            userDefaultsService.getData(item: .profileRemoved) as? Bool ?? false
        }
        set {
            userDefaultsService.store(newValue, item: .profileRemoved)
        }
    }
    
    public var userID: String? {
        get {
            guard userRemembered, !profileRemoved else { return nil }
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
