{exec} = require 'child_process'
fs = require 'fs'
fm = require 'front-matter'
path = require 'path'
pug = require 'pug'
dive = require 'diveSync'

srcdir = './src/pages'
outdir = './out'
pretty = 0
global = {}


run = (cmd) ->
  exec cmd, (err, stdout, stderr) ->
    throw err if err
    console.log "stdout: #{stdout}" if stdout
    console.log "stderr: #{stderr}" if stderr

listFiles = (dir = './', list = []) ->
  dive dir, (err, filename) => list[list.length] = { filename }
  list

assign = (action) -> (item) -> Object.assign item, action item

sortBy = (property, desc) -> (a, b) -> (a[property] > b[property]) ^ desc

outFilename = (item) => outfile: (item.filename.slice srcdir.length, - '.pug'.length).replace /index$/, ''

readFile = (item) => content: fs.readFileSync item.filename, 'utf-8'

parseFM = (item) => fm item.content

globalObj = () => {global}

render = (item) => html: pug.render item.body, item

linkMenu = (item) => Object.assign item.attributes.menu, path: item.outfile

composeMenu = (item) => (item.global.menu ?= []).push item.attributes.menu

writeHtml = (item) =>
  dir = path.join outdir, item.outfile
  file = path.join dir, 'index.html'
  run "mkdir -p #{dir}"
  fs.writeFileSync file, item.html

build = () ->
  list = listFiles srcdir
  list.map assign outFilename
  list.map assign readFile
  list.map assign parseFM
  list.map assign globalObj
  list.map linkMenu
  list.map composeMenu
  global.menu.sort sortBy 'order'
  list.map assign render
  list.map writeHtml

module.exports = { build }
