//
//  File.swift
//  
//
//  Created by Арман Чархчян on 02.05.2022.
//

import UIKit
import NetworkServices
import ModelInterfaces

public final class PostModel: PostModelProtocol {
    public var imageHeight: CGFloat?
    public var imageWidth: CGFloat?
    public var userID: String
    public var likersIds: [String]
    public var date: Date
    public var id: String
    public var textContent: String
    public var urlImage: String?
    public var owner: ProfileModelProtocol
    public var likedByMe: Bool
    public var ownerMe: Bool
    
    init(model: PostNetworkModelProtocol,
         owner: ProfileNetworkModelProtocol) {
        self.userID = model.userID
        self.date = model.date
        self.id = model.id
        self.textContent = model.textContent
        self.urlImage = model.urlImage
        self.imageWidth = model.imageWidth
        self.imageHeight = model.imageHeight
        self.likersIds = model.likersIds
        self.textContent = model.textContent
        self.owner = ProfileModel(profile: owner)
        self.likedByMe = false
        self.ownerMe = false
    }
}
