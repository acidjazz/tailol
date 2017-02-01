fs = require 'fs'

files = []

if process.argv.length < 3
  console.log 'Usage: tailol file [file file...]'
  process.exit(0)

if process.argv[2] is '-v'
  console.log require('../package.json').version
  process.exit(0)

for file, index in process.argv
  continue if index < 2
  if !fs.existsSync file
    console.log "File: \"#{file}\" cannot be found"
    process.exit(0)

  files.push file

blessed = require 'blessed'
screen = blessed.screen smartCSR: true
Tail = require('tail').Tail

###
util = require 'util'
log_file = fs.createWriteStream('./debug.log', {flags : 'w'})
log = (d) ->
  log_file.write util.format(d) + "\n"
###

screen.title = "tailoling #{files.length} files"

boxen = []
tails = []
modal = false

shift = 0
shiftIndex = false
shiftValue = false
shiftBox = false

files.forEach (file, i) ->

  filename = file.replace(/^.*[\\\/]/, '')

  boxen.push
    index: i
    current: false
    list: blessed.List
      top: (100 / files.length * i) + '%'
      height: 100 / files.length + '%'
      label: filename
      border: type: 'line'
      scrollable: true
      scrollbar: style: bg: 'blue'
      alwaysScroll: true
      keys: true
      vi: true
      interactive: true
      style:
        label: fg: 'grey'
        focus: label: fg: 'white'
        border: fg: 'green'
        selected: fg: 'blue'

  boxen[i].list.on 'select', (selected) ->
    modal = blessed.box
      top: 'center'
      left: '10%'
      width: '80%'
      height: '50%'
      label: "#{selected.content.length} characters"
      content: selected.content
      tags: true
      border: 'line'
      draggable: true
      style:
        bg: '#333333'
        border: fg: 'blue'
      padding:
        left: 2
        top: 2
        right: 2
        bottom: 2

    screen.append modal
    modal.focus()
    modal.setFront()

    modal.key 'enter', ->
      modal.destroy()

  boxen[i].list.on 'focus', ->
    boxen[i].list.setFront()

  boxen[i].list.key ['up', 'down'], ->

    if shiftIndex isnt false and boxen[i].list.selected isnt shiftIndex
      boxen[i].list.setItem shiftIndex, shiftValue
      screen.render()
      shift = 0
      shiftBox = false
      shiftValue = false
      shiftIndex = false

  boxen[i].list.key '$', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift = boxen[i].list.value.length - boxen[i].list.width + 3
      shiftIndex = boxen[i].list.selected
      shiftValue = boxen[i].list.value if shiftValue is false
      shiftBox = i
      boxen[i].list.setItem boxen[i].list.selected, shiftValue.substring shift
      screen.render()

  boxen[i].list.key '^', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift = 0
      shiftIndex = boxen[i].list.selected
      shiftValue = boxen[i].list.value if shiftValue is false
      shiftBox = i
      boxen[i].list.setItem boxen[i].list.selected, shiftValue.substring shift
      screen.render()


  boxen[i].list.key 'right', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift++
      shiftIndex = boxen[i].list.selected
      shiftValue = boxen[i].list.value if shiftValue is false
      shiftBox = i
      boxen[i].list.setItem boxen[i].list.selected, shiftValue.substring shift
      screen.render()


  boxen[i].list.key 'space', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift += 10
      shiftIndex = boxen[i].list.selected
      shiftValue = boxen[i].list.value if shiftValue is false
      shiftBox = i
      boxen[i].list.setItem boxen[i].list.selected, shiftValue.substring shift
      screen.render()


  boxen[i].list.key 'left', ->
    if shift > 0
      shift--
      boxen[i].list.setItem boxen[i].list.selected, shiftValue.substring shift
      screen.render()

  screen.append boxen[i].list

  tails.push new Tail file

  tails[i].on 'line', (data) ->
    boxen[i].list.add data
    boxen[i].list.scrollTo boxen[i].list.getScrollHeight()
    boxen[i].list.select boxen[i].list.items.length-1
    boxen[i].current = boxen[i].list.items.length-1
    screen.render()

screen.key ['escape','q','C-c'], (ch, key) ->
  process.exit 0

screen.key ['tab'], (ch, key) ->
  if shiftBox isnt false
    boxen[shiftBox].list.setItem shiftIndex, shiftValue
    screen.render()
    shift = 0
    shiftValue = false
    shiftIndex = false
    shiftBox = false
  screen.focusNext()
  screen.render()

screen.key ['S-tab'], (ch, key) ->
  if shiftBox isnt false
    boxen[shiftBox].list.setItem shiftIndex, shiftValue
    screen.render()
    shift = 0
    shiftValue = false
    shiftBox = false
  screen.focusPrevious()
  screen.render()

boxen[0].list.focus()
boxen[0].list.setFront()
screen.render()

