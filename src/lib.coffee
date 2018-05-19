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

filterFiles = (item) -> !item.filename.includes 'README'

fileProps = (item, parts = item.filename.match /(\w+)\/(\w+)\.(\w+)/i) => fileclass: parts[1], outfile: parts[2], filetype: parts[3]

filterIndexes = (item) => item.outfile == 'index'

cleanIndexNames = (item) => outfile: ''

readFile = (item) => content: fs.readFileSync item.filename, 'utf-8'

parseFM = (item) => fm item.content

globalObj = () => {global}

filterMD = (item) => item.filetype == 'md'

prepareMDMixins = (item) => { body: item.body
    .split "\n"
    .map (item) => if item.match /\+[a-z]/i then "#{item}\n:markdown-it" else "  #{item}"
    .join "\n"
  }

prepareMD = (item) => body: "#{mdwrapper}#{item.body.replace /^/gm, '  '}"

filterWithMenu = (item) => item.attributes.menu

linkMenu = (item) => item.attributes.menu && Object.assign item.attributes.menu, path: "/#{item.outfile}"

composeMenu = (item) => item.attributes.menu && (item.global.menu ?= []).push item.attributes.menu

render = (item) => html: pug.render item.body, item

writeHtml = (item) =>
  dir = path.join outdir, item.outfile
  file = path.join dir, 'index.html'
  run "mkdir -p #{dir}"
  fs.writeFileSync file, item.html
  console.log "- #{file}"

build = () ->
  list = listFiles srcdir
      .filter filterFiles
  list.map assign fileProps
  list.filter filterIndexes
      .map assign cleanIndexNames
  list.map assign readFile
  list.map assign parseFM
  list.map assign globalObj
  list.filter filterWithMenu
      .map linkMenu
  list.filter filterWithMenu
      .map composeMenu
  global.menu.sort sortBy 'order'
  list.filter filterMD
      .map assign prepareMDMixins
  list.filter filterMD
      .map assign prepareMD
  list.map assign render
  list.map writeHtml

module.exports = { build }
