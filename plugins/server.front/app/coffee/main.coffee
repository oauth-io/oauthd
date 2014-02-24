require.config
    baseUrl: '/js'

require [
    'app',
    'services/routeResolver'
], ->
    angular.bootstrap document, ['oauth']
    return