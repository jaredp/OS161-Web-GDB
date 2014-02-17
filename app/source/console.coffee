'use strict'

angular.module('gdbGuiApp')
  .directive 'console', -> {
    template: '''<div>
    	<pre class="console"><span
    		ng-repeat="line in log"
    		class="pipe-{{line.from}}"
    		>{{line.data}}</pre>
    	</div>'''
    restrict: 'E'
    replace: true
    scope: {
    	'log': '=log'
    }
    link: (scope, element, attrs) ->

  }
