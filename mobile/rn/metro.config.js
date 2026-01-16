const path = require('path');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

module.exports = mergeConfig(getDefaultConfig(__dirname), {
  watchFolders: [path.join(__dirname, '..', 'common')],
  resolver: {
    nodeModulesPaths: [path.join(__dirname, 'node_modules')],
  },
});
