const { registerRoutes } = require('rescript-remix/registerRoutes')

/**
 * @type {import('@remix-run/dev/config').AppConfig}
 */
module.exports = {
  serverBuildTarget: 'vercel',
  server: process.env.NODE_ENV === 'development' ? undefined : './server.js',
  appDirectory: 'app',
  assetsBuildDirectory: 'public/build',
  publicPath: '/build/',
  serverBuildDirectory: 'build',
  devServerPort: 8002,
  ignoredRouteFiles: ['.*', '*.res'],
  transpileModules: ['rescript', 'rescript-webapi'],
  serverDependenciesToBundle: ['@rainbow-me/rainbowkit, react'],
  routes(defineRoutes) {
    return defineRoutes(route => {
      registerRoutes(route)
      route('/Root_FetchGuilds', './res-routes/Root_FetchGuilds.js')
    })
  },
}
