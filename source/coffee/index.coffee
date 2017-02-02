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

shift =
  cursor: 0
  index: false
  value: false
  box: false
  reset: ->
    @cursor = 0
    @index = false
    @value = false
    @box = false

files.forEach (file, i) ->

  filename = file.replace(/^.*[\\\/]/, '')

  boxen.push
    index: i
    current: false
    shift: (i) ->
      
      shift.index = @list.selected
      shift.value = @list.value if shift.value is false
      shift.box = i
      @list.setItem @list.selected, shift.value.substring shift.cursor

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

    if shift.index isnt false
      boxen[i].list.setItem shift.index, shift.value
      screen.render()
      shift.reset()

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

    if shift.index isnt false and boxen[i].list.selected isnt shift.index
      boxen[i].list.setItem shift.index, shift.value
      screen.render()
      shift.reset()

  boxen[i].list.key '$', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift.cursor = boxen[i].list.value.length - boxen[i].list.width + 3
      boxen[i].shift i
      screen.render()

  boxen[i].list.key '^', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift.cursor = 0
      boxen[i].shift i
      screen.render()

  boxen[i].list.key 'right', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift.cursor++
      boxen[i].shift i
      screen.render()


  boxen[i].list.key 'space', ->

    if boxen[i].list.value.length > boxen[i].list.width
      shift.cursor += 10
      boxen[i].shift i
      screen.render()


  boxen[i].list.key 'left', ->
    if shift.cursor > 0
      shift.cursor--
      boxen[i].shift i
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
  if shift.box isnt false
    boxen[shift.box].list.setItem shift.index, shift.value
    screen.render()
    shift.reset()
  screen.focusNext()
  screen.render()

screen.key ['S-tab'], (ch, key) ->
  if shift.box isnt false
    boxen[shift.box].list.setItem shift.index, shift.value
    screen.render()
    shift.reset()
  screen.focusPrevious()
  screen.render()

boxen[0].list.focus()
boxen[0].list.setFront()
screen.render()

