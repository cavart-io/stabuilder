{execSync} = require 'child_process'
fs = require 'fs'
fm = require 'front-matter'
path = require 'path'
pug = require 'pug'
dive = require 'diveSync'

srcdir = './src'
types  = ['.md', '.pug', '.mdm']
outdir = './out'
pretty = 0
menu   = []
mdwrapper = fs.readFileSync "./src/mdwrapper.pug", 'utf-8'

try console.log 'Building with stabuilder v_' + require(path.join __dirname, 'package.json').version

run = (cmd) -> execSync cmd

listFiles = (dir = './', list = [], _x = dive dir, (err, filename) => list[list.length] = { filename }) -> list

assign = (filter, action) -> (item) -> if filter(item) then Object.assign item, action item

sortBy = (property, desc) -> (a, b) -> (a[property] > b[property]) ^ desc

noFilter = () => true

filterFiles = (types) => (item) => !item.filename.includes('README') && types.find (e) => item.filename.endsWith e

filterClasses = (classes) => (item) => classes.find (e) => item.fileclass.endsWith e

fileProps = (item, parts = item.filename.match /(\w+)\/(\w+)\.(\w+)/i) => fileclass: parts[1], outfile: parts[2], filetype: parts[3]

filterIndexes = (item) => item.outfile == 'index'

cleanIndexNames = (item) => outfile: ''

readFile = (item) => content: fs.readFileSync item.filename, 'utf-8'

parseFM = (item) => fm item.content

prepareMD = (item) => body:
  mdwrapper + item.body.replace /^(.*)$/mg, (a, b) => if b.match /^\+\w/ then "  #{a}\n  :markdown-it" else '    '+a

makeMenu = (item) => global: menu:
  (if item.attributes.menu then [menu.push(Object.assign item.attributes.menu, path: "/#{item.outfile}"), menu][1] else menu)
    .sort sortBy 'order'

render = (item) => html: pug.render item.body, item

writeHtml = (item) =>
  dir = path.join outdir, item.outfile
  file = path.join dir, 'index.html'
  run "mkdir -p #{dir}"
  fs.writeFileSync file, item.html
  console.log "- #{file}"

build = () ->
  list = listFiles(srcdir).filter filterFiles(types)
  list.map assign   noFilter,                     fileProps
  list.map assign   filterIndexes,                cleanIndexNames
  list.map assign   noFilter,                     readFile
  list.map assign   filterFiles(['pug', 'md']),   parseFM
  list.map assign   noFilter,                     makeMenu
  list.map assign   filterFiles(['md']),          prepareMD
  list.map assign   filterClasses(['pages']),     render
  list.map assign   filterClasses(['pages']),     writeHtml
  return list

module.exports = { build }
