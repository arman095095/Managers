//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices


public final class RequestModel: RequestModelProtocol {
    public var sender: ProfileModelProtocol
    public var senderID: String
    
    public init(sender: ProfileNetworkModelProtocol) {
        self.sender = ProfileModel(profile: sender)
        self.senderID = sender.id
    }
}
