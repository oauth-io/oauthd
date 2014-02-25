define [], () ->
    NotificationService = ($rootScope) ->
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
                modalInstance = $modal.open
                    templateUrl: '/templates/partials/notifications.html'
                    controller: NotificationCtrl
                    resolve: {
                    }
        }
    return ['$rootScope', NotificationService]