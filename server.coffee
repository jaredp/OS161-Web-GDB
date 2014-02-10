{spawn} = require 'child_process'
{RecordedProcess, GDB} = require './gdbcontroller.coffee'
_ = require 'underscore'
_.str = require 'underscore.string'

spawnKernel = (callback) ->
	kernel_proc = spawn('sys161', ['-w', 'kernel'], {cwd: '/home/jharvard/cs161/root'})
	kernel = new RecordedProcess(kernel_proc)

	check_if_waiting_for_debugger = ->
		stderr = kernel.ipcHistoryOn('stderr')
		waiting_signal = '\nsys161: Waiting for debugger connection...\n'
		if _.str.contains(stderr, waiting_signal)
			# stop listening
			kernel_proc.stderr.removeListener 'data', check_if_waiting_for_debugger

			# return the kernel proc
			callback(kernel)

	kernel_proc.stderr.on 'data', check_if_waiting_for_debugger

spawnGDB = (callback) ->
	spawnKernel (kernel) ->
		gdb_proc = spawn('os161-gdb', ['kernel'], {cwd: '/home/jharvard/cs161/root'})
		gdb = new GDB(gdb_proc, kernel, -> callback(gdb))

spawnGDB (gdb) ->
	gdb.setBreakpoint 'menu_execute', ->
		gdb.continueExecution ->
			gdb.getStack (stack) ->
				console.log JSON.stringify(stack, null, '  ')
				#gdb.print_ipc_history()
				process.exit()



