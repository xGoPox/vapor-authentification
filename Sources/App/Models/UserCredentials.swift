//
//  UserCredentials.swift
//  vapor-authentification
//
//  Created by Clement Yerochewski on 1/13/17.
//
//

import Auth
import BCrypt
import Node
import Vapor

typealias HashedPassword = (secret: User.Secret, salt: User.Salt)

struct UserCredentials: Credentials {
    var password: String
    var email: String
    private let hash: HashProtocol

    init(email: String, password: String, hash: HashProtocol) {
        self.email = email
        self.hash = hash
        self.password = password
    }
    
    func hashPassword(using salt: User.Salt = BCryptSalt().string) throws -> HashedPassword {
        return (try hash.make((password) + salt), salt)
    }
}


struct AuthenticatedUserCredentials: Credentials {
    let id: String
    
    /*
    init(node: Node) throws {
        guard let id: String = try node.extract(User.Keys.id) else {
                throw VaporAuthError.couldNotLogIn
        }
        self.id = id
    }*/
}



