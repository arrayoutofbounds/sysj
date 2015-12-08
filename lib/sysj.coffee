SysjView = require './sysj-view'
{CompositeDisposable} = require 'atom'


module.exports = Sysj =
  sysjView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @sysjView = new SysjView(state.sysjViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @sysjView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
    'sysj:compile': => @compile()
    'sysj:run': => @run()
    #'sysj:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @sysjView.destroy()

  serialize: ->
    sysjViewState: @sysjView.serialize()

  ## compile the current file and then get the output
  compile: ->
    #testing this method via console
    #console.log 'compiled'
    #if (true)
    #  @sysjView.setText("Compiled successfully")
    #else
    #  @sysjView.setText("Failed to compile")

    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath

    #exec = require('sync-exec')
    #console.log(exec('/home/anmol/Desktop/Research/sjdk-v2.0-151-g539eeba/bin/sysjc',['' + filePath]));

    ## get sysjc with exec command
    {exec} = require('child_process')
    exec('/home/anmol/Desktop/Research/sjdk-v2.0-151-g539eeba/bin/sysjc ' + filePath, (err, stdout, stderr) ->
       (
         if (stderr)
            #console.log("child processes failed with error code: " + err.code)
            atom.notifications.addError "Compilation failed", detail: stderr
          else
            atom.notifications.addSuccess "Compilation successful", detail: stdout
            #console.log(stdout)
            #atom.notifications.addInfo "err is ", detail: err
       )
    )



    # get sysjc with node-cmd. This is run async....so both happen at any time.
    #cmd=require('node-cmd');
    #cmd.get(
    #    'sysjc ' + filePath,
    #    (data) -> console.log("node-cmd used:" + data)
    #)

    #exec('sysjc ' + filePath, (err, stdout, stderr) ->
    #   (if (err) then console.log("child processes failed with error code: " + err.code) else console.log(stdout))
    #)

    ##{ spawn } = require 'child_process'
    #sysjc = spawn('sysjc',['filePath'])
    #sysjc.stdout.on 'data', (data) -> atom.notifications.addSuccess "#{data}"
    #sysjc.stderr.on 'data', (data) -> atom.notifications.addError "#{data}"

    ##{ spawn } = require 'child_process'
    #ls = spawn 'ls'
    #ls.stdout.on 'data', ( data ) -> console.log "Output: #{ data }"
    #ls.stderr.on 'data', ( data ) -> console.error "Error: #{ data }"
    #ls.on 'close', -> console.log "'ls' has finished executing."

    #if @modalPanel.isVisible()
    #  @modalPanel.hide()
    #else
    #  @sysjView.setText("Compiled")
    #  @modalPanel.show()

  # run the currently open file..which is the xml file and get the output
  run: ->
    console.log 'run'
    if (false)
      @sysjView.setText("Ran successfully")
    else
      @sysjView.setText("Failed to run")
    #if @modalPanel.isVisible()
    #  @modalPanel.hide()
    #else
    #  @sysjView.setText("Ran successfully")
    #  @modalPanel.show()
###
    toggle: ->
      console.log 'Sysj was toggled!'

      if @modalPanel.isVisible()
        @modalPanel.hide()
      else
        @modalPanel.show()
  ###
