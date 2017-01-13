//
//  User.swift
//  vapor-authentification
//
//  Created by Clement Yerochewski on 1/13/17.
//
//

import Vapor
import Fluent
import Auth
import HTTP
import BCrypt


final class User: Model {
    
    static var entity: String = "users"
    
    struct Keys {
        static let id = "id"
        static let email = "email"
        static let salt = "salt"
        static let secret = "secret"
    }
    
    typealias Secret = String
    typealias Salt = String

    var exists = false
    fileprivate var secret: Secret
    fileprivate var salt: Salt
    var id: Node?
    var email: String
    
    // MARK: - Initialization
    
    init(email: String, salt: Salt, secret: Secret)  {
        self.email = email
        self.salt = salt
        self.secret = secret
    }
    
    // MARK: - NodeInitializable
    init(node: Node, in context: Context) throws {
        id = try node.extract(Keys.id)
        email = try node.extract(Keys.email)
        salt = try node.extract(Keys.salt)
        secret = try node.extract(Keys.secret)
    }
    
    static func find(by email: String) throws -> User? {
        return try User.query().filter(Keys.email, email).first()
    }
    
}

// MARK: - NodeRepresentable
extension User {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            Keys.id: id,
            Keys.email: email,
            Keys.secret: secret,
            Keys.salt : salt
            ])
    }
}

// MARK: - Authentication

extension User: Auth.User {
    public static func authenticate(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let userCredentials as AuthenticatedUserCredentials:
            return try userCredentials.user()
        case let userCredentials as UserCredentials:
            return try userCredentials.user()
        default:
            let type = type(of: credentials)
            throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
        }
    }
    
    public static func register(credentials: Credentials) throws -> Auth.User {
        
        guard let creds = credentials as? UserCredentials else {
            let type = type(of: credentials)
            throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
        }
        
        let hashedPassword = try creds.hashPassword()

        guard let userExists = try? User.find(by: creds.email) != nil,
            userExists == false else {
                throw Abort.custom(status: .badRequest, message: "User exists")
        }
    
        
        let user = User(email: creds.email, salt: hashedPassword.salt, secret: hashedPassword.secret)
        return user
    }
}

// Check if UserCredentials match an User
extension UserCredentials {
     func user() throws -> User {
        guard let user = try User.find(by: email) else {
            throw Abort.custom(status: .badRequest,
                               message: "User not found")
        }
        guard try hashPassword(using: user.salt).secret == user.secret else {
            throw Abort.custom(status: .badRequest,
                               message: "invalid password")
        }
        return user
    }
}

// Check if UserCredentials match an User
extension AuthenticatedUserCredentials {
     func user() throws -> User {
        guard let user = try User.find(id) else {
            throw Abort.custom(status: .badRequest, message: "User not found")
        }
        return user
    }
}


// User :
// By default, request.auth.user() returns the authorized Auth.User. This will need to be casted to your internal User type for use.
// Adding a convenience method on Request is a great way to simplify this.

extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }
        
        return user
    }
}


// MARK: - Preparation
extension User: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(entity) { user in
            user.id()
            user.string(Keys.email)
            user.string(Keys.secret)
            user.string(Keys.salt)
        }
        try database.driver.raw("ALTER TABLE \(entity) ADD CONSTRAINT uc_email UNIQUE (\(Keys.email));")
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
    
}

