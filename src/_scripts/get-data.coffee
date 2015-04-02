getSpots = require './get-spots'
getPhotos = require './get-photos'
moment = require 'moment'

module.exports = ->
  spots = null
  credentials =
    email: process.env.SAKURA360_SPOT_SHEET_EMAIL
    key: JSON.parse process.env.SAKURA360_SPOT_SHEET_KEY
  getSpots credentials, process.env.SAKURA360_SPOT_SHEET_SHEET_KEY
  .then (s) ->
    spots = s
  .then ->
    getPhotos credentials, process.env.SAKURA360_PHOTO_SHEET_SHEET_KEY
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
