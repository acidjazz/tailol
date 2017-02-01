fs = require 'fs'

files = []

if process.argv.length < 3
  console.log 'Usage: tailol files [file file...]'
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

util = require 'util'
log_file = fs.createWriteStream('./debug.log', {flags : 'w'})

log = (d) ->
  log_file.write util.format(d) + "\n"


screen.title = "tailoling #{files.length} files"

boxen = []
tails = []

shift = 0

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

  boxen[i].list.key 'up', ->
    boxen[i].current -= 1
    #log 'up found' + boxen[i].list.selected
    shift = 0
  boxen[i].list.key 'down', ->
    boxen[i].current += 1
    #log 'down found' + boxen[i].list.selected
    shift = 0

  boxen[i].list.key 'right', ->
    shift++
    value = boxen[i].list.value
    #boxen[i].list.add "#{value.length} vs #{boxen[i].list.width}"
    if value.length > boxen[i].list.width
      boxen[i].list.setItem boxen[i].list.selected, boxen[i].list.value.substring shift
      #boxen[i].list.add boxen[i].list.value.substring 1
      screen.render()
    #log 'right key pressed' + boxen[i].list.selected

  boxen[i].list.key 'left', ->
    if shift > 0
      shift--
      boxen[i].list.setItem boxen[i].list.selected, boxen[i].list.value.substring shift
    #log 'left key pressed ' + boxen[i].list.selected

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
  screen.focusNext()

screen.key ['S-tab'], (ch, key) ->
  screen.focusPrevious()

boxen[0].list.focus()
screen.render()

