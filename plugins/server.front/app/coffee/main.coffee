require.config
    baseUrl: '/js'

require [
    'app'
], ->
    angular.bootstrap document, ['oauth']
    return