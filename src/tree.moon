
array = require 'cirru-parser.array'
inspect = require 'inspect'

concat = array.concat
append = array.append
init = array.init
size = array.size
isArray = array.isArray
tail = array.tail

appendItem = (xs, level, buffer) ->
  if level == 0
    append xs, buffer
  else
    res = appendItem xs[size xs], (level - 1), buffer
    append (init xs), res

createHelper = (xs, n) ->
  if n <= 1
    xs
  else
    {createHelper xs, (n - 1)}

createNesting = (n) ->
  createHelper {}, n

-- initialize the function
resolveDollar = nil
resolveComma = nil

dollarHelper = (before, after) ->
  if (size after) == 0 then return before
  cursor = after[1]
  if (isArray cursor)
    dollarHelper (append before, (resolveDollar cursor)), (tail after)
  else if cursor.text == '$'
    append before, (resolveDollar (tail after))
  else
    dollarHelper (append before, cursor), (tail after)

resolveDollar = (xs) ->
  if (size xs) == 0 then return xs
  dollarHelper {}, xs

commaHelper = (before, after) ->
  if (size after) == 0 then return before
  cursor = after[1]
  if (isArray cursor) and ((size cursor) > 0)
    head = cursor[1]
    if isArray head
      commaHelper (append before, (resolveComma cursor)), (tail after)
    else if head.text == ','
      commaHelper before, (concat (resolveComma (tail cursor)), (tail after))
    else
      commaHelper (append before, (resolveComma cursor)), (tail after)
  else
    commaHelper (append before, cursor), (tail after)

resolveComma = (xs) ->
  if (size xs) == 0 then return xs
  commaHelper {}, xs

return {:appendItem, :createNesting, :resolveDollar, :resolveComma}
