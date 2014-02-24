define [], ->
    services = angular.module 'routeResolverServices', []
    services.provider 'routeResolver', ->
        @$get = ->
            @
        @routeConfig = (->
            viewsDirectory = '/templates/'
            controllersDirectory = '/js/controllers/'
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
            resolve = (baseName, templateName, title, desc) ->
                routeDef = {}
                if templateName is "" or templateName is `undefined`
                    routeDef.templateUrl = routeConfig.getViewsDirectory() + baseName + '.html'
                else
                    routeDef.templateUrl = templateName
                routeDef.controller = baseName + 'Controller'
                routeDef.title = title
                routeDef.desc = desc

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
        return