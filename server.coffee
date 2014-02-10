express = require('express')
app = express()
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());

launch_gdb = require './os161-gdbcontroller.coffee'
gdb = null
launch_gdb (_gdb) ->
	gdb = _gdb
	app.listen(3000)
	console.log "listening on port 3000"

## Inspect program
app.get '/backtrace', (req, res) ->
	gdb.getStack (stack) ->
		res.send(stack)

app.get '/gdb_history', (req, res) ->
	res.send(gdb.ipc_history)

app.get '/proc_history', (req, res) ->
	res.send(gdb.debugged_program.ipc_history)


## Mangage breakpoints
app.get '/breakpoints', (req, res) ->
	gdb.getBreakpoints (breakpoints) ->
		res.send(breakpoints)

app.post '/add_breakpoint', (req, res) ->
	gdb.setBreakpoint req.body.breakpoint, ->
		res.send(true)


# Control program
app.post '/continue', (req, res) ->
	gdb.continueExecution ->
		res.send(true)

app.post '/step', (req, res) ->
	gdb.stepIntoLine ->
		res.send(true)

app.post '/next', (req, res) ->
	gdb.runNextLine ->
		res.send(true)

app.post '/finish', (req, res) ->
	gdb.finishFunction ->
		res.send(true)
