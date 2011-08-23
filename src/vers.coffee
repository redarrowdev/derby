racer = require 'racer'
View = require './View.server'
path = require 'path'
fs = require 'fs'
crypto = require 'crypto'

exports.createApp = (appModule, appExports, options = {}) ->
  # Expose racer and vers methods on the application module
  racer.util.merge appExports, racer
  appExports.view = view = new View

  view._clientName = options.name || path.basename appModule.filename, '.js'
  maxAge = options.maxAge || 1000 * 60 * 60 * 24 * 365
  staticRoot = options.root || path.dirname appModule.filename
  staticDir = options.dir || 'public'
  staticPath = path.join staticRoot, staticDir

  bundle = -> racer.js require: appModule.filename, (js) ->
    filename = crypto.createHash('md5').update(js).digest('base64') + '.js'
    # Base64 uses characters reserved in URLs and adds extra padding charcters.
    # Replace "/" and "+" with the unreserved "-" and "_" and remove "=" padding
    view._jsFile = filename = filename.replace /[\/\+=]/g, (match) ->
      switch match
        when '/' then '-'
        when '+' then '_'
        when '=' then ''
    console.log filePath = path.join staticPath, filename
    fs.writeFile filePath, js

  path.exists staticPath, (exists) ->
    return bundle() if exists
    fs.mkdir staticPath, 0777, (err) ->
      throw err if err
      bundle()

  return appExports

