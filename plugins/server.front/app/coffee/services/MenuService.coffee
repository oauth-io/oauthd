define ["app"], (app) ->
    app.register.factory 'MenuService', ($http, $rootScope) ->
        $rootScope.selectedMenu = $location.path()

        return changed: ->
            p = $location.path()

            if ['/signin','/signup','/help','/feedback','/faq','/pricing'].indexOf(p) != -1 or p.substr(0, 8) == '/payment'
                $('body').css('background-color', "#FFF")
            else
                $('body').css('background-color', '#FFF')

            $('body > .navbar span, #footer').css('color', '#777777')
            $('#wsh-powered').attr('src', '/img/webshell-logo.png')
            $('body > .navbar li a').css('color', '#777777').css('font-weight', 'normal')

            $rootScope.selectedMenu = $location.path()