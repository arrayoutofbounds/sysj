module.exports =
  class DialogView
    constructor: () ->
      # Create root element
      @element = document.createElement('div')
      @element.classList.add('dialog')

      header = document.createElement('h3')
      header.textContent = 'Compile Options'
      header.classList.add('header','compile-options')
      @element.appendChild(header)

      # Create message element
      message = document.createElement('div')
      message.textContent = "The Wordcount package is Alive! It's ALIVE!"
      message.classList.add('message','block')
      @element.appendChild(message)

      button = document.createElement('button')
      button.textContent = "Compile"
      button.classList.add('btn', 'btn-success', 'inline-block-tight')
      button.addEventListener('click',@clicked)
      @element.appendChild(button)



    clicked: ->
      console.log "this was clicked"

    # Returns an object that can be retrieved when package is activated
    serialize: ->
    # Tear down any state and detach
    destroy: ->
      @element.remove()
    getElement: ->
      @element
