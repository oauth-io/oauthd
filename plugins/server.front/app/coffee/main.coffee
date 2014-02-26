require.config
    baseUrl: '/js'

require [
    'app',
    'utilities/routeResolver'
], ->
    angular.bootstrap document, ['oauth']
    return