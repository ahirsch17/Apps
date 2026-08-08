const fs = require('fs');
const path = require('path');

const DEMO_CONFIG_PATH = path.join(__dirname, '../../Between/Resources/local_demo_config.json');

function loadDemoConfig() {
  return JSON.parse(fs.readFileSync(DEMO_CONFIG_PATH, 'utf8'));
}

module.exports = { loadDemoConfig };
