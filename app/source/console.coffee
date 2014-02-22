'use strict'

angular.module('gdbGuiApp')
  .directive 'console', -> {
    # sorry for the weird formatting, but html
    # will show newlines between the pre/spans
    template: '''<div>
        <pre class="console"><span
            ng-repeat="line in log"
            class="pipe-{{line.from}}"
            >{{line.data}}</span><span
                contenteditable="true"
                class="console-input-line"
            ></span></pre>
        </div>'''
    restrict: 'E'
    replace: true
    scope: {
        log: '=log'
        sendline: '=sendline'
    }
    link: (scope, element, attrs) ->
        input_line = element.find('.console-input-line')

        do_sendline = ->
            line = input_line.text() + '\n'
            scope.sendline(line)
            scope.log.push {data: line, from: 'direct-input'}
            input_line.text('')

        input_line.keydown (e) ->
            # on enter
            if e.keyCode == 13
                scope.$apply -> do_sendline()
                return false

        element.click -> input_line.focus()
        element.focus -> input_line.focus()
  }
