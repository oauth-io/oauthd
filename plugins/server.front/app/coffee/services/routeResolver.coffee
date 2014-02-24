define [], ->
    services = angular.module 'routeResolverServices', []
    services.provider 'routeResolver', ->
        @get = ->
            this
        @routeConfig = (->
            viewsDirectory = '/templates'
            controllersDirectory = '/js/controllers'
            setBaseDirectory = (viewsDir, controllersDir) ->
                viewsDirectory = viewsDir
                controllersDirectory = controllersDir
            getViewsDirectory = ->
                viewsDirectory
            getControllersDirectory = ->
                controllersDirectory

            setBaseDirectory : setBaseDirectory,
            getViewsDirectory : getViewsDirectory,
            getControllersDirectory: getControllersDirectory
            )()
        @route = ((routeConfig) ->
            resolve = (baseName) ->
                routeDef = {}
                routeDef.templateUrl = routeConfig.getViewsDirectory() + baseName + '.html'
                routeDef.controller = baseName + 'Controller'

                routeDef.resolve =
                    load: ['$q', '$rootScope',
                        ($q, $rootScope) ->
                            dependencies = [routeConfig.getControllersDirectory() + baseName + 'Controller.js']
                            return resolveDependencies $q, $rootScope, dependencies
                    ]
                return routeDef
            resolveDependencies = ($q, $rootScope, dependencies) ->
                defer = $q.defer()
                require dependencies, ->
                    defer.resolve()
                    $rootScope.$apply()
                    defer.promise
                resolve: resolve
        ) (@routeConfig)
