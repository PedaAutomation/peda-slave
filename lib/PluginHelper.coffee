EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave) ->
    
  setType: (type) ->
    @type = type if ["input", "output", "logic"].indexOf(type) > -1
    
  setName: (name) ->
    @name = name
    
  setPlugin: (plugin) ->
    @plugin = plugin
    
  
module.exports = PluginHelper
