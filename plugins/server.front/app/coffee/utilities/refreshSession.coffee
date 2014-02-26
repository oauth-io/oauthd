define ["app"], (app) ->
    window.refreshSession = ($rootScope) ->
        if $rootScope.accessToken
            date = new Date()
            date.setTime date.getTime() - 86400000
            document.cookie = "accessToken=; expires="+date.toGMTString()+"; path=/"
            date = new Date()
            date.setTime date.getTime() + 3600*36*1000
            expires = "; expires="+date.toGMTString()
            document.cookie = "accessToken=%22"+$rootScope.accessToken+"%22"+expires+"; path=/"
            return