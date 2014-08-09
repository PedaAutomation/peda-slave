EventEmitter = require('events').EventEmitter

mdns = require('mdns')

class MDNSHelper extends EventEmitter
  constructor: ->
    self = this
    @browser = mdns.createBrowser mdns.tcp 'pedam'
    @browser.on 'serviceUp', (service) ->
      if not self.found
        url = service.addresses[0] + ":" + service.port
        self.emit 'masterFound', url
        self.found = url
    @browser.on 'serviceDown', (service) ->
      url = service.addresses[0] + ":" + service.port
      if self.found == url
        self.found = null
        self.emit 'masterLost'
      
    @browser.start()
    
    
module.exports = MDNSHelper
