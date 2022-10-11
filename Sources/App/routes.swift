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
    
    app.put("comment", "like") { req async throws -> CommentLike in
        let commentLike = try req.content.decode(CommentLike.self)
        
        if let existingLike = try await CommentLike.query(on: req.db)
            .with(\.$user)
            .filter(\.$user.$id == commentLike.$user.id)
            .filter(\.$comment.$id == commentLike.$comment.id).first() {
            return existingLike
        }
        
        try await commentLike.create(on: req.db)
        return commentLike
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
        $0.post("user", "create") { req async throws -> User in
            let user = try req.content.decode(User.self)
            
            guard try await User.query(on: req.db)
                .filter(\.$email == user.email).first() == nil else {
                throw Abort(.notFound, reason: "An account with that email address already exists.")
            }
            
            try await user.create(on: req.db)
            return user
        }
    }
    
    // MARK: GET /user/:username
    
    app.get("user", ":username") { req async throws -> User in
        let username = req.parameters.get("username")!
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user
    }
    
    // MARK: PUT /user/:username
    
    app.put("user") { req async throws -> Response in
        let bodyUser = try req.content.decode(User.self)
        
        guard let userID = bodyUser.id else {
            throw Abort(.badRequest, reason: "Request body must specify ID of existing user")
        }
        
        guard let requestedUserName = bodyUser.username else {
            throw Abort(.badRequest, reason: "Request body must specify desired username")
        }
        
        let matchingUser = try await User.query(on: req.db)
            .filter(\.$id == userID)
            .first()

        if let matchingUser = matchingUser, matchingUser.username == requestedUserName {
            let response = try await matchingUser.encodeResponse(status: .noContent, for: req)
            
            return response
        } else if matchingUser == nil {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let existingUsernameCount = try await User.query(on: req.db)
            .filter(\.$username == bodyUser.username)
            .count()
        
        if existingUsernameCount == 1 {
            throw Abort(.conflict, reason: "This username has already been taken.")
        } else if existingUsernameCount > 1 {
            throw Abort(.internalServerError, reason: "An unexpected error occured updating this user.")
        }
        
        try await User.query(on: req.db)
            .set(\.$username, to: requestedUserName)
            .filter(\.$id == userID)
            .update()
        
        guard let updatedUser = try await User.query(on: req.db)
            .filter(\.$username == requestedUserName)
            .first() else {
            throw Abort(.internalServerError, reason: "An unexpected error occurred updating this user.")
        }
        
        return try await updatedUser.encodeResponse(for: req)
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
    
    // MARK: GET /posts/user/:id
    
    app.get("posts", "user", ":id") { req async throws -> [Post] in
        let idString = req.parameters.get("id")!
        guard let userUUID = UUID(uuidString: idString) else {
            throw Abort(.notFound)
        }
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userUUID)
            .with(\.$posts)
            .first() else {
            throw Abort(.notFound)
        }
        
        return user.posts
    }
}


