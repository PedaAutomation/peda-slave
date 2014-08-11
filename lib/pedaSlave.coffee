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
    
    if @options.master
      @connect @options.master
    else
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
      helper = new PluginHelper(name, this, @language)
      plugin = pluginLoader(helper)
      helper.setPlugin plugin
      @pluginHelpers.push helper
      @plugins.push plugin
    catch e
      console.log e
      logger.warn "Could not load #{name}.", e
  
    
  waitForMdns: ->
    logger.info "Looking for master..."
    self = this
    @mdnsHelper = new MDNSHelper()
    @mdnsHelper.on 'masterFound', (url) ->
      self.connect(url)
    @mdnsHelper.on 'masterLost', ->
      logger.warn "Connection to master lost."
      self.plugins = []
      self.pluginHelpers = []
      
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
      
    @ws.on 'message', (data) ->
      self.handleMessage JSON.parse data
      
  
  stop: ->
    logger.info "Stopping PedaSlave..."
    # @ws.close() ROLF
    logger.info "Shutting down."
    process.exit()
  
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
        for id of helper.logicEvents
          ev = helper.logicEvents[id]
          regex = ev.regex.toString()
          name = id
          caps.push({type: "logic", name: "#{helper.getCapabilityName()}:#{name}", regex: regex})
          
    logger.info "Sending #{caps.length} Capabilities to master"
       
    @sendMessage "capabilities", caps
  
  handleMessage: (m) ->
    logger.info "Incoming \"#{m.message}\" message from Master."

    switch m.message
      when "handleOutput"
        for helper in @pluginHelpers
          if helper.type == "output"
            if m.data.targetCapability.indexOf(helper.name) > -1
              helper.emit 'output', m.data
      when "handleLogic"
        for helper in @pluginHelpers
          if helper.type == "logic"
            target = m.data.capability.split(":")[1] 
            helper.callLogic target, m.data
      when "language"
        @language = m.data
        @loadPlugins()
        @sendCapabilities()
    
module.exports = PedaSlave
