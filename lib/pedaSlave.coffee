logger = require './logger.coffee'


PluginHelper = require('./pluginHelper.coffee')
MDNSHelper = require './mdnsHelper.coffee'
WebSocket = require 'ws'


class PedaSlave
  
  constructor: (@options, @npm) ->
    @pluginNames = @options.plugins
    @name = @options.name
    
    logger.info "Starting PedaSlave #{@name} with plugins #{@pluginNames.join(", ")}."

    @plugins = []
    @pluginHelpers = []
    @loadPlugins()
    @waitForMdns()
    logger.info "PedaSlave running."
  
  loadPlugins: ->
    logger.info "Loading Plugins..."
    
    for name in @pluginNames
      @loadPlugin name 
      logger.info "Plugin #{name} loaded."
      
    logger.info "All Plugins loaded."
    

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
  
    
  waitForMdns: ->
    logger.info "Looking for master..."
    self = this
    @mdnsHelper = new MDNSHelper()
    @mdnsHelper.on 'masterFound', (url) ->
      self.connect(url)
      
  initPlugins: ->
    for helper in @pluginHelpers
      helper.emit 'init'
    
  connect: (url) ->
    logger.info "Master found at #{url}, connecting!"
    
    self = this
    
    url = "ws://" + url
    
    @ws = new WebSocket url

    @ws.on 'open', ->
      logger.info "Connected to Master!"
      self.sendWelcome()
      self.sendCapabilities()
    @ws.on 'message', (data) ->
      self.handleMessage JSON.parse data
    
  sendMessage: (name, data) ->
    @ws.send JSON.stringify {message: name, data: data}  
  
  sendWelcome: ->
    logger.info "Sending Welcome Message to Master."
    @sendMessage "name", @name
  
  sendCapabilities: ->
    logger.info "Collecting Capabilities..."

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
          
    logger.info "Sending #{caps.length} Capabilities to master"
       
    @sendMessage "capabilities", caps
  
  handleMessage: (m) ->
    logger.info "Incoming \"#{m.message}\" message from Master."

    switch m.message
      when "handleOutput"
        for helper in @pluginHelpers
          if helper.type == "output"
            if m.data.targetCapability is helper.capability
              helper.emit 'output', m.data
      when "handleLogic"
        for helper in @pluginHelpers
          if helper.type == "logic"
            capabilitiy = m.data.capability
            target = capability.split(":")[1] 
            helper.callLogic target, m.data

    
module.exports = PedaSlave
