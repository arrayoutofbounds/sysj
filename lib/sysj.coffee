SysjView = require '../lib/sysj-view'
{CompositeDisposable} = require 'atom'


module.exports = Sysj =
  sysjView: null
  modalPanel: null
  subscriptions: null
  dialogView: null
  flag: false
  clickHappened:false
  compileDialog: false

  setCompileDialogExistence: (value) -> # sets the existence of the compile dialog so when it is asked to be showed it can be referred
    @compileDialog = value

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
    'sysj:create': => @create()
    'sysj:compile all': => @compileAll()
    'sysj:generate_subsystem': => @parseJson()
    #'sysj:kill': => @kill()
    #'sysj:toggle': => @toggle()

    SysjView.get().setChildren(0) # set to 0 when syjs package is loaded

  createXml: (dir,val,subsystem) ->
    # this method takes in the value and name of the subsystem respectively
    console.log val
    console.log subsystem
    path = require 'path'
    fs = require 'fs'
    # steps:
    # create a new file for the subsystem
    # iterate the object and get all clock domains
    clockDomains = []
    oChannels = []
    iChannels = []
    pathToXml = dir + path.sep + "config" + path.sep + subsystem + ".xml" #create the xml file
    builder = require('xmlbuilder')


    System = builder.create("System")
    System.att('xmlns','http://systemjtechnology.com') # add attribute to the root element
    System.com('<Interconnection>')
    System.com('<Link Type="Destination">')
    System.com('Interface example:')
    System.com('<Interface SubSystem="SS1" Class="com.systemj.ipc.TCPIPInterface" Args="127.0.0.1:1100"/>')
    System.com('<Interface SubSystem="SS2" Class="com.systemj.ipc.TCPIPInterface" Args="127.0.0.1:1200"/>')
    System.com('.....')
    System.com('</Link>')
    System.com('</Interconnection>')
    SubSystem = System.ele("SubSystem",{'Name':subsystem.toString(),'Local':'true'})


    # now go throught the SubSystem and get all clock domains
    for cd of val
      if val.hasOwnProperty(cd)
        console.log cd # this just prints the name of the clock domain inside
        clockDomains.push cd
        #console.log val[cd]

        # create the clock domain tag
        ClockDomain = SubSystem.ele('ClockDomain',{'Name':cd.toString(),'Class': (val[cd].Class).toString()}) # this adds clock domains as siblings but also children of SubSystem


        # now go through and add channels
        if val[cd].oChannels != undefined
          oChannels = val[cd].oChannels
        else
            oChannels = []
        if val[cd].iChannels != undefined
          iChannels = val[cd].iChannels
        else
          iChannels = []
        if val[cd].iSignals != undefined
          iSignals = val[cd].iSignals
        else
          iSignals  = []
        if val[cd].oSignals != undefined
          oSignals = val[cd].oSignals
        else
          oSignals  = []

        for oc in oChannels # if nothing is in ochannel array then its ok as nothing happens
          console.log oc
          # go through all properties of that oc.
          attributesOc = {}
          for atr of oc
            if oc.hasOwnProperty(atr)
              ocProperty = atr
              attributesOc[ocProperty] = oc[atr]
          #console.log attributesOc
          @addNode(ClockDomain,'oChannel',attributesOc)

        for ic in iChannels # if nothing is in ochannel array then its ok as nothing happens
          console.log ic

          attributesIc = {}
          for atr of ic
            if ic.hasOwnProperty(atr)
              icProperty = atr
              attributesIc[icProperty] = ic[atr]
          #console.log attributesIc
          @addNode(ClockDomain,'iChannel',attributesIc)

        for inputSignal in iSignals
          console.log inputSignal
          attributesIsig = {}
          for atr of inputSignal
            if inputSignal.hasOwnProperty(atr)
              isigProperty = atr
              attributesIsig[isigProperty] = inputSignal[atr]
          @addNode(ClockDomain,'iSignal',attributesIsig)

        for outputSignal in oSignals
          console.log outputSignal
          attributesOsig = {}
          for atr of outputSignal
            if outputSignal.hasOwnProperty(atr)
              osigProperty = atr
              attributesOsig[osigProperty] = outputSignal[atr]
          @addNode(ClockDomain,'oSignal',attributesOsig)


        #console.log val[cd].oChannels # this prints all the output channels
    console.log clockDomains # prints all the clock domains in the sub system
    #fs.writeFileSync(pathToXml,doc.toString())


    # convert to string and then write to the xml file
    converted = System.end({ pretty: true, indent: '  ', newline: '\n' })
    fs.writeFileSync(pathToXml,converted)

  addNode: (ClockDomain,type,attributes) ->
    ClockDomain.ele(type.toString(),attributes)
    # node is the node you want to add to
    # type is channel or signal existence
    # attributes is a object in the form e.g {Name:'' + ic.Name,From:'' + ic.From}

  readJson: (pathToJsonFile)  ->
    jsonfile = require('jsonfile')
    @objectRead = jsonfile.readFileSync(pathToJsonFile)
    console.log @objectRead

    #back up npm package incase you want to change the json files attributes.
    #json = require('json-file');
    #file  = json.read(pathToJsonFile) # this is done syncronously .
    #@objectRead = file.data
    #console.log @objectRead # print the data in the json file


  parseJson: ->
    editor = atom.workspace.getActivePaneItem()
    path = require 'path'
    file = editor?.buffer.file
    filePath = file?.path
    dirToConfig = filePath.substring(0,filePath.lastIndexOf(path.sep + ""))
    dir = dirToConfig.substring(0,dirToConfig.lastIndexOf(path.sep + ""))

    console.log "dir when parsing json is " + dir
    @subsystems = []
    pathToJsonFile = dir + path.sep + "projectSettings" + path.sep + "generate_subsystem.json"

    @readJson(pathToJsonFile) # the object read is given a value
    for subsystem of @objectRead # go through each object of the data from the file
      if @objectRead.hasOwnProperty(subsystem)
        val = @objectRead[subsystem] # val is the actual subystem object
        console.log "property is " + subsystem
        @subsystems.push subsystem
        #console.log "value name is " + val.name
        # NOW SEND each sub system to a method which reads through it and writes it to its own xml file
        @createXml(dir,val,subsystem)

    console.log "subsystems are " + @subsystems # this prints the list of all subystems in the json file


  showCompileDialog: -> # this shows the compile dialog if the compile dialog variable is false, else it does nothing because the dialog must be open
    if @compileDialog == false # the compile dialog must not exist for this to happen. else it implies that the dialog is already open
      path = require 'path'
      #console.log path.sep #checks that the path is different for windows and linux
      console.log "show dialog method is run"
      DialogView = require '..' + path.sep + "lib" + path.sep + 'dialog-view'
      @dialogView = new DialogView()
      @modalPanel = atom.workspace.addRightPanel(item: @dialogView.getElement(), visible: true)
      @dialogView.toAppend = ""
      @compileDialog = true # set it to true as it exists
      if !@modalPanel.isVisible()
        @modalPanel.show()

  consumeCommandOutputView: (commandOutputView) ->
    @commandOutputView = commandOutputView
    console.log "API consumed"
    console.log @commandOutputView
    console.log "New terminal created"

  consumeConsolePanel: (consolePanel) ->
    @consolePanel = consolePanel
    SysjView.get().setConsolePanel(@consolePanel)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @subscriptions = null
    @sysjView.destroy()
    @emitter.dispose()



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


    # optional compile options file....can be used in the future
    #fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "compileOptions.json", "{}", (err) ->
    #  if (err)
    #    console.log "error occurred"
    #  console.log "file saved"
    #)
    fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "generate_subsystem.json", "", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    jsonfile = require('jsonfile') # require the jsonfile package
    obj = {}
    jsonfile.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "generate_subsystem.json", obj, {spaces: 2}, (err) ->
      if err
        console.error(err)
    )
    fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt", "", (err) ->
      if (err)
        console.log "error occurred"
      console.log "file saved"
    )
    pathToJavaf = directoryChosen +  path.sep + "java" + path.sep
    fs.writeFileSync(directoryChosen +  path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt",pathToJavaf)
    fs.writeFile(directoryChosen +  path.sep + "projectSettings" + path.sep + "pathToJdk.txt", "", (err) ->
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

  # this method was used when output went to the console. It is useless now
  kill: ->
    # get the parent pid from the env and then kill it using sigterm
    terminate = require("terminate")
    #console.log process.env['parent']

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

    filesInJavaFolder = fs.readdirSync javaFolderPath
    console.log filesInJavaFolder # this lists all the files and folders inside the java folder

    mv = require("mv")

    # go through the java folder and make a folder for each name that is not a .java file
    j = 0
    while j < filesInJavaFolder.length
      if (filesInJavaFolder[j].indexOf(".java") == -1) # if file is not java then it must be a folder so make a dir in class folder of that name
        fs.mkdir(dir +  path.sep + "class" + path.sep + filesInJavaFolder[j]) # dir/class/mytest
        # now move all the class files from the folder that are inside the java folder
        console.log filesInJavaFolder[j]
        filesInSubJavaFolder = fs.readdirSync javaFolderPath + path.sep + filesInJavaFolder[j] # this gets all the class files in that sub folder inside java
        console.log "files in sub folder are " + filesInSubJavaFolder
        k = 0
        while k<filesInSubJavaFolder.length
          if ( filesInSubJavaFolder[k].indexOf(".class") > -1)
            mv javaFolderPath + path.sep + filesInJavaFolder[j] + path.sep + filesInSubJavaFolder[k],classFolderPath + path.sep + filesInJavaFolder[j] + path.sep + filesInSubJavaFolder[k], (err) ->
              if err
                console.error err
          k++
      j++

    files = fs.readdirSync classFolderPath # sync read to ensure that all files are collected in an array before moving on
    console.log files
    i = 0
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

    if filePath.indexOf(".sysj") > -1


      packagePath = ""
      paths = atom.packages.getAvailablePackagePaths()
      dirToConfig = filePath.substring(0,filePath.lastIndexOf(path.sep + ""))
      dir = dirToConfig.substring(0,dirToConfig.lastIndexOf(path.sep + ""))
      jdkPath = @getJdkPath(dir)

      if jdkPath.length == 0
        jdkPath = "java"

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

      fs  = require("fs");
      fileContentsArray = fs.readFileSync(dir + path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt").toString().split('\n');
      externalJars = ""
      arrayLength = fileContentsArray.length
      counter = 0
      while counter < arrayLength
        if a # windows
          externalJars = externalJars + ";" + fileContentsArray[counter]
        else # mac or linux
          externalJars = externalJars + ":" + fileContentsArray[counter]
        counter++



      # this moves the class and java compiled files to the class folder
      command = jdkPath + ' -classpath \"' + pathToJar + externalJars + '\" JavaPrettyPrinter -d ' + dir + path.sep + 'class ' + toAppend + " " + filePath

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
    else
      window.alert("Please compile a sysj file only")

    #console.log "command output view is " + @commandOutputView

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
    jdkPath = @getJdkPath(dir)

    if jdkPath.length == 0
      jdkPath = "java"

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

    fs  = require("fs");
    fileContentsArray = fs.readFileSync(dir + path.sep + "projectSettings" + path.sep + "pathsToExternalLibraries.txt").toString().split('\n');
    externalJars = ""
    arrayLength = fileContentsArray.length
    counter = 0
    while counter < arrayLength
      if a # windows
        externalJars = externalJars + ";" + fileContentsArray[counter]
      else # mac or linux
        externalJars = externalJars + ":" + fileContentsArray[counter]
      counter++


    # go through the source folder and append the file path of each file


    # this moves the class and java compiled files to the class folder
    command = jdkPath + ' -classpath \"' + pathToJar + externalJars +  '\" JavaPrettyPrinter -d ' + dir + path.sep + 'class ' +  allSysjFiles

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

  createTerminal: ->
    terminal = @commandOutputView.newTermClick() #create new terminal
    terminal

  getJdkPath: (dir) ->
    fs  = require("fs")
    path = require("path")
    fileContentsArray = fs.readFileSync(dir + path.sep + "projectSettings" + path.sep + "pathToJdk.txt").toString().split('\n'); # read and split by new line
    pathToJdk = ""
    pathToJdk = fileContentsArray[0]
    pathToJdk # return path to jdk

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

    if filePath == undefined
      window.alert("ctrl-alt-a runs the current xml file open. Please open a xml config file in the editor before proceeding.")
    else
      if filePath.indexOf(".xml") > -1
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

        pathToJar = packagePath + path.sep + "jar" + path.sep + "\\*"
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

        # path to the class files
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
          if a # windows
            externalJars = externalJars + ";" + fileContentsArray[counter]
          else # mac or linux
            externalJars = externalJars + ":" + fileContentsArray[counter]
          counter++


        #'-classpath','\"' + pathToJar + @pathToClass + '\"', 'com.systemj.SystemJRunner',filePath
        process.env['parent'] = process.pid # this is the parent process id
        console.log " the id stored in process.env parent is " + process.env['parent'] #prints the parent process id
        console.log "children are " + SysjView.get().getChildren() # gets the number of children processes


        ###
        if (SysjView.get().getChildren() == 0) # if the number of child processes is 0 then carry on and execute
          console.log "entered here"
          { spawn } = require 'child_process'
          #@sysjr = spawn("java",["-classpath", "" + pathToJar + externalJars + #@pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
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
          ###

        jdkPath = @getJdkPath(dir)

        if jdkPath.length == 0
          jdkPath = "java"

        console.log jdkPath + " -classpath " + pathToJar + externalJars + @pathToClass + " com.systemj.SystemJRunner " + filePath
        terminal = @createTerminal()
        if externalJars.length == 0
          terminal.spawn(jdkPath + " -classpath " + pathToJar + @pathToClass + " com.systemj.SystemJRunner " + filePath,"java",["-classpath", "" + pathToJar + @pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
        else
          terminal.spawn(jdkPath + " -classpath " + pathToJar + externalJars + @pathToClass + " com.systemj.SystemJRunner " + filePath,"java",["-classpath", "" + pathToJar + externalJars + @pathToClass , 'com.systemj.SystemJRunner',"" + filePath])
      else
        window.alert("Please ensure the correct xml file format is run")

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
