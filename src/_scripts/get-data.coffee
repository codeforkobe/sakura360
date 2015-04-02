getSpots = require './get-spots'
getPhotos = require './get-photos'
moment = require 'moment'

module.exports = ->
  config =
    email: 'SAKURA360_GOOGLE_API_CLIENT_EMAIL'
    key: 'SAKURA360_GOOGLE_API_PRIVATE_KEY'
    spotSheetKey: 'SAKURA360_SPOT_SHEET_KEY'
    photoSheetKey: 'SAKURA360_PHOTO_SHEET_KEY'

  for k, v of config
    value = process.env[v]
    throw new Error("export #{v}='...'") unless value?
    config[k] = value

  spots = null
  credentials =
    email: config.email
    key: JSON.parse config.key
  getSpots credentials, config.spotSheetKey
  .then (s) ->
    spots = s
  .then ->
    getPhotos credentials, config.photoSheetKey
  .then (photos) ->
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
