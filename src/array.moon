
-- inspect = require('inspect')

size = (list) ->
  count = 0
  for key, value in pairs list
    count += 1
  count

concat = (listA, listB) ->
  resultList = {}
  sizeA = size listA
  for key, value in pairs listA
    resultList[key] = value
  for key, value in pairs listB
    resultList[key + sizeA] = value
  resultList

append = (list, item) ->
  concat list, {item}

init = (list) ->
  sizeX = size list
  if sizeX < 1
    error "call init upon empty table"
  resultList = {}
  for key, value in pairs list
    if key < sizeX
      resultList[key] = value
  resultList

tail = (list) ->
  resultList = {}
  for key, value in pairs list
    if key > 1
      resultList[key - 1] = value
  resultList

isArray = (list) ->
  if type(list) != 'table'
    return false
  for key, value in pairs list
    if (type key) != 'number'
      return false
  return true

map = (list, fn) ->
  resultList = {}
  for key, value in pairs list
    resultList[key] = fn value, key
  resultList

-- print inspect(concat {1,2,{3}}, {4,{5,6}})
-- print inspect(append {1,2,{3}}, 4)
-- print inspect(append {1,2,{3}}, {4})
-- print inspect(init {1,2,3})
-- print inspect(init {})

return {:size, :concat, :append, :init, :isArray, :tail, :map}
