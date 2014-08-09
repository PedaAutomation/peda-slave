npm = require 'npm'

PluginHelper = require('./PluginHelper.coffee')
MDNSHelper = require './mdnsHelper.coffee'

class PedaSlave
  
  constructor: (@options, @npm) ->
    @pluginNames = @options.plugins
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
    url = "ws://" + url
    console.log url
    
module.exports = PedaSlave
