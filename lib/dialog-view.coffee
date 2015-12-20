module.exports =
  class DialogView

    constructor: () ->
      # Create root element
      @element = document.createElement('div')
      @element.classList.add('dialog')

      header = document.createElement('h1')
      header.textContent = 'Compile Options'
      header.classList.add('header','compile-options','block')
      @element.appendChild(header)

      body = document.createElement('div')
      body.classList.add('dialog-body','block')
      @element.appendChild(body)

      input1  = document.createElement('input')
      input1.placeholder = "Enter compile option"
      input1.setAttribute('id','input1')
      input1.classList.add('compile-option','input1')
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

      input2  = document.createElement('input')
      input2.placeholder = "Enter arguments for this option"
      input2.setAttribute('id','input2')
      input2.classList.add('compile-option','input2')
      input2.addEventListener("keydown", (event)->
        e = document.getElementById(input2.id)
        console.log "id is " + e.id
        value = e.value
        console.log "value is " + value
        console.log "key code is " + event.keyCode
        if event.keyCode == 8
          e.value = value.substring(0,value.length-1)
        )
      body.appendChild(input2)


      footer = document.createElement('div')
      footer.classList.add('dialog-footer','block')
      @element.appendChild(footer)

      button1 = document.createElement('button')
      button1.textContent = "Compile"
      button1.setAttribute('id','btn1')
      button1.classList.add('btn', 'btn-success', 'inline-block-tight','block','compile-button','btn-lg','button1')
      button1.addEventListener('click',@clicked)
      footer.appendChild(button1)

      button2 = document.createElement('button')
      button2.textContent = "Cancel"
      button2.setAttribute('id','btn2')
      button2.classList.add('btn', 'btn-warning', 'inline-block-tight','block','compile-button','btn-lg','button2')
      button2.addEventListener('click',@clicked)
      footer.appendChild(button2)

    get: (id) ->
      return document.getElementById(id)

    clicked: (e)->

      #console.log "Clicked method is called"

      #if e == undefined
      #  return false

      # e is the event.
      Sysj = require './sysj'
      Sysj.clickHappened = true
      id =  e.target.id;

      if id == 'btn1'
        #compile
        #return "compile"
        Sysj.getModalPanel().hide()
        Sysj.compile()
      else if id == 'btn2'
        Sysj.getModalPanel().hide()
        console.log "closed compile dialog"
        #return "close"
        # close the modal
      else
        Sysj.getModalPanel().hide()
        console.log "we have a problem and id is " + id


    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
      @element.remove()

    getElement: ->
      @element
