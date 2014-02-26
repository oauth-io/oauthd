define [], () ->
    NotificationService = ($rootScope, $modal) ->
        $rootScope.notifications = []
        return {
            push: (notif) ->
                notif.pop = false
                notif.href = '#' if not notif.href
                $rootScope.notifications.push notif
            list: () ->
                return $rootScope.notifications
            clear: () ->
                $rootScope.notifications = []
            open: () ->
                $rootScope.notifModal = modalInstance = $modal.open
                    templateUrl: '/templates/partials/notifications.html'
                    controller: 'NotificationCtrl'
                    resolve: {
                    }
        }
    return ['$rootScope', '$modal', NotificationService]