{spawn} = require 'child_process'
{RecordedProcess, GDB} = require './gdbcontroller.coffee'
_ = require 'underscore'
_.str = require 'underscore.string'
path = require 'path'

exports.compile_root = compile_root = '/home/jharvard/cs161/os161/kern/compile/ASST0'
exports.kernel_root = kernel_root = '/home/jharvard/cs161/root'
exports.source_root = source_root = '/home/jharvard/cs161/os161'

rebase_path = (compile_relative_path) ->
  return path.relative(
    source_root,
    path.resolve(
      compile_root,
      compile_relative_path
    )
  )

class OS161_GDB extends GDB
  getBacktrace: (callback) ->
    super (frames) ->
      for frame in frames
        frame.file = rebase_path(frame.file)
      callback(frames)

spawnKernel = (callback) ->
  kernel_proc = spawn('sys161', ['-w', 'kernel'], {cwd: kernel_root})
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
    gdb_proc = spawn('os161-gdb', ['kernel'], {cwd: kernel_root})
    gdb = new OS161_GDB(gdb_proc, kernel, -> callback(gdb))

exports.launch_gdb = spawnGDB
