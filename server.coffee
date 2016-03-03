#!/bin/env node
Express = require 'express'
MongoDb = require 'mongodb'
Async = require 'async'

app = Express()

app.get '/', (req, res) ->
    Collections.lengths.count (err, count) ->
        res.send("Nothing here yet! DB has #{count} records.")

_ipAddress = process.env.OPENSHIFT_NODEJS_IP ? '127.0.0.1'
_port = process.env.OPENSHIFT_NODEJS_PORT ? 8080

_mongoHost = process.env.OPENSHIFT_MONGODB_DB_HOST ? '127.0.0.1'
_mongoPort = process.env.OPENSHIFT_MONGODB_DB_PORT ? 27017
_mongoURL = "mongodb://#{_mongoHost}:#{_mongoPort}/ringing"

Collections = []
MongoDb.MongoClient.connect _mongoURL, (err, db) ->
    if err? then throw new Error "Failed to connect to MongoDB on #{_mongoURL}"

    collections = ['lengths', 'towers']
    Async.each collections, (collectionName, done) ->
        db.createCollection collectionName, {strict: false}, (err, collection) ->
            Collections[collectionName] = collection
            done(err)
    , (err) ->
        if err? then throw new Error "Collection creation failed with error: #{err}"

        Collections.lengths.count (err, count) ->
            if err? then throw new Error "Sample DB query failed"
            console.log "Connected to MongoDB. Lengths has #{count} records."


app.listen _port, _ipAddress, ->
    console.log "Web server started"

