EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave) ->
    @logicCapabilities = []
    
  setType: (type) ->
    @type = type if type in ["input", "output", "logic"]
    
  setName: (name) ->
    @name = name
    
  getCapabilityName: ->
    "#{@type}-#{@name}" 

  sendInput: (input) ->
    @slave.sendMessage "input", {command: input}
  
  registerLogic: (name, regex, callback) ->
    throw "You need to have a logic plugin for logic calls." if @type isnt "logic"
    
    @logicEvents[name] = {
      regex: regex,
      callback: callback
    }
  
  callLogic: (name, data) ->
    @logicEvents[name](data)
  
  setPlugin: (plugin) ->
    @plugin = plugin
    
  sendOutput: (result) ->  	
    @slave.sendMessage "outputForward", result

  sendOutputToSlave: (result, target) ->
    data = {}
    data.data = result
    data.targetDevice = target
    @slave.sendMessage "outputForward", data
  
  sendOutputToCapability: (result, cap) ->
    data = {}
    data.data = result
    data.targetCapability = target
    @slave.sendMessage "outputForward", data
    
  sendOutputToCapabilityAndSlave: (result, cap, device) ->
    data = {}
    data.data = result
    data.targetCapability = target
    data.targetDevice = device 
    @slave.sendMessage "outputForward", data
    
module.exports = PluginHelper
