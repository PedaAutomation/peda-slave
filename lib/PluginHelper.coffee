EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave) ->
    
  setType: (type) ->
    @type = type if type in ["input", "output", "logic"]
    
  setName: (name) ->
    @name = name

  setCapability: (capability) ->
    if @type isnt "input"
      @capability = capability
    else
      throw "Only output and logic plugin can have capabilities."
    
  setPlugin: (plugin) ->
    @plugin = plugin
    
  sendOutput: (result) ->  	
    @slave.sendMessage "outputForward", result

  sendAimedOutput: (result, target) ->
    data
    data.data = result
    data.targetDevice = target
    @slave.sendMessage "outputForward", data
    
module.exports = PluginHelper
