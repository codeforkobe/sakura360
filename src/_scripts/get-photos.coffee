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
    .reduce (photos, i) ->
      photo = photos.filter((j) -> j.row is i.row)[0]
      if photo?
        photo.spot_id = i.value if i.col is 1
        photo.type = i.value if i.col is 2
        photo.author = i.value if i.col is 3
        photo.title = i.value if i.col is 4
        photo.url = i.value if i.col is 5
        photos
      else
        photo = i
        photo.spot_id = i.value if i.col is 1
        photo.type = i.value if i.col is 2
        photo.author = i.value if i.col is 3
        photo.title = i.value if i.col is 4
        photo.url = i.value if i.col is 5
        photos.concat [photo]
    , []
    .filter (i) -> i.row isnt 1 and i.spot_id? and i.url?
    .sort (a, b) -> if a.row < b.row then -1 else if a.row > b.row then 1 else 0
    .map (i) ->
      spot_id: i.spot_id
      type: i.type
      author: i.author
      title: i.title
      url: i.url
