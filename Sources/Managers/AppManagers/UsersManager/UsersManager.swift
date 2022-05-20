//
//  File.swift
//  
//
//  Created by Арман Чархчян on 17.04.2022.
//

import Foundation
import NetworkServices
import ModelInterfaces
import Services

public protocol UsersManagerProtocol: AnyObject {
    func getFirstProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void)
    func getNextProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void)
}

public final class UsersManager {
    
    public enum Limits: Int {
        case users = 15
    }
    
    private let accountID: String
    private let profileService: ProfilesNetworkServiceProtocol
    
    public init(accountID: String, profileService: ProfilesNetworkServiceProtocol) {
        self.profileService = profileService
        self.accountID = accountID
    }
}

extension UsersManager: UsersManagerProtocol {
    
    public func getFirstProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void) {
        profileService.getFirstProfilesIDs(count: Limits.users.rawValue) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                let group = DispatchGroup()
                var profilesIDs = ids
                if let firstIndex = profilesIDs.firstIndex(of: self.accountID) {
                    profilesIDs.remove(at: firstIndex)
                }
                var profiles = [ProfileModelProtocol]()
                profilesIDs.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let profileModel = ProfileModel(profile: profile)
                            profiles.append(profileModel)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(.success(profiles))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getNextProfiles(completion: @escaping (Result<[ProfileModelProtocol], Error>) -> Void) {
        profileService.getNextProfilesIDs(count: Limits.users.rawValue) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                let group = DispatchGroup()
                var profilesIDs = ids
                if let firstIndex = profilesIDs.firstIndex(of: self.accountID) {
                    profilesIDs.remove(at: firstIndex)
                }
                var profiles = [ProfileModelProtocol]()
                profilesIDs.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let profileModel = ProfileModel(profile: profile)
                            profiles.append(profileModel)
                        case .failure:
                            break
                        }
                    }
                    group.notify(queue: .main) {
                        completion(.success(profiles))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

