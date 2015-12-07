module.exports =
class SysjView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('sysj')

    # Create message element
    #message = document.createElement('div')
    #message.textContent = "The Sysj package is Alive"
    #message.classList.add('message')
    #@element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  setText: (textToShow) ->
    #console.log textToShow
    #@element.children[0].textContent = textToShow
    if textToShow.indexOf("successfully") > -1
      atom.notifications.addSuccess textToShow
    else
      atom.notifications.addError textToShow,
      dismissable: true
