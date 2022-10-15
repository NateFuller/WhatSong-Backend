import FluentSQL
import Vapor

func routes(_ app: Application) throws {
    // MARK: - Comment
    
    // MARK: GET /comments
    
    app.get("comments") { req async throws in
        try await Comment.query(on: req.db).all()
    }
    
    // MARK: POST /comment/create
    
    app.group(NewCommentMiddleware()) {
        $0.post("comment", "create") { req async throws -> Comment in
            let comment = try req.content.decode(Comment.self)
            try await comment.create(on: req.db)
            return comment
        }
    }
    
    // MARK: PUT /comment/like
    
    app.put("comment", "like") { req async throws -> Response in
        let commentLike = try req.content.decode(CommentLike.self)
        
        if try await CommentLike.query(on: req.db)
            .with(\.$user)
            .filter(\.$user.$id == commentLike.$user.id)
            .filter(\.$comment.$id == commentLike.$comment.id)
            .first() != nil {
            return .init(status: .noContent)
        }
        
        try await commentLike.create(on: req.db)
        
        return .init(status: .ok)
    }
    
    // MARK: DELETE /comment/like
    
    app.delete("comment", "like") { req async throws -> Response in
        let commentLike = try req.content.decode(CommentLike.self)
        
        guard let existingLike = try await CommentLike.query(on: req.db)
            .with(\.$user)
            .filter(\.$user.$id == commentLike.$user.id)
            .filter(\.$comment.$id == commentLike.$comment.id)
            .first() else {
            return .init(status: .noContent)
        }
        
        try await existingLike.delete(on: req.db)
        
        return .init(status: .ok)
    }
    
    // MARK: DELETE /comments (Dev)
    
    app.delete("comments") { req async throws -> String in
        guard app.environment == .development else {
            throw Abort(.notFound)
        }
        
        if let sql = req.db as? SQLDatabase {
            try sql.delete(from: "comments")
                .run().wait()
            
            return "⚠️ Deleted all comments! ⚠️"
        } else {
            throw Abort(.internalServerError)
        }
    }
    
    // MARK: - User
    
    // MARK: POST /user/create
    
    app.group(NewUserMiddleware()) {
        $0.post("user", "create") { req async throws -> UserResponse.Basic in
            let user = try req.content.decode(User.self)
            
            guard try await User.query(on: req.db)
                .filter(\.$email == user.email).first() == nil else {
                throw Abort(.notFound, reason: "An account with that email address already exists.")
            }
            
            user.password = try await req.password.async.hash(user.password)
            
            try await user.create(on: req.db)
            
            return UserResponse.Basic(user: user)
        }
    }
    
    // MARK: GET /user/:username
    
    app.get("user", ":username") { req async throws -> UserResponse.Basic in
        let username = req.parameters.get("username")!
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound)
        }
        
        return UserResponse.Basic(user: user)
    }
    
    // MARK: PUT /user
    
    app.put("user") { req async throws -> Response in
        let bodyUser = try req.content.decode(UserRequest.UpdateUsername.self)
        
        guard let matchingUser = try await User.query(on: req.db)
            .filter(\.$id == bodyUser.id)
            .first() else {
            throw Abort(.notFound)
        }

        if matchingUser.username == bodyUser.username {
            let basicResponse = UserResponse.Basic(user: matchingUser)
            let updatedResponse = try await basicResponse.encodeResponse(status: .noContent, for: req)
            
            return updatedResponse
        }
        
        let existingUsernameCount = try await User.query(on: req.db)
            .filter(\.$username == bodyUser.username)
            .count()
        
        if existingUsernameCount == 1 {
            throw Abort(.conflict, reason: "This username has already been taken.")
        } else if existingUsernameCount > 1 {
            throw Abort(.internalServerError, reason: "An unexpected error occured updating this user.")
        }
        
        if let lastModifiedDate = matchingUser.usernameLastModified {
            let cooldownEndsAt = lastModifiedDate.addingTimeInterval(60*60*24)
            
            if Date() < cooldownEndsAt {
                throw UserError.userRenameCooldown(lastModifiedDate, cooldownEndsAt)
            }
        }
        
        try await User.query(on: req.db)
            .set(\.$username, to: bodyUser.username)
            .set(\.$usernameLastModified, to: Date())
            .filter(\.$id == bodyUser.id)
            .update()
        
        guard let updatedUser = try await User.query(on: req.db)
            .filter(\.$username == bodyUser.username)
            .first() else {
            throw Abort(.internalServerError, reason: "An unexpected error occurred updating this user.")
        }
        
        return try await UserResponse.UsernameUpdated(user: updatedUser).encodeResponse(for: req)
    }
    
    // MARK: - Post
    
    // MARK: POST /post/create
    
    app.post("post", "create") { req async throws -> Post in
        let post = try req.content.decode(Post.self)
        try await post.create(on: req.db)
        
        return post
    }
    
    // MARK: GET /posts/:id
    
    app.get("post", ":id") { req async throws -> Post in
        let idString = req.parameters.get("id")!
        print("GET POST ID: \(idString)")
        guard let postUUID = UUID(uuidString: idString) else {
            req.logger.info("UUID invalid \(idString)")
            throw Abort(.notFound)
        }
        
        guard let post = try await Post.query(on: req.db)
            .filter(\.$id == postUUID)
            .first() else {
            req.logger.info("Query failed")
            throw Abort(.notFound)
        }
        
        return post
    }
    
    // MARK: GET /posts/user/:username
    
    app.get("posts", "user", ":username") { req async throws -> [Post] in
        let username = req.parameters.get("username")!
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$posts)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user.posts
    }
    
    // MARK: GET /likedComments/user/:username
    
    app.get("likedComments", "user", ":username") { req async throws -> [Comment] in
        let username = req.parameters.get("username")!
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$likedComments)
            .first() else {
            throw Abort(.notFound)
        }

        return user.likedComments
    }
    
    // MARK : GET /comments/user/:username
    
    app.get("comments", "user", ":username") { req async throws -> [Comment] in
        let username = req.parameters.get("username")!
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$comments)
            .first() else {
            throw Abort(.notFound)
        }

        return user.comments
    }
}


