//
//  UserRequest.swift
//  
//
//  Created by Nathan Fuller on 10/14/22.
//

import Foundation
import Vapor

struct UserRequest {
    struct UpdateUsername: Content {
        var id: UUID
        var email: String
        var username: String
    }
}
