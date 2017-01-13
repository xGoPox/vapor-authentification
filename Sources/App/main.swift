import Vapor
import VaporPostgreSQL
import Auth

let drop = Droplet()

let auth = AuthMiddleware(user: User.self)

drop.middleware.append(auth)

try drop.addProvider(VaporPostgreSQL.Provider.self)

drop.preparations.append(User.self)

let authController = AuthController(hash: drop.hash)

authController.addRoutes(drop: drop)

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.resource("posts", PostController())

drop.run()
