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

app.get '/app-state', (req, res) ->
	gdb.getStack (stack) ->
		res.send(stack)
