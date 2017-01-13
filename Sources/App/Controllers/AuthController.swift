//
//  AuthController.swift
//  vapor-authentification
//
//  Created by Clement Yerochewski on 1/13/17.
//
//

import Vapor
import HTTP
import Auth
import BCrypt

final class AuthController {
    
    private let hash: HashProtocol

    // MARK: - Init

    init(hash: HashProtocol) {
        self.hash = hash
    }

    // MARK: - Routes
    
    func addRoutes(drop: Droplet) {
        drop.post("login", handler: login)
        drop.post("register", handler: register)
    }
    
    // MARK: - Login
    
    func login(request: Request) throws -> ResponseRepresentable {
        guard let email = request.data["email"]?.string else {
            throw Abort.custom(status: .badRequest, message: "email is missing")
        }
        guard let password = request.data["password"]?.string else {
                throw Abort.custom(status: .badRequest, message: "password is missing")
        }
        let credentials = UserCredentials(email: email,
                                          password: password,
                                          hash: hash)
        try request.auth.login(credentials, persist: false)
        let user = try request.user()
        return try user.makeJSON()
    }
    
    // MARK: - Register
    
    func register(request: Request) throws -> ResponseRepresentable {
        guard let email = request.data["email"]?.string else {
            throw Abort.custom(status: .badRequest, message: "email is missing")
        }
        guard let password = request.data["password"]?.string else {
            throw Abort.custom(status: .badRequest, message: "password is missing")
        }
        let credentials = UserCredentials(email: email,
                                          password: password,
                                          hash: hash)
        

        var user = try User.register(credentials: credentials)
        try user.save()
        try request.auth.login(credentials, persist: false)
        return try request.user().makeJSON()
    }
    
}
