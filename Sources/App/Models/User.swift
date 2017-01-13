//
//  User.swift
//  vapor-authentification
//
//  Created by Clement Yerochewski on 1/13/17.
//
//

import Vapor
import Fluent


final class User: Model {
    
    static var entity: String = "users"

    struct Keys {
        static let id = "id"
        static let email = "email"
        static let password = "password"
    }

    
    var exists = false
    var id: Node?
    var password: String
    var email: String
    
    // MARK: - Initialization
    
    init(email: String, password: String) throws {
        self.email = email
        self.password = password
    }
    
    // MARK: - NodeInitializable
    init(node: Node, in context: Context) throws {
        id = try node.extract(Keys.id)
        email = try (node.extract(Keys.email))
        password = try node.extract(Keys.password)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "email": email,
            "password": password,
            ])
    }

}


// MARK: - Preparation

extension User: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(entity) { user in
            user.id()
            user.string(Keys.password)
            user.string(Keys.email)
        }
        try database.driver.raw("ALTER TABLE \(entity) ADD CONSTRAINT uc_email UNIQUE (\(Keys.email));")
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
    
}

