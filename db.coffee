MongoDb = require 'mongodb'
Async = require 'async'

_mongoHost = process.env.OPENSHIFT_MONGODB_DB_HOST ? '127.0.0.1'
_mongoPort = process.env.OPENSHIFT_MONGODB_DB_PORT ? 27017
_mongoURL = process.env.OPENSHIFT_MONGODB_DB_URL ? "mongodb://127.0.0.1:27017/ringing"

exports.collections = []

exports.start = (done) ->
    MongoDb.MongoClient.connect _mongoURL, (err, db) ->
        if err? then return done "Failed to connect to MongoDB on #{_mongoURL}"

        collections = ['lengths', 'towers']
        Async.each collections, (collectionName, done) ->
            db.createCollection collectionName, {strict: false}, (err, collection) ->
                exports.collections[collectionName] = collection
                done(err)
        , (err) ->
            if err? then return done "Collection creation failed with error: #{err}"

            exports.collections.lengths.count (err, count) ->
                if err? then return done "Sample DB query failed"
                return done()
