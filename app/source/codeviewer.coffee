'use strict'

angular.module('gdbGuiApp')
  .filter 'splitLines', ->
    return (str) -> str?.split('\n')

  .directive 'codeViewer', -> {
    # sorry for the weird formatting, but html
    # will show newlines between the pre/spans
    template: '''
        <div
            ng-show="code != null"
            ng-repeat="line in code|splitLines track by $index"
            class="line selected-{{$index+1==highlight}}">
            <span class="lineno">{{$index+1}}</span>
            <span class="code">{{line}}</span>
        </div>
    '''
    restrict: 'E'
    scope: {
        code: '=code'
        highlight: '=highlight'
    }
    link: (scope, element, attrs) ->
  }
