// brought to you by sgade: https://github.com/MoinApp/moinapp-server/blob/35f1ba52dc7a86b49508929a913426359c8f5d9b/lib/index.js
// Register coffeescript to remove the compile step
require('coffee-script').register()
// coffeescript can now be require'd
// then load our index.coffee
exports = require('./index.coffee');
module.exports = exports
