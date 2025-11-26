const { getDefaultConfig } = require('expo/metro-config');

module.exports = (async () => {
  const config = await getDefaultConfig(__dirname);

  // 不监听 node_modules
  config.watchFolders = [__dirname];
  config.resolver.blockList = [/\/node_modules\/.*\/node_modules\/.*/];

  // 降并发、清缓存
  config.maxWorkers = 1;
  config.resetCache = true;

  return config;
})();
