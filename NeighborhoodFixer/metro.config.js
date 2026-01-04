const path = require("path");
const { getDefaultConfig } = require("expo/metro-config");

const projectRoot = __dirname;
const appsRoot = path.resolve(projectRoot, "..");

const config = getDefaultConfig(projectRoot);

// Allow importing shared modules from `Apps/` (e.g. `Apps/client.js`)
config.watchFolders = [appsRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(appsRoot, "node_modules"),
];
config.resolver.disableHierarchicalLookup = true;

module.exports = config;


