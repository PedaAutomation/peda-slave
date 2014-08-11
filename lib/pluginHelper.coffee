logger = require('./logger.coffee')

EventEmitter = require('events').EventEmitter

class PluginHelper extends EventEmitter
  constructor: (@pluginName, @slave, @lang="en") ->
    @logicCapabilities = []
    @languageData = {}
    @logicEvents = []
  
  getLanguage: ->
    console.log @lang
    @lang
  
  registerLanguage: (name, data, defaultLang = false) ->
      @languageData[name] = data
      if defaultLang
        @languageData["default"] = data
  
  setLanguage: (lang) ->
    console.log lang
    @lang = lang
  
  __: (name) ->
    value = @getLanguageValue @lang, name
    value = @getLanguageValue "default", name if not value
    
    return value
  
  log: (level, string) ->
    logger.log level, "Plugin #{@pluginName}: #{string}"
  
  getLanguageValue: (lang, name) ->
      data = @languageData[lang]
      
      name = name.split("\\.")
      
      value = data

      try
        for p in name
          value = value[p]
      catch
        return null
      
      return value 
  
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
    @logicEvents[name].callback(data, this)
  
  setPlugin: (plugin) ->
    @plugin = plugin
    
  sendOutput: (result) ->  	
    @slave.sendMessage "forwardOutput", result

  sendOutputToSlave: (result, target) ->
    data = {}
    data.data = result
    data.targetDevice = target
    @slave.sendMessage "forwardOutput", data
  
  sendOutputToCapability: (result, target) ->
    data = {}
    data.data = result
    data.targetCapability = target
    @slave.sendMessage "forwardOutput", data
    
  sendOutputToCapabilityAndSlave: (result, target, device) ->
    data = {}
    data.data = result
    data.targetCapability = target
    data.targetDevice = device 
    @slave.sendMessage "forwardOutput", data
    
module.exports = PluginHelper
