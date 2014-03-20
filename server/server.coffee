debounce = require('debounce')
express = require('express')
app = express()
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.static(__dirname + '/../app'))
server = require('http').createServer(app)
io = require('socket.io').listen(server)
io.set 'log level', 0


## Expose program information
program_state = {}

app.get '/proc_state', (req, res) ->
  res.send(program_state)

io.sockets.on 'connection', (socket) ->
  socket.emit('app_state_change', program_state)

max_push_rate = 1#ms
push_prgram_state = debounce((->
  io.sockets.emit('app_state_change', program_state)
), max_push_rate)

set_program_state = (state) ->
  program_state = state
  push_prgram_state()


## Manage gdb
os161 = require './os161.coffee'
gdb = null

update_program_state = (continuation) ->
  gdb.getProgramState (state) ->
    set_program_state(state)
    continuation()


## Serialize gdb interactions
# use a queue of gdb interactions
# invariant: gdb is_busy() OR gdb_interaction_queue.length == 0
# design: we're assuming that all interactions with gdb goes
# through run_gdb_queue.
gdb_interaction_queue = []

gdb_interaction = (interaction, callback) ->
  gdb_interaction_queue.push {interaction, callback}
  run_gdb_queue() unless gdb.is_busy()

run_gdb_queue = ->
  if gdb_interaction_queue.length > 0
    next = gdb_interaction_queue.shift()
    {interaction, callback} = next
    execute_gdb_interaction interaction, ->
      callback()

      # repeat until we've exhausted the queue
      run_gdb_queue()

execute_gdb_interaction = (interaction, callback) ->
  interaction ->
    update_program_state ->
      callback()

expose_gdb = (url, interaction) ->
  app.post url, (req, res) ->
    gdb_interaction(
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

app.post '/gdb_kill', (req, res) ->
  gdb.kill ->
    console.log "gdb killed"
    res.send(true)

# A bit hacky, but we need to be able to update
# proc output even when gdb is blocking
push_proc_output = ->
  program_state.proc_history = gdb.debugged_program.ipc_history
  program_state.gdb_history = gdb.ipc_history
  push_prgram_state()


## Expose source code
# this may be the beginning of something much greater...
app.use('/source', express.static(os161.source_root))

# wait until gdb is ready before opening to http requests
os161.launch_gdb (_gdb) ->
  gdb = _gdb

  gdb.debugged_program.on 'stdout-data', push_proc_output
  gdb.debugged_program.on 'stderr-data', push_proc_output

  update_program_state ->
    server.listen(3000)
    console.log "listening on port 3000"
