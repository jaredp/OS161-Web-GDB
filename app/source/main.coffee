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

    $scope.send_gdb_command = (command) ->
      $scope.http_post('/gdb_command', {command});

    $scope.send_proc_input = (input) ->
      $scope.http_post('/proc_input', {input});

    $http.get('/source/kern/main/menu.c')
      .success (data) ->
        $scope.selected_frame = {
          file: {
            contents: data
          }
          line: 694
        }
