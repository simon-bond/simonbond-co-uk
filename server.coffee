#!/bin/env node
Express = require 'express'
MongoDb = require 'mongodb'
Async = require 'async'
Morgan = require 'morgan'
ErrorHandler = require 'errorhandler'
Moment = require 'moment'

Db = require './db'

_ipAddress = process.env.OPENSHIFT_NODEJS_IP ? '127.0.0.1'
_port = process.env.OPENSHIFT_NODEJS_PORT ? 8080

app = Express()
app.set 'view engine', 'pug'
app.use Morgan('combined')
app.use ErrorHandler()

app.get '/', (req, res) ->
    selector = {}
    Db.collections.lengths.find(selector).sort(date: 1).toArray (err, lengths) ->
        if err? then return res.status(500).send(err)
        mappedLengths = lengths.map (length) ->
            length.formatDate = Moment(length.date).format 'ddd D MMMM YYYY'
            if lengths.Footnotes?
                lengths.formatFootnotes = lengths.Footnotes.replace '\n', '<br>'
            return length
        res.render 'index', {performances: lengths}

Db.start (err) ->
    if err? then throw new Error "DB start failed: #{err}"

    app.listen _port, _ipAddress, ->
        console.log "Web server started"

