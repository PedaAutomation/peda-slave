EventEmitter = require('events').EventEmitter

mdns = require('mdns')

class MDNSHelper extends EventEmitter
  constructor: ->
    self = this
    @browser = mdns.createBrowser mdns.tcp 'pedam'
    
    @browser.on 'serviceUp', (service) ->
      if not self.found
        address = null
        for a in service.addresses
          address = a if a.indexOf('.') > -1
        return if not address?
        url = address + ":" + service.port
        self.emit 'masterFound', url
        self.found = service.name
    
    @browser.on 'serviceDown', (service) ->
      if self.found == service.name
        self.found = null
        self.emit 'masterLost'
      
    @browser.start()
    
    
module.exports = MDNSHelper
