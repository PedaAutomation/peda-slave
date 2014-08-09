npm = require 'npm'

PluginHelper = require('./PluginHelper.coffee')
MDNSHelper = require './mdnsHelper.coffee'
WebSocket = require 'ws'


class PedaSlave
  
  constructor: (@options, @npm) ->
    @pluginNames = @options.plugins
    @name = @options.name
    @plugins = []
    @pluginHelpers = []
    @loadPlugins()

  
  loadPlugins: ->
    for name in @pluginNames
      @loadPlugin name 
    self = this
    @mdnsHelper = new MDNSHelper()
    @mdnsHelper.on 'masterFound', (url) ->
      self.connect(url)

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
      console.log e
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
      self.sendWelcome()
      self.sendCapabilities()
    @ws.on 'message', (data) ->
      self.handleMessage JSON.parse data
    
  sendMessage: (name, data) ->
    @ws.send JSON.stringify {message: name, data: data}  
  
  sendWelcome: ->
    @sendMessage "name", @name
  
  sendCapabilities: ->
    caps = []
    for helper in @pluginHelpers
      if helper.type == "input"
        caps.push({type: "input", name: helper.getCapabilityName()})
      if helper.type == "output"
        caps.push({type: "output", name: helper.getCapabilityName()})
      if helper.type == "logic"
        for id in helper.logicEvents
          ev = helper.logicEvents[id]
          regex = ev.regex.toString()
          name = id
          caps.push({type: "logic", name: "#{helper.getCapabilityName()}-#{name}", regex: regex})
           
    @sendMessage "capabilities", caps
  
  handleMessage: (m) ->
    
    switch m.message
      when "handleOutput"
        for helper in @pluginHelpers
          if helper.type == "output"
            if m.data.targetCapability is helper.capability
              helper.emit 'output', m.data.data
      when "handleLogic"
        for helper in @pluginHelpers
          if helper.type == "logic"
            capabilitiy = m.data.capability
            target = capability.split(":")[1] 
            helper.callLogic target, m.data

    
module.exports = PedaSlave
