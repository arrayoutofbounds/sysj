module.exports =
  class DialogView
    constructor: () ->
      # Create root element
      @element = document.createElement('div')
      @element.classList.add('dialog')

      header = document.createElement('h3')
      header.textContent = 'Compile Options'
      header.classList.add('header','compile-options','block')
      @element.appendChild(header)

      body = document.createElement('div')
      body.classList.add('dialog-body','block')
      @element.appendChild(body)

      input1  = document.createElement('input')
      input1.textContent = "Enter compile option"
      input1.setAttribute('id','input1')
      input1.classList.add('compile-option-1')
      input1.addEventListener("keydown", (event)->
        e = document.getElementById(input1.id)
        console.log "id is " + e.id
        value = e.value
        console.log "value is " + value
        console.log "key code is " + event.keyCode
        if event.keyCode == 8
          e.value = value.substring(0,value.length-1)
      )
      body.appendChild(input1)

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
