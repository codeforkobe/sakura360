# Client / Spreadsheet / Worksheet
#
# Example:
# worksheet = null
# client = newClient({ email: config.googleEmail, key: config.googleKey })
# spreadsheet = client.getSpreadsheet(config.googleSheetKey)
# spreadsheet.getWorksheetIds()
# .then (worksheetIds) ->
#   spreadsheet.getWorksheet(worksheetIds[0])
# .then (w) -> worksheet = w
# .then ->
#   worksheet.getValue({ row: 1, col: 1 })
# .then (value) ->
#   worksheet.setValue({ row: 1, col: 1, value: value })
# .then ->
#   worksheet.getCells({ row: 1 })
# .then (cells) ->
#   console.log cells.filter (i) -> i.col is 1
# .catch (e) ->
#   console.error e
#

google = require 'googleapis'
{Promise} = require 'es6-promise'
{parseString} = require 'xml2js'

class Client
  @baseUrl: 'https://spreadsheets.google.com/feeds'

  @visibilities:
    private: 'private'
    public: 'public'

  @projections:
    basic: 'basic'
    full: 'full'

  constructor: ({ @email, @key }) ->

  getSpreadsheet: (key) ->
    new Spreadsheet({ client: @, key })

  request: (options) ->
    @_authorize({ @email, @key })
    .then (client) ->
      new Promise (resolve, reject) ->
        client.request options, (err, data) ->
          if err? then reject(err) else resolve(data)

  _authorize: ({ email, key })->
    new Promise (resolve, reject) ->
      scope = ['https://spreadsheets.google.com/feeds']
      jwt = new google.auth.JWT(email, null, key, scope, null)
      jwt.authorize (err) ->
        if err? then reject(err) else resolve(jwt)

  parseXml: (xml) ->
    new Promise (resolve, reject) ->
      parseString xml, (err, parsed) ->
        if err? then reject(err) else resolve(parsed)


class Spreadsheet
  constructor: ({ @client, @key }) ->

  getWorksheet: (id) ->
    new Worksheet({ @client, spreadsheet: @, id })

  getWorksheetIds: ->
    url = @_getWorksheetsUrl
      key: @key
      visibilities: Client.visibilities.private
      projections: Client.projections.basic

    @client.request({ url })
    .then @client.parseXml.bind(@client)
    .then (data) ->
      data.feed.entry.map (i) ->
        u = i.id[0]
        throw new Error() if u.indexOf(url) isnt 0
        u.replace(url + '/', '')

  # visibilities: private / public
  # projections: full / basic
  _getWorksheetsUrl: ({ key, visibilities, projections }) ->
    path = "/worksheets/#{key}/#{visibilities}/#{projections}"
    Client.baseUrl + path


class Worksheet
  constructor: ({ @client, @spreadsheet, @id }) ->

  getValue: (position) ->
    { row, col } = @_parsePosition(position)
    url = @_getCellUrl
      key: @spreadsheet.key
      worksheetId: @id
      visibilities: Client.visibilities.private
      projections: Client.projections.full
      row: row
      col: col
    @client.request({
      url,
      method: 'GET'
      headers:
        'GData-Version': '3.0'
        'Content-Type': 'application/atom+xml'
    })
    .then @client.parseXml.bind(@client)
    .then (data) ->
      data.entry.content[0]

  getCells: ->
    url = @_getCellsUrl
      key: @spreadsheet.key
      worksheetId: @id
      visibilities: Client.visibilities.private
      projections: Client.projections.full
    @client.request({
      url,
      method: 'GET'
      headers:
        'GData-Version': '3.0'
        'Content-Type': 'application/atom+xml'
    })
    .then @client.parseXml.bind(@client)
    .then (data) =>
      data.feed.entry.map (i) =>
        [_, colName, rowString] = i.title[0].match(/^([A-Z]+)(\d+)$/)
        row = parseInt(rowString, 10)
        col = @_parseColumnName(colName)
        { row, col, value: i.content[0] }

  setValue: (positionAndValue) ->
    { row, col } = @_parsePosition(positionAndValue)
    { value } = positionAndValue
    url = @_getCellUrl
      key: @spreadsheet.key
      worksheetId: @id
      visibilities: Client.visibilities.private
      projections: Client.projections.full
      row: row
      col: col
    @client.request({
      url,
      method: 'GET'
      headers:
        'GData-Version': '3.0'
        'Content-Type': 'application/atom+xml'
    })
    .then @client.parseXml.bind(@client)
    .then (data) =>
      contentType = 'application/atom+xml'
      xml = """
        <entry xmlns="http://www.w3.org/2005/Atom"
            xmlns:gs="http://schemas.google.com/spreadsheets/2006">
          <id>#{url}</id>
          <link rel="edit" type="#{contentType}" href="#{url}"/>
          <gs:cell row="#{row}" col="#{col}" inputValue="#{value}"/>
        </entry>
      """
      @client.request({
        url,
        method: 'PUT'
        headers:
          'GData-Version': '3.0'
          'Content-Type': contentType
          'If-Match': data.entry.$['gd:etag']
        body: xml
      })
    .then @client.parseXml.bind(@client)

  deleteValue: (position) ->
    { row, col } = @_parsePosition(position)
    url = @_getCellUrl
      key: @spreadsheet.key
      worksheetId: @id
      visibilities: Client.visibilities.private
      projections: Client.projections.full
      row: row
      col: col
    @client.request({
      url,
      method: 'GET'
      headers:
        'GData-Version': '3.0'
        'Content-Type': 'application/atom+xml'
    })
    .then @client.parseXml.bind(@client)
    .then (data) =>
      contentType = 'application/atom+xml'
      @client.request({
        url,
        method: 'DELETE'
        headers:
          'GData-Version': '3.0'
          'Content-Type': contentType
          'If-Match': data.entry.$['gd:etag']
      })
    .then @client.parseXml.bind(@client)

  # visibilities: private / public
  # projections: full / basic
  _getCellUrl: ({ key, worksheetId, visibilities, projections, row, col }) ->
    path = """
/cells/#{key}/#{worksheetId}/#{visibilities}/#{projections}/R#{row}C#{col}
    """
    Client.baseUrl + path

  # visibilities: private / public
  # projections: full / basic
  _getCellsUrl: ({ key, worksheetId, visibilities, projections }) ->
    path = "/cells/#{key}/#{worksheetId}/#{visibilities}/#{projections}"
    Client.baseUrl + path

  _parsePosition: ({ row, col, r1c1 }) ->
    return { row, col } if row? and col?
    throw new Error() if row? or col?
    throw new Error() unless r1c1?
    [_, row, col] = r1c1.match(/^R(\d+)C(\d+)$/)
    { row, col }

  _getColumnName: (col) ->
    String.fromCharCode('A'.charCodeAt(0) + col - 1)

  _parseColumnName: (colName) ->
    # TODO: colName 'AA' support
    colName.charCodeAt(0) - 'A'.charCodeAt(0) + 1

module.exports = (credentials) ->
  new Client(credentials)
