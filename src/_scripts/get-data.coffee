getSpots = require './get-spots'
moment = require 'moment'

generateSpots = ->
  config =
    email: process.env.SAKURA360_SPOT_SHEET_EMAIL
    key: JSON.parse process.env.SAKURA360_SPOT_SHEET_KEY
    sheetKey: process.env.SAKURA360_SPOT_SHEET_SHEET_KEY
  getSpots config

module.exports = ->
  spots = null

  generateSpots()
  .then (s) ->
    spots = s
  .then ->
    photos = [
      spot_id: 'ojizoo'
      type: 'theta'
      author: 'bouzuya'
      created_at: new Date(moment().valueOf())
      url: 'http://example.com/ozizoo.jpg'
    ]

    # merge photos to spots.photos
    photos.forEach (photo) ->
      spot = spots.filter((spot) -> spot.id is photo.spot_id)[0]
      return unless spot?
      spot.photos.push photo

    # sort spots.photos
    spots.forEach (spot) ->
      spot.photos.sort (a, b) ->
        ad = moment a.created_at
        bd = moment b.created_at
        if ad.isBefore bd
          -1
        else if ad.isAfter bd
          1
        else
          0

    # build site data
    site = { spots }
