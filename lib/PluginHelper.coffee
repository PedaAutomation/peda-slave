logger = require('./logger.coffee')

EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave) ->
    @logicCapabilities = []
    @languageData = {}
    @lang = "en" #TODO: load this from the master
    
  
  getLanguage: ->
    @lang
  
  registerLanguage: (name, data, default = false) ->
      @languageData[name] = data
      if default
        @languageData["default"] = data
  
  setLanguage: (lang) ->
    @lang = lang
  
  __: (name) ->
    value = getLanguageValue @lang, name
    value = getLanguageValue "default", name if not value
    
    return value
  
  log: (level, string) ->
    logger.log level, "Plugin #{@pluginName}: #{string}"
  
  getLanguageValue: (lang, name) ->
      data = @languageData[lang]
      
      name.split(".")
      
      value = data
      
      try
        for p in name
          value[p] = value
      catch
        return null
      
      return lang 
  
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
    @logicEvents[name].callback(data)
  
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
