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

console.log files

blessed = require('blessed')
screen = blessed.screen(smartCSR: true)
Tail = require('tail').Tail

screen.title = "tailoling #{files.length} files"

boxen = []
tails = []

files.forEach (file, index) ->

  filename = file.replace(/^.*[\\\/]/, '')

  boxen.push blessed.List
    top: (100 / files.length * index) + '%'
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
      label: fg: 'green'
      border: fg: 'blue'
      selected: fg: 'blue'

  screen.append boxen[index]

  tails.push new Tail file

  tails[index].on 'line', (data) ->
    boxen[index].add data
    boxen[index].scrollTo boxen[index].getScrollHeight()
    boxen[index].select boxen[index].items.length-1
    screen.render()

screen.key ['escape','q','C-c'], (ch, key) ->
  process.exit 0

screen.key ['tab'], (ch, key) ->
  screen.focusNext()

screen.key ['S-tab'], (ch, key) ->
  screen.focusPrevious()

screen.render()

