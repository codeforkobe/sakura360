newClient = require 'google-sheets-api'

module.exports = ({ email, key }, sheetKey)->
  config = { email, key, sheetKey }
  client = newClient({ email: config.email, key: config.key })
  spreadsheet = client.getSpreadsheet(config.sheetKey)
  spreadsheet.getWorksheetIds()
  .then (worksheetIds) ->
    spreadsheet.getWorksheet(worksheetIds[0])
  .then (worksheet) ->
    worksheet.getCells()
  .then (cells) ->
    cells
    .reduce (spots, i) ->
      spot = spots.filter((j) -> j.row is i.row)[0]
      if spot?
        spot.id = i.value if i.col is 2
        spot.name = i.value if i.col is 3
        spots
      else
        spot = i
        spot.id = i.value if i.col is 2
        spot.name = i.value if i.col is 3
        spots.concat [spot]
    , []
    .filter (i) -> i.row isnt 1 and i.id? and i.name?
    .sort (a, b) -> if a.row < b.row then -1 else if a.row > b.row then 1 else 0
    .map (i) ->
      id: i.id     # syukugawa
      name: i.name # 夙川公園
      photos: []
