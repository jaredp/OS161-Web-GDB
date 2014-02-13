'use strict'

angular.module('gdbGuiApp')
  .controller 'MainCtrl', ($scope, $http) ->
  	$scope.refresh = ->
  		$http({url: '/proc_state', method: 'GET'}).success (data) ->
  			$scope.app_state = data

  	$scope.state_json = ->
  		JSON.stringify($scope.app_state, null, '\t')

  	$scope.add_breakpoint = ->
  		$http({
  			url: '/add_breakpoint'
  			method: 'POST'
  			data: {"breakpoint": "menu_execute"}
  		}).success -> $scope.refresh()

  	$scope.continue_execution = ->
  		$http({
  			url: '/continue'
  			method: 'POST'
  			data: {}
  		}).success -> $scope.refresh()

  	$scope.run_next_line = ->
  		$http({
  			url: '/next'
  			method: 'POST'
  			data: {}
  		}).success -> $scope.refresh()

  	$scope.refresh()