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
    console.log 'compiled'
    if (true)
      @sysjView.setText("Compiled successfully")
    else
      @sysjView.setText("Failed to compile")
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
