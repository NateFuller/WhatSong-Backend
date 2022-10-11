//
//  LikedComment.swift
//  
//
//  Created by Nathan Fuller on 9/25/22.
//

import Fluent
import Vapor

final class CommentLike: Model, Content {
    static let schema = "commentLikes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "commentID")
    var comment: Comment
    
    @Parent(key: "userID")
    var user: User
    
    init() { }
    
    init(id: UUID? = nil, comment: Comment, user: User) throws {
        self.id = id
        self.$comment.id = try comment.requireID()
        self.$user.id = try user.requireID()
    }
}

extension CommentLike {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(CommentLike.schema)
                .id()
                .field("commentID", .uuid, .required, .references(Comment.schema, "id"))
                .field("userID", .uuid, .required, .references(User.schema, "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(CommentLike.schema).delete()
        }
    }
}
