//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices

public final class ChatModel: ChatModelProtocol {
    public var friend: ProfileModelProtocol
    public var friendID: String
    
    public init(friend: ProfileNetworkModelProtocol) {
        self.friend = ProfileModel(profile: friend)
        self.friendID = friend.id
    }
}
