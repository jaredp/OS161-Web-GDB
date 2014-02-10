express = require('express')
app = express()
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());

os161 = require './os161.coffee'
gdb = null

# wait until gdb is ready before opening to http requests
os161.launch_gdb (_gdb) ->
	gdb = _gdb
	app.listen(3000)
	console.log "listening on port 3000"

## Expose source code
# this may be the beginning of something much greater...
app.use('/source', express.static(os161.source_root))

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

