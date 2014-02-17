'use strict'

angular.module('gdbGuiApp')
  .controller 'MainCtrl', ($scope, $http) ->
    socket = io.connect('/', {reconnect: true})
    socket.on 'app_state_change', (data) -> $scope.$apply ->
        $scope.app_state = data

    $scope.http_post = (url, data = {}) ->
      $http({url, data, method: 'POST'})

    $scope.add_breakpoint = ->
      $scope.http_post('/add_breakpoint', {
        "breakpoint": "menu_execute"
      })
