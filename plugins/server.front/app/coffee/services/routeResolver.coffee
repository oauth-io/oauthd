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
                if templateName is `undefined` or templateName is ""
                    routeDef.templateUrl = routeConfig.getViewsDirectory() + baseName.toLowerCase() + '.html'
                else
                    routeDef.templateUrl = templateName
                routeDef.controller = baseName + 'Ctrl'
                routeDef.title = title
                routeDef.desc = desc

                routeDef.resolve =
                    load: ['$q', '$rootScope',
                        ($q, $rootScope) ->
                            dependencies = [routeConfig.getControllersDirectory() + baseName + 'Ctrl.js']
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