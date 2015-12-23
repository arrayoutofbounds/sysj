SysjView = require './sysj-view'
{CompositeDisposable} = require 'atom'


module.exports = Sysj =
  sysjView: null
  modalPanel: null
  subscriptions: null
  dialogView: null
  flag: false
  clickHappened:false

  getModalPanel: ->
    @modalPanel

  activate: (state) ->
    @sysjView = SysjView.get(state.sysjViewState)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
    'sysj:compile': => @showCompileDialog()
    'sysj:run': => @run()
    'sysj:kill': => @kill()
    'sysj:create': => @create()
    #'sysj:toggle': => @toggle()

    SysjView.get().setChildren(0) # set to 0 when syjs package is loaded


  showCompileDialog: ->
    console.log "show dialog method is run"
    DialogView = require './dialog-view'
    @dialogView = new DialogView()
    @modalPanel = atom.workspace.addModalPanel(item: @dialogView.getElement(), visible: false)

    @dialogView.toAppend = ""

    if !@modalPanel.isVisible()
      @modalPanel.show()


  consumeConsolePanel: (consolePanel) ->
    @consolePanel = consolePanel
    SysjView.get().setConsolePanel(@consolePanel)

  deactivate: ->
    #@modalPanel.destroy()
    @subscriptions.dispose()
    @subscriptions = null
    @sysjView.destroy()

  serialize: ->
    sysjViewState: @sysjView.serialize()

  create: ->
    fs = require('fs')
    remote = require 'remote'
    dialog  = remote.require 'dialog'
    directoryChosen =  dialog.showOpenDialog({properties:['openDirectory']}) # the user can create a directory and return it

    # create the directories needed for a project
    fs.mkdir(directoryChosen + "/source")
    fs.mkdir(directoryChosen + "/class")
    fs.mkdir(directoryChosen + "/config")
    fs.mkdir(directoryChosen + "/java")
    fs.mkdir(directoryChosen + "/projectSettings")
    fs.writeFile(directoryChosen + "/projectSettings/compileOptions.json", "{}", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    fs.writeFile(directoryChosen + "/projectSettings/pathsToExternalLibraries.txt", "", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    atom.project.addPath(directoryChosen + "")
    atom.reload()

    #editor = atom.workspace.getActivePaneItem()
    #file = editor?.buffer.file
    #filePath = file?.path
    #console.log filePath

  kill: ->
    # get the parent pid from the env and then kill it using sigterm
    terminate = require("terminate")
    console.log process.env['parent']
    terminate process.env['parent'],(err,done) ->
      if err
        console.log "oops " + err
      else
        console.log done
        SysjView.get().setChildren(0)
        console.log "children set to 0 so that sysj xml can be run again"
      return


  organise: (dir) ->
    # this function organises the project as required

    # move the java files from the class folder to a java folder
    classFolderPath = dir + "/class"
    javaFolderPath = dir + "/java"
    configFolderPath = dir + "/config"
    console.log "config path is " + configFolderPath
    fs = require('fs')

    dirExists = (d) ->
      fs = require("fs")
      try
        fs.statSync(d).isDirectory()
      catch error
        return false

    if !dirExists(javaFolderPath)
      fs.mkdir(javaFolderPath)

    files = fs.readdirSync classFolderPath # sync read to ensure that all files are collected in an array before moving on
    console.log files
    i = 0
    mv = require("mv")
    path = require('path')
    while i < files.length
      #console.log files[i]
      if (files[i].indexOf(".xml") > -1)
        mv classFolderPath + path.sep + files[i], configFolderPath + path.sep + files[i], (err) ->
          if err
            console.error err
          return

      # if the file has a ".java" then move it to the java folder
      if ( files[i].indexOf(".java") > -1)
        mv classFolderPath + path.sep + files[i],javaFolderPath + path.sep + files[i], (err) ->
          if err
            console.error err
          return
      i++
    return


  ## compile the current file and then get the output
  compile: (toAppend) ->
    #testing this method via console
    #console.log 'compiled'
    #if (true)
    #  @sysjView.setText("Compiled successfully")
    #else
    #  @sysjView.setText("Failed to compile")


    #console.log "click happened is " + @clickHappened

    #console.log "dialog view is " + @dialogView


    ###
    foo =  =>
      console.log "dialog view inside is " + #@dialogView
      console.log "click happened is " + #@clickHappened
      if #@clickHappened == false
        setTimeout foo,1000
      return

    foo()
    ###

    #console.log "after waiting is " + @clickHappened

    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath

    packagePath = ""
    paths = atom.packages.getAvailablePackagePaths()
    dirToConfig = filePath.substring(0,filePath.lastIndexOf("/"))
    dir = dirToConfig.substring(0,dirToConfig.lastIndexOf("/"))

    console.log "dirToConfig is " + dirToConfig
    console.log "dir is " + dir

    process.chdir(dir)


    findsysj = (p) ->
      (
        if (p.indexOf("sysj") > -1)
          packagePath = packagePath + p
          console.log packagePath
      )
    findsysj p for p in paths

    pathToJar = packagePath + "/jar/*"
    console.log pathToJar

    # this moves the class and java compiled files to the class folder
    command = 'java -classpath \"' + pathToJar +  '\" JavaPrettyPrinter -d ' + dir + '/class ' + toAppend + " " + filePath

    #exec = require('sync-exec')
    #console.log(exec('/home/anmol/Desktop/Research/sjdk-v2.0-151-g539eeba/bin/sysjc',['' + filePath]));
    console.log command
    ## get sysjc with exec command

    #spawnSync = require('spawn-sync')
    #result = spawnSync('java',['-classpath',"" + pathToJar,'JavaPrettyPrinter','-d',""+dir,'/class',""+filePath,"1>" + console.log ,"2>" + console.log ])

    doSomething = (organise,dir) ->

      {exec} = require('child_process')
      exec(command, (err, stdout, stderr) ->
          (
           if (stderr)
              #console.log("child processes failed with error code: " + err.code)
              atom.notifications.addError "Compilation failed", detail: stderr
              SysjView.get().getConsolePanel().warn(stderr)
            else
              atom.notifications.addSuccess "Compilation successful", detail: stdout
              SysjView.get().getConsolePanel().log(stdout,level="info")
              organise dir
              #console.log(stdout)
              #atom.notifications.addInfo "err is ", detail: err
              )
          )

    doSomething(@organise,dir)

    #@organise dir # this function will organise the files itn the project

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
    dirToConfigFolder = filePath.substring(0,filePath.lastIndexOf("/"))
    dir = dirToConfigFolder.substring(0,dirToConfigFolder.lastIndexOf("/"))
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
      @pathToClass = ";" + dir + "/class/"
    else
      @pathToClass = ":" + dir + "/class/"

    command = 'java -classpath \"' + pathToJar + @pathToClass +  '\" com.systemj.SystemJRunner ' + filePath

    #console.log "command is " + command

    #'-classpath','\"' + pathToJar + @pathToClass + '\"', 'com.systemj.SystemJRunner',filePath
    process.env['parent'] = process.pid
    console.log process.env['parent']
    console.log "children are " + SysjView.get().getChildren()

    if (SysjView.get().getChildren() == 0)
      console.log "entered here"
      { spawn } = require 'child_process'
      @sysjr = spawn("java",["-classpath", "" + pathToJar + @pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
      SysjView.get().setChildren(1)
      console.log "children are " + SysjView.get().getChildren()
      @sysjr.stdout.on 'data', (data ) ->  SysjView.get().getConsolePanel().log("#{data}",level="info")#SysjView.get().printOutput("#{data}")
      #console.log process.pid
      #console.log @sysjr.pid
      @sysjr.stderr.on 'data', ( data ) -> SysjView.get().getConsolePanel().error("#{data}")  #atom.notifications.addError "Run failed", detail: "#{data}"
      @sysjr.on 'close', ->
        SysjView.get().getConsolePanel().notice("sysj program has finished executing")#console.log "sysj program has finished executing." + process.id
        SysjView.get().setChildren(0)
      @sysjr.on 'exit', ->
        SysjView.get().getConsolePanel().notice("sysj program has finished executing")#console.log "sysj program has finished executing." + process.id
        SysjView.get().setChildren(0)
    else
      SysjView.get().getConsolePanel().log("there is already one child and wait till it finishes",level="info")#console.log "there is already one child and wait till it finishes"

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
