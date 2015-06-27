
inspect = require 'inspect'
parser = require 'src/parser'

files = {
  'demo'
}

for key, value in pairs(files)
  file = io.open ('cirru/' .. value .. '.cirru'), 'rb'
  content = file\read "*all"
  file\close()
  print(inspect(content))
  tree = parser.pare content, ""
  print(inspect(tree))
