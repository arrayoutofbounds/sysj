SysjView = require '../lib/sysj-view'
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
    'sysj:compile all': => @compileAll()
    #'sysj:toggle': => @toggle()

    SysjView.get().setChildren(0) # set to 0 when syjs package is loaded


  showCompileDialog: ->
    path = require 'path'
    #console.log path.sep #checks that the path is different for windows and linux
    console.log "show dialog method is run"
    DialogView = require '..' + path.sep + "lib" + path.sep + 'dialog-view'
    @dialogView = new DialogView()
    @modalPanel = atom.workspace.addRightPanel(item: @dialogView.getElement(), visible: false)
    @dialogView.toAppend = ""

    if !@modalPanel.isVisible()
      @modalPanel.show()

  consumeConsolePanel: (consolePanel) ->
    @consolePanel = consolePanel
    SysjView.get().setConsolePanel(@consolePanel)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @subscriptions = null
    @sysjView.destroy()

  serialize: ->
    sysjViewState: @sysjView.serialize()

  create: ->
    fs = require('fs')
    remote = require 'remote'
    dialog  = remote.require 'dialog' # this is for opening the choose dir dialog
    directoryChosen =  dialog.showOpenDialog({properties:['openDirectory']}) # the user can create a directory and return it
    path = require('path')

    # create the directories needed for a project
    fs.mkdir(directoryChosen + path.sep + "source")
    fs.mkdir(directoryChosen + path.sep + "class")
    fs.mkdir(directoryChosen +  path.sep + "config")
    fs.mkdir(directoryChosen + path.sep + "java")
    fs.mkdir(directoryChosen +  path.sep + "projectSettings")
    fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "compileOptions.json", "{}", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt", "", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    console.log "directory chosen is " + directoryChosen
    atom.project.addPath(directoryChosen + "")
    #atom.reload()

    #editor = atom.workspace.getActivePaneItem()
    #file = editor?.buffer.file
    #filePath = file?.path
    #console.log filePath

  kill: ->
    # get the parent pid from the env and then kill it using sigterm
    terminate = require("terminate")
    console.log process.env['parent']

    kill = require('tree-kill')
    kill process.env['child_pid'],'SIGKILL', (err) ->
      if err
        console.log "error occurred is " + err
      else
        SysjView.get().setChildren(0) # set it to 0 so it can run again
        console.log "children set to 0 so that sysj xml can be run again"
      return
    ###
    terminate process.env['parent'],(err,done) ->
      if err
        console.log "oops " + err
      else
        console.log done
        SysjView.get().setChildren(0) # set it to 0 so it can run again
        console.log "children set to 0 so that sysj xml can be run again"
      return
      ###
  organise: (dir) ->
    # this function organises the project as required
    path = require('path')
    # move the java files from the class folder to a java folder
    classFolderPath = dir + path.sep + "class"
    javaFolderPath = dir + path.sep + "java"
    configFolderPath = dir + path.sep + "config"
    console.log "config path is " + configFolderPath
    fs = require('fs')

    # this is a function used later on to check if a directory exists
    dirExists = (d) ->
      fs = require("fs")
      try
        fs.statSync(d).isDirectory()
      catch error
        return false

    # if directory for java folder does not exist then make one
    if !dirExists(javaFolderPath)
      fs.mkdir(javaFolderPath)

    files = fs.readdirSync classFolderPath # sync read to ensure that all files are collected in an array before moving on
    console.log files
    i = 0
    mv = require("mv")
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
    console.log "this process is " + process.pid
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
    path = require('path')
    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath

    packagePath = ""
    paths = atom.packages.getAvailablePackagePaths()
    dirToConfig = filePath.substring(0,filePath.lastIndexOf(path.sep + ""))
    dir = dirToConfig.substring(0,dirToConfig.lastIndexOf(path.sep + ""))

    console.log "dirToConfig is " + dirToConfig
    console.log "dir is " + dir

    process.chdir(dir) # change dir to the working directory so config-gen and other dir specific things work


    findsysj = (p) ->
      (
        if (p.indexOf("sysj") > -1)
          packagePath = packagePath + p
          console.log packagePath
      )
    findsysj p for p in paths

    pathToJar = packagePath + path.sep + "jar" + path.sep + "*"
    console.log pathToJar

    # this moves the class and java compiled files to the class folder
    command = 'java -classpath \"' + pathToJar +  '\" JavaPrettyPrinter -d ' + dir + path.sep + 'class ' + toAppend + " " + filePath

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


  compileAll: ->
    # this method compiles all the sysj files in the source folder

    path = require 'path'
    fs = require('fs')
    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath

    packagePath = "" # package path is the path to the sysj package
    paths = atom.packages.getAvailablePackagePaths()
    dirToConfig = filePath.substring(0,filePath.lastIndexOf(path.sep + "")) # path to the sub folder folder
    dir = dirToConfig.substring(0,dirToConfig.lastIndexOf(path.sep + "")) # path to the overall project folder
    dirToSourceFolder = dir + path.sep + "source" # this ensures that it can get the root directory if any file is open

    console.log "dirToConfig is " + dirToConfig
    console.log "dir is " + dir
    console.log "path to source folder is " + dirToSourceFolder


    findsysj = (p) ->
      (
        if (p.indexOf("sysj") > -1)
          packagePath = packagePath + p
          console.log packagePath
      )
    findsysj p for p in paths # sets the package path to that of the sysj package

    pathToJar = packagePath + path.sep + "jar" + path.sep + "*" # path to jar is the path to package plus the jar folder.
    console.log pathToJar

    files = fs.readdirSync dirToSourceFolder
    console.log files
    i = 0
    allSysjFiles = ""
    while i < files.length
      allSysjFiles = allSysjFiles + dirToSourceFolder + path.sep + files[i] + " "
      i++


    # go through the source folder and append the file path of each file


    # this moves the class and java compiled files to the class folder
    command = 'java -classpath \"' + pathToJar +  '\" JavaPrettyPrinter -d ' + dir + path.sep + 'class ' +  allSysjFiles

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

  # run the currently open file..which is the xml file and get the output
  run: ->
    console.log "this process is " + process.pid
    #console.log 'run'
    #if (false)
    #  @sysjView.setText("Ran successfully")
    #else
    #  @sysjView.setText("Failed to run")
    path = require('path')
    editor = atom.workspace.getActivePaneItem()
    file = editor?.buffer.file
    filePath = file?.path
    console.log filePath
    dirToConfigFolder = filePath.substring(0,filePath.lastIndexOf(path.sep + ""))
    dir = dirToConfigFolder.substring(0,dirToConfigFolder.lastIndexOf(path.sep + ""))
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

    pathToJar = packagePath + path.sep + "jar" + path.sep + "*"
    console.log pathToJar

    # a represents Windows
    # rest represent unix or linux
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
      @pathToClass = ";" + dir + path.sep + "class" + path.sep
    else
      @pathToClass = ":" + dir + path.sep + "class" + path.sep

    #command = 'java -classpath \"' + pathToJar + @pathToClass +  '\" com.systemj.SystemJRunner ' + filePath

    #console.log "command is " + command

    # READ path to external libraries and add each line to the class path
    fs  = require("fs");
    fileContentsArray = fs.readFileSync(dir + path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt").toString().split('\n');
    externalJars = ""
    arrayLength = fileContentsArray.length
    counter = 0
    while counter < arrayLength
      if a
        externalJars = externalJars + ";" + fileContentsArray[counter]
      else
        externalJars = externalJars + ":" + fileContentsArray[counter]
      counter++


    #'-classpath','\"' + pathToJar + @pathToClass + '\"', 'com.systemj.SystemJRunner',filePath
    process.env['parent'] = process.pid
    console.log " the id stored in process.env parent is " + process.env['parent']
    console.log "children are " + SysjView.get().getChildren()

    if (SysjView.get().getChildren() == 0)
      console.log "entered here"
      { spawn } = require 'child_process'
      @sysjr = spawn("java",["-classpath", "" + pathToJar + externalJars + @pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
      SysjView.get().setChildren(1)
      console.log "children are " + SysjView.get().getChildren()
      @sysjr.stdout.on 'data', (data ) ->  SysjView.get().getConsolePanel().log("#{data}",level="info")#SysjView.get().printOutput("#{data}")
      console.log process.pid
      console.log @sysjr.pid
      @sysjr.stderr.on 'data', ( data ) -> SysjView.get().getConsolePanel().error("#{data}")  #atom.notifications.addError "Run failed", detail: "#{data}"
      # if the process spawned closes or exits
      pid = @sysjr.pid
      process.env['child_pid'] = pid
      @sysjr.on 'close', ->
        SysjView.get().getConsolePanel().notice("sysj program has finished executing " + pid)#console.log "sysj program has finished executing." + process.id
        SysjView.get().setChildren(0)
      @sysjr.on 'exit', ->
        SysjView.get().getConsolePanel().notice("sysj program has finished executing " + pid)#console.log "sysj program has finished executing." + process.id
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
