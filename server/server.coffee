express = require('express')
app = express()
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.static(__dirname + '/../app'))
server = require('http').createServer(app)
io = require('socket.io').listen(server)
io.set 'log level', 0

os161 = require './os161.coffee'

gdb = null
program_state = {}

io.sockets.on 'connection', (socket) ->
  socket.emit('app_state_change', program_state)

set_program_state = (state) ->
  program_state = state
  io.sockets.emit('app_state_change', program_state)

update_program_state = (continuation) ->
  gdb.getProgramState (state) ->
    set_program_state(state)
    continuation()

# wait until gdb is ready before opening to http requests
os161.launch_gdb (_gdb) ->
  gdb = _gdb
  update_program_state ->
    server.listen(3000)
    console.log "listening on port 3000"

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

## Expose source code
# this may be the beginning of something much greater...
app.use('/source', express.static(os161.source_root))


## Inspect program
app.get '/proc_state', (req, res) ->
  res.send(program_state)


## Mangage breakpoints
app.post '/add_breakpoint', (req, res) ->
  gdb_interaction(
    ((c)-> gdb.setBreakpoint(req.body.breakpoint, c)),
    (-> res.send(true))
  )


## Control program
app.post '/continue', (req, res) ->
  gdb_interaction(
    ((c)-> gdb.continueExecution(c)),
    (-> res.send(true))
  )

app.post '/step', (req, res) ->
  gdb_interaction(
    ((c)-> gdb.stepIntoLine(c)),
    (-> res.send(true))
  )

app.post '/next', (req, res) ->
  gdb_interaction(
    ((c)-> gdb.runNextLine(c)),
    (-> res.send(true))
  )

app.post '/finish', (req, res) ->
  gdb_interaction(
    ((c)-> gdb.finishFunction(c)),
    (-> res.send(true))
  )
