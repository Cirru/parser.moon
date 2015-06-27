
tree = require 'cirru-parser.tree'
array = require 'cirru-parser.array'
-- inspect = require 'inspect'

-- initialize the function
runParse = nil
shorten = nil

parse = (code, filename) ->

  buffer = nil

  state = {
    name: 'indent'
    x: 1
    y: 1
    level: 1 -- inside list
    indent: 0
    indented: 0 -- counter
    nest: 0 -- parentheses
    path: filename
  }
  xs = {}
  while (string.len code) > 0
    {xs, buffer, state, code} = runParse xs, buffer, state, code
  res = runParse xs, buffer, state, code
  -- print(inspect(shorten res))
  res = array.map res, tree.resolveDollar
  res = array.map res, tree.resolveComma
  res

shorten = (xs) ->
  if array.isArray xs
    array.map xs, shorten
  else
    xs.text

pare = (code, filename) ->
  res = parse code, filename

  shorten res

-- eof

_escape_eof = (xs, buffer, state, code) ->
  error "EOF in escape state"

_string_eof = (xs, buffer, state, code) ->
  error "EOF in string state"

_space_eof = (xs, buffer, state, code) ->
  xs

_token_eof = (xs, buffer, state, code) ->
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem xs, state.level, buffer
  buffer = nil
  xs

_indent_eof = (xs, buffer, state, code) ->
  xs

-- escape

_escape_newline = (xs, buffer, state, code) ->
  error 'newline while escape'

_escape_n = (xs, buffer, state, code) ->
  state.x += 1
  buffer.text ..= '\n'
  state.name = 'string'
  {xs, buffer, state, (string.sub code, 2)}

_escape_t = (xs, buffer, state, code) ->
  state.x += 1
  buffer.text ..= '\t'
  state.name = 'string'
  {xs, buffer, state, (string.sub code, 2)}

_escape_else = (xs, buffer, state, code) ->
  state.x += 1
  buffer.text ..= (string.sub code, 1, 1)
  state.name = 'string'
  {xs, buffer, state, (string.sub code, 2)}

-- string

_string_backslash = (xs, buffer, state, code) ->
  state.name = 'escape'
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_string_newline = (xs, buffer, state, code) ->
  error 'newline in a string'

_string_quote = (xs, buffer, state, code) ->
  state.name = 'token'
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_string_else = (xs, buffer, state, code) ->
  state.x += 1
  buffer.text ..= (string.sub code, 1, 1)
  {xs, buffer, state, (string.sub code, 2)}

-- space

_space_space = (xs, buffer, state, code) ->
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_space_newline = (xs, buffer, state, code) ->
  if state.nest != 0
    error 'incorrect nesting'
  state.name = 'indent'
  state.x = 1
  state.y += 1
  state.indented = 0
  {xs, buffer, state, (string.sub code, 2)}

_space_open = (xs, buffer, state, code) ->
  nesting = tree.createNesting(1)
  xs = tree.appendItem xs, state.level, nesting
  state.nest += 1
  state.level += 1
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_space_close = (xs, buffer, state, code) ->
  state.nest -= 1
  state.level -= 1
  if state.nest < 0
    error 'close at space'
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_space_quote = (xs, buffer, state, code) ->
  state.name = 'string'
  buffer = {
    text: ''
    x: state.x
    y: state.y
    path: state.path
  }
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_space_else = (xs, buffer, state, code) ->
  state.name = 'token'
  buffer = {
    text: string.sub code, 1, 1
    x: state.x
    y: state.y
    path: state.path
  }
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

-- token

_token_space = (xs, buffer, state, code) ->
  state.name = 'space'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem xs, state.level, buffer
  state.x += 1
  buffer = nil
  {xs, buffer, state, (string.sub code, 2)}

_token_newline = (xs, buffer, state, code) ->
  state.name = 'indent'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem xs, state.level, buffer
  state.indented = 0
  state.x = 1
  state.y += 1
  buffer = nil
  {xs, buffer, state, (string.sub code, 2)}

_token_open = (xs, buffer, state, code) ->
  error 'open parenthesis in token'

_token_close = (xs, buffer, state, code) ->
  state.name = 'space'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem xs, state.level, buffer
  buffer = nil
  {xs, buffer, state, code}

_token_quote = (xs, buffer, state, code) ->
  state.name = 'string'
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_token_else = (xs, buffer, state, code) ->
  buffer.text ..= (string.sub code, 1, 1)
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

-- indent

_indent_space = (xs, buffer, state, code) ->
  state.indented += 1
  state.x += 1
  {xs, buffer, state, (string.sub code, 2)}

_indent_newilne = (xs, buffer, state, code) ->
  state.x = 1
  state.y += 1
  state.indented = 0
  {xs, buffer, state, (string.sub code, 2)}

_indent_close = (xs, buffer, state, code) ->
  error 'close parenthesis at indent'

_indent_else = (xs, buffer, state, code) ->
  state.name = 'space'
  if math.fmod(state.indented, 2) == 1
    error 'odd indentation'
  indented = state.indented / 2
  diff = indented - state.indent

  if diff <= 0
    nesting = tree.createNesting 1
    xs = tree.appendItem xs, (state.level + diff - 1), nesting
  else if diff > 0
    nesting = tree.createNesting diff
    xs = tree.appendItem xs, state.level, nesting

  state.level += diff
  state.indent = indented
  {xs, buffer, state, code}

-- parse

runParse = (xs, buffer, state, code) ->
  eof = (string.len code) == 0
  char = string.sub code, 1, 1
  switch state.name
    when 'escape'
      if eof      then _escape_eof        xs, buffer, state, code
      else switch char
        when '\n' then _escape_newline    xs, buffer, state, code
        when 'n'  then _escape_n          xs, buffer, state, code
        when 't'  then _escape_t          xs, buffer, state, code
        else           _escape_else       xs, buffer, state, code
    when 'string'
      if eof      then _string_eof        xs, buffer, state, code
      else switch char
        when '\\' then _string_backslash  xs, buffer, state, code
        when '\n' then _string_newline    xs, buffer, state, code
        when '"'  then _string_quote      xs, buffer, state, code
        else           _string_else       xs, buffer, state, code
    when 'space'
      if eof      then _space_eof         xs, buffer, state, code
      else switch char
        when ' '  then _space_space       xs, buffer, state, code
        when '\n' then _space_newline     xs, buffer, state, code
        when '('  then _space_open        xs, buffer, state, code
        when ')'  then _space_close       xs, buffer, state, code
        when '"'  then _space_quote       xs, buffer, state, code
        else           _space_else        xs, buffer, state, code
    when 'token'
      if eof      then _token_eof         xs, buffer, state, code
      else switch char
        when ' '  then _token_space       xs, buffer, state, code
        when '\n' then _token_newline     xs, buffer, state, code
        when '('  then _token_open        xs, buffer, state, code
        when ')'  then _token_close       xs, buffer, state, code
        when '"'  then _token_quote       xs, buffer, state, code
        else           _token_else        xs, buffer, state, code
    when 'indent'
      if eof      then _indent_eof        xs, buffer, state, code
      else switch char
        when ' '  then _indent_space      xs, buffer, state, code
        when '\n' then _indent_newilne    xs, buffer, state, code
        when ')'  then _indent_close      xs, buffer, state, code
        else           _indent_else       xs, buffer, state, code

return {:parse, :pare}
