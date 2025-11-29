const { getDefaultConfig } = require('expo/metro-config');

module.exports = {
  expo: {
    name: '气象沙盘模拟器',
    slug: 'meteorological-sandbox',
    version: '1.0.0',
    orientation: 'portrait',
    icon: './assets/icon.png',
    platforms: ['android', 'ios', 'web'],
    scheme: 'meteo-sandbox',
    ios: {
      bundleIdentifier: 'com.meteorological.sandbox',
      supportsTablet: true,
    },
    android: {
      package: 'com.meteorological.sandbox',
      versionCode: 1,
      adaptiveIcon: {
        foregroundImage: './assets/icon.png',
        backgroundColor: '#2196F3',
      },
    },
    web: {
      bundler: 'metro',
      favicon: './assets/icon.png',
    },
    extra: {
      appDescription: '专业级气象沙盘模拟器 - 6大求解器算法，并行计算，60FPS渲染',
      author: 'iFlow CLI',
    },
  },
};