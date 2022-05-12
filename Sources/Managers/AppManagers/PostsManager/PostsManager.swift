//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 02.05.2022.
//

import Foundation
import NetworkServices
import UIKit
import ModelInterfaces
import Services

public protocol PostsManagerProtocol: AnyObject {
    func create(image: UIImage?,
                imageSize: CGSize?,
                content: String,
                completion: @escaping (Result<Void, Error>) -> Void)
    func getAllFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getAllNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getFirstPosts(for userID: String,
                       completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getNextPosts(for userID: String,
                      completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getCurrentUserFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func getCurrentUserNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void)
    func removePost(postID: String)
    func like(postID: String, ownerID: String)
    func unlike(postID: String, ownerID: String)
}

public final class PostsManager {
    
    private let postsService: PostsServiceProtocol
    private let remoteStorage: RemoteStorageServiceProtocol
    private let profilesService: ProfilesServiceProtocol
    private let accountID: String
    
    init(accountID: String,
         postsService: PostsServiceProtocol,
         remoteStorage: RemoteStorageServiceProtocol,
         profilesService: ProfilesServiceProtocol) {
        self.accountID = accountID
        self.postsService = postsService
        self.remoteStorage = remoteStorage
        self.profilesService = profilesService
    }
}

extension PostsManager: PostsManagerProtocol {
    
    public enum Limits: Int {
        case posts = 20
    }
    
    public func create(image: UIImage?,
                       imageSize: CGSize?,
                       content: String,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        if let data = image?.jpegData(compressionQuality: 0.4),
           let size = imageSize {
            remoteStorage.uploadPost(image: data) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    let postNetworkModel = PostNetworkModel(userID: self.accountID,
                                                            textContent: content,
                                                            urlImage: url,
                                                            imageHeight: size.height,
                                                            imageWidth: size.width)
                    self.postsService.createPost(accountID: self.accountID,
                                                 post: postNetworkModel) { result in
                        switch result {
                        case .success():
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let postNetworkModel = PostNetworkModel(userID: accountID,
                                                    textContent: content,
                                                    urlImage: nil,
                                                    imageHeight: nil,
                                                    imageWidth: nil)
            postsService.createPost(accountID: accountID, post: postNetworkModel) { result in
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func getAllFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        postsService.getAllFirstPosts(count: Limits.posts.rawValue) { [weak self] result in
            guard let self = self else { return }
            let group = DispatchGroup()
            switch result {
            case .success(let models):
                models.forEach { model in
                    group.enter()
                    self.postsService.getPostLikersIDs(postID: model.id) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let likers):
                            model.likersIds = likers
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    self.handle(models: models, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getAllNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        postsService.getAllNextPosts(count: Limits.posts.rawValue) { [weak self] result in
            guard let self = self else { return }
            let group = DispatchGroup()
            switch result {
            case .success(let models):
                models.forEach { model in
                    group.enter()
                    self.postsService.getPostLikersIDs(postID: model.id) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let likers):
                            model.likersIds = likers
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    self.handle(models: models, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getFirstPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        self.profilesService.getProfileInfo(userID: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard !profile.removed else {
                    completion(.success([]))
                    return
                }
                self.postsService.getUserFirstPosts(count: Limits.posts.rawValue,
                                                    userID: userID) { result in
                    let group = DispatchGroup()
                    switch result {
                    case .success(let models):
                        models.forEach { model in
                            group.enter()
                            self.postsService.getPostLikersIDs(postID: model.id) { result in
                                defer { group.leave() }
                                switch result {
                                case .success(let likers):
                                    model.likersIds = likers
                                case .failure:
                                    break
                                }
                            }
                        }
                        group.notify(queue: .main) {
                            let posts: [PostModelProtocol] = models.map {
                                let model = PostModel(model: $0, owner: profile)
                                model.likedByMe = model.likersIds.contains(self.accountID)
                                model.ownerMe = self.accountID == $0.userID
                                return model
                            }
                            completion(.success(posts))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getNextPosts(for userID: String, completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        self.profilesService.getProfileInfo(userID: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard !profile.removed else {
                    completion(.success([]))
                    return
                }
                self.postsService.getUserNextPosts(count: Limits.posts.rawValue,
                                                   userID: userID) { result in
                    let group = DispatchGroup()
                    switch result {
                    case .success(let models):
                        models.forEach { model in
                            group.enter()
                            self.postsService.getPostLikersIDs(postID: model.id) { result in
                                defer { group.leave() }
                                switch result {
                                case .success(let likers):
                                    model.likersIds = likers
                                case .failure:
                                    break
                                }
                            }
                        }
                        group.notify(queue: .main) {
                            let posts: [PostModelProtocol] = models.map {
                                let model = PostModel(model: $0, owner: profile)
                                model.likedByMe = model.likersIds.contains(self.accountID)
                                model.ownerMe = self.accountID == $0.userID
                                return model
                            }
                            completion(.success(posts))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getCurrentUserFirstPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        getFirstPosts(for: accountID, completion: completion)
    }
    
    public func getCurrentUserNextPosts(completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        getNextPosts(for: accountID, completion: completion)
    }
    
    public func removePost(postID: String) {
        postsService.deletePost(accountID: accountID, postID: postID)
    }
    
    public func like(postID: String, ownerID: String) {
        postsService.likePost(accountID: accountID, postID: postID, ownerID: ownerID)
    }
    
    public func unlike(postID: String, ownerID: String) {
        postsService.unlikePost(accountID: accountID, postID: postID, ownerID: ownerID)
    }
    
}

private extension PostsManager {
    func handle(models: [PostNetworkModelProtocol],
                completion: @escaping (Result<[PostModelProtocol], Error>) -> Void) {
        var posts = [PostModelProtocol]()
        var dict = [String: ProfileNetworkModelProtocol]()
        let ownersIDs = Set(models.map { $0.userID })
        let group = DispatchGroup()
        for userID in ownersIDs {
            group.enter()
            self.profilesService.getProfileInfo(userID: userID) { result in
                defer { group.leave() }
                switch result {
                case .success(let profile):
                    dict[userID] = profile
                case .failure:
                    break
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            posts = models.compactMap {
                guard let owner = dict[$0.userID] else { return nil }
                let post = PostModel(model: $0, owner: owner)
                post.ownerMe = self.accountID == $0.userID
                post.likedByMe = post.likersIds.contains(self.accountID)
                return post
            }
            completion(.success(posts))
        }
    }

}

