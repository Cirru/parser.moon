
inspect = require 'inspect'
parser = require 'src/parser'
JSON = require 'JSON'

files = {
  'comma'
  'demo'
  'folding'
  'html'
  'indent'
  'parentheses'
  'quote'
  'spaces'
  'unfolding'
}

for key, value in pairs(files)
  file = io.open ('cirru/' .. value .. '.cirru'), 'rb'
  content = file\read "*all"
  file\close()

  tree = parser.pare content, ""
  generated = JSON\encode tree

  file = io.open ('ast/' .. value .. '.json'), 'rb'
  template = file\read "*all"
  file\close()

  tree = JSON\decode template
  template = JSON\encode tree

  if generated == template
    print "passed test: " .. value
  else
    print "failed at: " .. value
    print(generated)
    print(template)
