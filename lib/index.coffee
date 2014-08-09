npm = require 'npm'

PluginHelper = require('./PluginHelper.coffee')
MDNSHelper = require './mdnsHelper.coffee'
WebSocket = require 'ws'


class PedaSlave
  
  constructor: (@options, @npm) ->
    @pluginNames = @options.plugins
    @name = @options.name
    @mdnsHelper = new MDNSHelper()
    @mdnsHelper.on 'masterFound', @connect
    @plugins = []
    @pluginHelpers = []
    @loadPlugins()

  
  loadPlugins: ->
    for name in @pluginNames
      @loadPlugin name 
  
  loadPlugin: (name) ->
    pluginLoader = require("#{@npm.globalDir}/#{name}")
    plugin = null
    try
      helper = new PluginHelper(name, this)
      plugin = pluginLoader(helper)
      helper.setPlugin plugin
      @pluginHelpers.push helper
      @plugins.push plugin
    catch e
      console.log("Could not load #{name}.")
      
  initPlugins: ->
    for helper in @pluginHelpers
      helper.emit 'init'
    
  connect: (url) ->
    self = this
    
    url = "ws://" + url
    
    @ws = new WebSocket url
    console.log url
    @ws.on 'open', ->
      self.sendWelcome
    @ws.on 'message', (data) ->
      self.handleMessage data
    
  sendMessage: (name, data) ->
    @ws.send JSON.stringify {message: name, data: data}  
  
  sendWelcome: ->
    @sendMessage name, @name
  
  handleMessage: (m) ->
    
    
module.exports = PedaSlave
