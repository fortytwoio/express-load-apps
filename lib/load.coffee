debugModule = require "debug"
debug = debugModule "express-load-apps:load"
assert = require "assert"
fileloader = require "loadfiles"
routing = require "./routing"
util = require "util"

fs = require "fs"
path = require "path"
async = require "async"

exports = module.exports = load = (webappsPath, callback)->
    debug "Loading webapps from '%s'", webappsPath
    webapps = []
    isDir = (content, callback)->
        webappPath = path.resolve webappsPath, content
        fs.stat webappPath, (error, stats)->
            return callback stats.isDirectory()

    setupWebapp = (webappName, callback) ->
        webappPath = path.resolve webappsPath, webappName

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

        mountpoint = "/#{webappName}/"
        # TODO: This should be configurable via package.json or somehow. How?
        if webappName == "MAIN" then mountpoint = "/"
        webappSettings =
            mountpoint :  mountpoint
            app :         webapp
            controllers : controllers
            routers :     routers
            name :        webappName
            path :        webappPath

        routing webappSettings
        webapps.push webappSettings

        callback(null)

    fs.readdir webappsPath, (error, contents) ->
        if error then return callback new Error("Error reading '#{webappsPath}': '#{util.inspect(error, depth : null)}'"), null
        async.filter contents, isDir, (webappNames)->
            async.each webappNames, setupWebapp, (error)->
                return callback(error, webapps)




