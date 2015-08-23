os = require 'os'
path = require 'path'
away = require 'away'

Action = require './backupper-action'

module.exports = Backupper =

  config:
    sevePath:
      title: 'Save path'
      type: 'string'
      default: path.join( os.tmpdir(), 'atom', 'backupper' )
    idleTime:
      title: 'Idle time.'
      type: 'integer'
      description: 'minute time.(3>)'
      minimum: 3
      default: 3

  activate: (state) ->
    act = new Action()

    timer = away @convertTime(atom.config.get 'backupper.idleTime')
    timer.on 'idle', -> act.save()

    atom.commands.add 'atom-workspace', 'backupper:recover': ->
      act.recover()

  convertTime: (time) ->
    time = 3 if time < 3
    time *= 60000
