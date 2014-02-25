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
        "breakpoint": "cmd_dispatch"
      })

    $scope.send_gdb_command = (command) ->
      $scope.http_post('/gdb_command', {command});

    $scope.send_proc_input = (input) ->
      $scope.http_post('/proc_input', {input});

    $scope.sourceCache = {}

  .filter 'sourceFileContents', ($http) ->
    # define a sentinal value so we don't re-request
    # the same resource while it's already being fetched
    file_is_being_fetched = null

    return (file, cache) ->
      # if file is undefined, return null
      return null unless file?

      # if the file is in the cache, return it!
      return cache[file] if cache[file]?

      # return null while the file is being fetched
      return null if cache[file] == file_is_being_fetched

      # cache miss on file:
      cache[file] = file_is_being_fetched
      $http.get("/source/#{file}").success (data) ->
        cache[file] = data
      return null
