path = require('path')
ptyjs = require('pty.js')
termjs = require('term.js')

module.exports = TermyView = class TermyView
  constructor: (filePath) ->
    @title = path.basename(filePath) + ' termy'
    @cwd = path.dirname(filePath)
    @pane = null

    # Create root element
    @element = document.createElement('div')
    @element.classList.add('termy')

  spawnTerm: ->
    @pty = ptyjs.spawn(@getShell(), [],
      name: 'xterm-256color'
      cols: 150
      rows: 24
      cwd: @cwd
      env: process.env)

    @term = new termjs(
      name: 'xterm-256color'
      cols: 150,
      rows: 24
      screenKeys: true,
      useStyle: true
    )

    @pty.on('exit', @destroy.bind(@))
    @term.on('destroy', @destroy.bind(@))

    @term.on('data', @pty.write.bind(@pty))
    @term.open(@element)
    @pty.pipe(@term)
    @pty.write('ls\r')

    return

  destroy: ->
    @pty?.destroy()
    @term?.destroy()
    @element?.remove()
    @pane?.destroyItem(@)
    @pty = @term = @pane = undefined

  getElement: ->
    @element

  getTitle: ->
    @title

  setPane: (pane) ->
    if @pane
      @pane.moveItemToPane(@, pane)
    else
      pane.addItem(@)
      @spawnTerm()

    @pane = pane

  getShell: ->
    if process.platform is 'win32' then path.resolve(
      process.env.SystemRoot, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
    else process.env.SHELL
