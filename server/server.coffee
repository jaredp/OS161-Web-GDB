async = require('async')
debounce = require('debounce')
express = require('express')
socketio = require('socket.io')
os161 = require('./os161.coffee')


## Server configuration
app = express()
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.static(__dirname + '/../app'))
server = require('http').createServer(app)
io = socketio.listen(server)
io.set('log level', 0)


## program global state
gdb = null
program_state = {}


## Expose state information
app.get '/proc_state', (req, res) ->
  res.send(program_state)

io.sockets.on 'connection', (socket) ->
  socket.emit('app_state_change', program_state)

max_push_rate = 1#ms
push_program_state = debounce((->
  io.sockets.emit('app_state_change', program_state)
), max_push_rate)

update_program_state = (callback) ->
  gdb.getProgramState (state) ->
    program_state = state
    push_program_state()
    callback()


## Serialize gdb interactions
gdb_queue = async.queue (task, done) ->
    task ->
      update_program_state ->
        done()

launch_gdb = (callback) ->
  os161.launch_gdb (_gdb) ->
    gdb = _gdb

    gdb.debugged_program.on 'stdout-data', push_proc_output
    gdb.debugged_program.on 'stderr-data', push_proc_output

    update_program_state ->
      callback()


## Template for interacting with gdb over http
expose_gdb = (url, interaction) ->
  app.post url, (req, res) ->
    gdb_queue.push(
      (cb) -> interaction(cb, req.body),
      (-> res.send(true))
    )


## Mangage breakpoints
expose_gdb '/add_breakpoint', (cb, {breakpoint}) ->
  gdb.setBreakpoint(breakpoint, cb)


## Control program
expose_gdb '/continue', (cb) ->
  gdb.continueExecution(cb)

expose_gdb '/step', (cb, {frame}) ->
  gdb.stepIntoLine(frame, cb)

expose_gdb '/next', (cb, {frame}) ->
  gdb.runNextLine(frame, cb)

expose_gdb '/finish', (cb, {frame}) ->
  gdb.finishFunction(frame, cb)


## Interact with processes
expose_gdb '/gdb_command', (cb, {command}) ->
  gdb.command(command.trim(), cb)

app.post '/proc_input', (req, res) ->
  gdb.debugged_program.send(req.body.input)
  res.send(true)

expose_gdb '/gdb_restart', (cb) ->
  gdb.kill ->
    launch_gdb(cb)

# A bit hacky, but we need to be able to update
# proc output even when gdb is blocking
push_proc_output = ->
  program_state.proc_history = gdb.debugged_program.ipc_history
  program_state.gdb_history = gdb.ipc_history
  push_program_state()


## Expose source code
# this may be the beginning of something much greater...
app.use('/source', express.static(os161.source_root))

# wait until gdb is ready before opening to http requests
launch_gdb ->
  server.listen(3000)
  console.log "listening on port 3000"
