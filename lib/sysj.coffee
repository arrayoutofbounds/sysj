SysjView = require './sysj-view'
{CompositeDisposable} = require 'atom'


module.exports = Sysj =
  sysjView: null
  #modalPanel: null
  subscriptions: null

  activate: (state) ->
    @sysjView = SysjView.get(state.sysjViewState)

    #@modalPanel = atom.workspace.addModalPanel(item: @sysjView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
    'sysj:compile': => @compile()
    'sysj:run': => @run()
    #'sysj:toggle': => @toggle()


  deactivate: ->
    #@modalPanel.destroy()
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

    packagePath = ""
    paths = atom.packages.getAvailablePackagePaths()



    findsysj = (p) ->
      (
        if (p.indexOf("sysj") > -1)
          packagePath = packagePath + p
          console.log packagePath
      )
    findsysj p for p in paths

    pathToJar = packagePath + "/jar/*"
    console.log pathToJar
    command = 'java -classpath \"' + pathToJar +  '\" JavaPrettyPrinter ' + filePath
    #exec = require('sync-exec')
    #console.log(exec('/home/anmol/Desktop/Research/sjdk-v2.0-151-g539eeba/bin/sysjc',['' + filePath]));
    console.log command
    ## get sysjc with exec command
    {exec} = require('child_process')
    exec(command , (err, stdout, stderr) ->
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

    #'/home/anmol/Desktop/Research/sjdk-v2.0-151-g539eeba/bin/sysjc ' + filePath


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
    #console.log 'run'
    #if (false)
    #  @sysjView.setText("Ran successfully")
    #else
    #  @sysjView.setText("Failed to run")
    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath
    dir = filePath.substring(0,filePath.lastIndexOf("/"))
    console.log "dir is " + dir

    packagePath = ""
    paths = atom.packages.getAvailablePackagePaths()



    findsysj = (p) ->
      (
        if (p.indexOf("sysj") > -1)
          packagePath = packagePath + p
          console.log packagePath
      )
    findsysj p for p in paths

    pathToJar = packagePath + "/jar/*"
    console.log pathToJar

    a = 1
    @OSName = ""
    if (navigator.appVersion.indexOf("Win")!=-1)
      @OSName="Windows"
      a = 1
    if (navigator.appVersion.indexOf("Mac")!=-1)
      @OSName="MacOS"
      a = 0
    if (navigator.appVersion.indexOf("X11")!=-1)
      @OSName="UNIX"
      a = 0
    if (navigator.appVersion.indexOf("Linux")!=-1)
      @OSName="Linux"
      a = 0

    @pathToClass = ""
    if (a)
      @pathToClass = ";" + dir + "/"
    else
      @pathToClass = ":" + dir + "/"

    command = 'java -classpath \"' + pathToJar + @pathToClass +  '\" com.systemj.SystemJRunner ' + filePath

    #console.log "command is " + command

    #'-classpath','\"' + pathToJar + @pathToClass + '\"', 'com.systemj.SystemJRunner',filePath

    { spawn } = require 'child_process'
    @sysjr = spawn("java",["-classpath", "" + pathToJar + @pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
    @sysjr.stdout.on 'data', (data ) ->    SysjView.get().printOutput("#{data}") #atom.notifications.addSuccess "Run successful", detail: "#{data}"
    @sysjr.stderr.on 'data', ( data ) ->   atom.notifications.addError "Run failed", detail: "#{data}"
    @sysjr.on 'close', -> console.log "sysj program has finished executing."


    ##{exec} = require('child_process')
    #exec(command , (err, stdout, stderr) ->
    #   (
    #     if (stderr)
    #        #console.log("child processes failed with error code: " + err.code)
    #        atom.notifications.addError "Run failed", detail: stderr
    #      else
    #        atom.notifications.addSuccess "Run successful"
    #        console.log "err is " + err
    #        console.log "stdout is " +  stdout
    #        console.log("stdout is " + stdout)
    #        console.log(stdout)
    #        atom.notifications.addInfo "err is ", detail: err
    #   )
    #)

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
