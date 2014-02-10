color = require 'colors'
_ = require 'underscore'
_.str = require 'underscore.string'
async = require 'async'

exports.RecordedProcess = class RecordedProcess
	constructor: (@proc) ->
		@ipc_history = []

		# FIXME: stderr sometimes appears out of order
		@proc.stdout.on 'data', (data) => @add_to_rpc_history('stdout', data.toString())
		@proc.stderr.on 'data', (data) => @add_to_rpc_history('stderr', data.toString())

	send: (data) ->
		@proc.stdin.write data
		@add_to_rpc_history('stdin', data)

	add_to_rpc_history: (from, data) ->
		@ipc_history.push {data, from}
		#@print_ipc_history()

	print_ipc_history: ->
		console.log "ipc history:"
		for {data, from} in @ipc_history
			color = {stdout: 'white', stderr: 'red', stdin: 'blue'}[from]
			process.stdout.write data[color]

	ipcHistoryOn: (chann)->
		(log.data for log in @ipc_history when log.from == chann).join()


###
Design:
-One command at a time
-Read from gdb.stdout until propmt
-Emit output between prompts as results of last command

Concerns:
-What happens if we get a prompt and then more?
-What happens if we want to send a command while another one is running?
	-we should buffer it, run next
	-throw for now
###

exports.GDB = class GDB extends RecordedProcess
	# debugged_program :: RecordedProcess, *NOT* process

	constructor: (@proc, @debugged_program, ready_handler) ->
		super(@proc)

		@output_buffer = ''
		#TODO: error buffer from stderr
		@next_handler = null

		#TODO: can't rely on newline, so we should change the prompt
		# to something reasonably unique
		# however, we then have to possibly strip a newline from the output
		# It's possible the newline is only omited if we ended stderr with a
		# newline.
		@gdb_prompt = '(gdb) '

		@proc.stdout.on 'data', (data) =>
			@output_buffer += data.toString()

			if _.str.endsWith(@output_buffer, @gdb_prompt)
				# consume results
				results = @output_buffer.slice(0, -@gdb_prompt.length)
				@output_buffer = ''

				# get the handler, if there is one
				if handler = @next_handler
					# clear the handler first, so we it doesn't
					# think we're in the middle of another command
					@next_handler = null

					# call the handler
					handler(results)

		@next_handler = => # wait until prompt
			@initialize =>
				ready_handler()

	initialize: (callback) ->
		@command 'set height 100000', =>
			@command 'set width 100000', =>
				@command 'set pagination off', =>
					callback()

	command: (code, callback) ->
		throw new Error "gdb is in the middle of another command" if @next_handler
		@next_handler = callback
		@send(code + '\n')

	####
	# Stack inspection
	##
	getBacktrace: (callback) ->
		@command 'bt', (backtrace) ->
			frames = []
			for line in backtrace.trim().split('\n')
				match = line.match(/^#(\d+)\s+(?:(.+) in )?(.+) \((.*)\) at (.+):(\d+)$/)
				if match?
					[input, frame, hex_loc, func, args, file, line] = match
					frames.push {
						frame: Number(frame),
						hex_loc, func, args,
						file, line: Number(line)
					}
			callback(frames)

	getLocalsInCurrentFrame: (callback) ->
		@command 'info locals', (locals) =>
			vars = []
			for line in locals.trim().split('\n')
				match = line.match(/^(.+) = (.+)$/)
				if match?
					[input, variable, value] = match
					vars.push {variable, value}
			callback(vars)

	setFrame: (frame, callback) ->
		@command "f #{frame}", callback

	getLocals: (frame, callback) ->
		@setFrame frame, => @getLocalsInCurrentFrame callback

	getStack: (callback) ->
		@getBacktrace (backtrace) =>
			async.eachSeries(backtrace, ((traceframe, finished) =>
				@getLocals traceframe.frame, (locals) =>
					traceframe.locals = locals
					finished()
			), (->
				callback(backtrace)
			))

	####
	# Control handling
	##
	setBreakpoint: (location, callback) ->
		@command "b #{location}", callback

	continueExecution: (callback) ->
		@command 'c', callback

