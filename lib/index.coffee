npm = require 'npm'

PluginHelper = require('./PluginHelper.coffee')

class PedaSlave
  
  constructor: (@options, @npm) ->
    @pluginNames = @options.plugins
    @plugins = []
    @loadPlugins()

  
  loadPlugins: ->
    for name in @pluginNames
      @loadPlugin name 
  
  loadPlugin: (name) ->
    pluginLoader = require("#{@npm.globalDir}/#{name}")
    plugin = null
    try 
      plugin = pluginLoader(new PluginHelper(name, this))
      @plugins.push plugin
    catch e
      console.log("Could not load #{name}.")
    
  start: ->
    
module.exports = PedaSlave
