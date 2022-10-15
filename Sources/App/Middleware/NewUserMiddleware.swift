//
//  NewUserMiddleware.swift
//  
//
//  Created by Nathan Fuller on 9/26/22.
//

import Vapor

struct NewUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let user = try request.content.decode(User.self)
        
        guard !user.password.isEmpty else {
            throw UserError.invalidPassword
        }
        
        let emailPattern = #"^\S+@\S+\.\S+$"# // TODO research more robust regex
        guard user.email.range(
            of: emailPattern,
            options: .regularExpression
        ) != nil else {
            throw UserError.invalidEmail(user.email)
        }
    
        return try await next.respond(to: request)
    }
}

