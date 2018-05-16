{execSync} = require 'child_process'
fs = require 'fs'
fm = require 'front-matter'
path = require 'path'
pug = require 'pug'
dive = require 'diveSync'

srcdir = './src/pages'
outdir = './out'
pretty = 0
global = {}
mdwrapper = fs.readFileSync "./src/mdwrapper.pug", 'utf-8'

run = (cmd) ->
  execSync cmd

listFiles = (dir = './', list = []) ->
  dive dir, (err, filename) => list[list.length] = { filename }
  list

assign = (action) -> (item) -> Object.assign item, action item

sortBy = (property, desc) -> (a, b) -> (a[property] > b[property]) ^ desc

fileProps = (item, parts = item.filename.match /(\w+)\/(\w+)\.(\w+)/i) => fileclass: parts[1], outfile: parts[2], filetype: parts[3]

cleanIndexNames = (item) => outfile: if item.outfile == 'index' then '' else item.outfile

readFile = (item) => content: fs.readFileSync item.filename, 'utf-8'

parseFM = (item) => fm item.content

globalObj = () => {global}

prepareMD = (item) => body: if item.filetype != 'md' then item.body else "#{mdwrapper}\n#{item.body.replace /^/gm, '    '}"

render = (item) => html: pug.render item.body, item

linkMenu = (item) => item.attributes.menu && Object.assign item.attributes.menu, path: "/#{item.outfile}"

composeMenu = (item) => item.attributes.menu && (item.global.menu ?= []).push item.attributes.menu

writeHtml = (item) =>
  dir = path.join outdir, item.outfile
  file = path.join dir, 'index.html'
  run "mkdir -p #{dir}"
  fs.writeFileSync file, item.html
  console.log "- #{file}"

build = () ->
  list = listFiles srcdir
    .filter (item) -> !item.filename.includes 'README'
  list.map assign fileProps
  list.map assign cleanIndexNames
  list.map assign readFile
  list.map assign parseFM
  list.map assign globalObj
  list.map linkMenu
  list.map composeMenu
  global.menu.sort sortBy 'order'
  list.map assign prepareMD
  list.map assign render
  list.map writeHtml

module.exports = { build }
