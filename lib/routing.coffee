debugModule = require "debug"
debug = debugModule "express-load-apps:routing"
defaultRoutingSetup = require "express-simple-routing"

exports = module.exports = routing = (webapp) ->
    setup = (routeName, actions) ->
        debug "Setting up routes for '#{routeName}' in webapp '#{webapp.name}'"
        if webapp.routers?.hasOwnProperty routeName
            debug "Custom routing for '#{routeName}' route in webapp '#{webapp.name}'"
            setupRouting = webapp.routers[routeName]
        else
            debug "Default routing for '#{routeName}' route in webapp '#{webapp.name}'"
            setupRouting = defaultRoutingSetup

        if routeName == "index"
            route = "/"
        else
            route = "/#{routeName}"

        webapp.app.use route, setupRouting(actions)

    # Make sure the "index" route gets added first
    if webapp.controllers?.index
        setup "index", webapp.controllers.index
        delete webapp.controllers.index # delete index router so we do not add it twice

    for name, actions of webapp.controllers
        setup name, actions
