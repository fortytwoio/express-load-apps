debugModule = require "debug"
debug = debugModule "express-load-apps:load"
assert = require "assert"
fileloader = require "loadfiles"
routing = require "./routing"
util = require "util"

fs = require "fs"
path = require "path"

exports = module.exports = load = (webappsPath, callback)->
    debug "Loading webapps from '%s'", webappsPath
    webapps = []
    isDir = (content) ->
        webappPath = path.resolve webappsPath, content
        stats = fs.statSync webappPath
        return stats.isDirectory()

    setupWebapp = (webappName) ->
        webappPath = path.resolve webappsPath, webappName
        middlewaresPath = path.resolve webappPath, 'middlewares'


        debug "Requiring '#{webappName}' at '#{webappPath}'"
        webapp = require webappPath

        # Lazy check if exported module seems to look like an express app. instanceof did not work. :(
        assert webapp.settings && webapp.locals && webapp.use && webapp.request && webapp.response && webapp.mountpath && webapp.get && webapp.set, "WebApp '#{webappName}' at '#{webappPath}' seems not to be (or export) an express app"

        # Initialize the file loader with the path to the webapp
        load = fileloader webappPath, "coffee"

        # TODO: The directory structure should be configurable in package.json according to commonjs.
        # TODO: Also if this app should be bootstrapped or not. Opt-In
        routers = load "routers"
        routerNames = Object.keys routers
        debug "Loaded '#{routerNames.length}' router(s) from webapp '#{webappName}': #{routerNames.join ", "}"

        controllers = load "controllers"
        controllerNames = Object.keys controllers
        debug "Loaded '#{controllerNames.length}' controller(s) from webapp '#{webappName}': #{controllerNames.join ", "}"

        if fs.existsSync middlewaresPath
            loadMiddlewares = fileloader middlewaresPath, 'coffee'
            try
                preMiddlewares = loadMiddlewares "pre"
                preMiddlewareNames = Object.keys preMiddlewares
                debug "Loaded '#{preMiddlewareNames.length}' pre middleware(s) from webapp '#{webappName}': #{preMiddlewareNames.join ", "}"
            catch error
                debug "No preMiddlewares found"

            try
                postMiddlewares = loadMiddlewares "post"
                postMiddlewareNames = Object.keys postMiddlewares
                debug "Loaded '#{postMiddlewareNames.length}' pre middleware(s) from webapp '#{webappName}': #{postMiddlewareNames.join ", "}"
            catch error
                debug "No postMiddlewares found"

        mountpoint = "/#{webappName}/"
        # TODO: This should be configurable via package.json or somehow. How?
        if webappName == "MAIN" then mountpoint = "/"
        webappSettings =
            mountpoint : mountpoint
            preMiddlewares : preMiddlewares
            postMiddlewares : postMiddlewares
            mountpoint : mountpoint
            app : webapp
            controllers : controllers
            routers : routers
            name : webappName
            path : webappPath

        routing webappSettings
        webapps.push webappSettings

    try
        contents = fs.readdirSync webappsPath
        webappNames = contents.filter isDir
        webappNames.forEach setupWebapp
    catch error
        return callback new Error("Error reading '#{webappsPath}': '#{util.inspect(error, depth : null)}'"), null

    return callback(null, webapps)




