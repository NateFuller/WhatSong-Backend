//
//  NewCommentMiddleware.swift
//  
//
//  Created by Nathan Fuller on 9/23/22.
//

import Vapor

struct NewCommentMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
//        let comment = try request.content.decode(Comment.self)
//        comment.createdAt = Date()
        
//        try request.content.encode(comment)
    
        return try await next.respond(to: request)
    }
}
