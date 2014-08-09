EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave) ->
    
  setType: (type) ->
    @type = type if type in ["input", "output", "logic"]
    
  setName: (name) ->
    @name = name
    
  setPlugin: (plugin) ->
    @plugin = plugin
    
  
module.exports = PluginHelper
