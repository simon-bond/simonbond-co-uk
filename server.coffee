#!/bin/env node
Express = require 'express'
MongoDb = require 'mongodb'
Async = require 'async'
Morgan = require 'morgan'
ErrorHandler = require 'errorhandler'
Moment = require 'moment'
Stable = require 'stable'

Db = require './db'

_ipAddress = process.env.OPENSHIFT_NODEJS_IP ? '127.0.0.1'
_port = process.env.OPENSHIFT_NODEJS_PORT ? 8080

app = Express()
app.set 'view engine', 'pug'
app.use Morgan('combined')
app.use ErrorHandler()

_stages = [
    "Singles"
    "Minimus"
    "Doubles"
    "Doubles and Minor"
    "Minor"
    "Triples"
    "Triples and Major"
    "Major"
    "Major and Caters"
    "Caters"
    "Caters and Royal"
    "Royal"
    "Cinques"
    "Cinques and Maximus"
    "Maximus"
    "Sextuples"
    "Fourteen"
    "Septuples"
    "Sixteen"
]

app.get '/', (req, res) ->
    return res.render 'index'

app.use '/static', Express.static('static')

app.get '/ringing', (req, res) ->
    selector = {}
    Db.collections.lengths.find(selector).sort(date: 1).toArray (err, lengths) ->
        if err? then return res.status(500).send(err)
        mappedLengths = lengths.map (length) ->
            length.formatDate = Moment(length.date).format 'ddd D MMMM YYYY'
            if lengths.Footnotes?
                lengths.formatFootnotes = lengths.Footnotes.replace '\n', '<br>'
            return length
        res.render 'ringing', {performances: lengths}

app.get '/stats', (req, res) ->
    selector = {}
    Db.collections.lengths.find(selector).sort(date: 1).toArray (err, lengths) ->
        if err? then return res.status(500).send(err)

        ringers = {}
        methods = {}
        methods[stage] = {} for stage in _stages
        towers = {}
        conductors = {}

        for perf in lengths
            for ringer in [1..16] when perf["Ringer#{ringer}"]?
                ringers[perf["Ringer#{ringer}"]] ?= 0
                ringers[perf["Ringer#{ringer}"]]++

            title = perf.Method or "(#{perf.NumMeth}m)"
            methods[perf.Stage][title] ?= 0
            methods[perf.Stage][title]++

            tower = perf.tower or perf.venue
            unless tower? then console.log perf

            towers[tower.DoveID] ?= displayName: getTowerDisplayName(tower), count: 0
            towers[tower.DoveID].count++

            conductor = perf["Ringer#{perf.Conductor}"]
            conductors[conductor] ?= 0
            conductors[conductor]++

        paramSortAsc = (param) -> (x, y) -> x[param] > y[param]
        paramSortDesc = (param) -> (x, y) -> y[param] > x[param]

        ringersArr = []
        ringersArr.push {name: ringer, count: count} for ringer, count of ringers
        Stable.inplace ringersArr, paramSortAsc('name')
        Stable.inplace ringersArr, paramSortDesc('count')

        for stage in _stages
            stagesArr = []
            stagesArr.push {method: method, count: count} for method, count of methods[stage]
            Stable.inplace stagesArr, paramSortAsc('method')
            Stable.inplace stagesArr, paramSortDesc('count')
            methods[stage] = stagesArr

        towersArr = []
        towersArr.push {towerId: towerId, displayName: details.displayName, count: details.count} for towerId, details of towers
        Stable.inplace towersArr, paramSortAsc('displayName')
        Stable.inplace towersArr, paramSortDesc('count')

        conductorsArr = []
        conductorsArr.push {name: ringer, count: count} for ringer, count of conductors
        Stable.inplace conductorsArr, paramSortAsc('name')
        Stable.inplace conductorsArr, paramSortDesc('count')

        context =
            stages: _stages
            methods: methods
            ringers: ringersArr
            towers: towersArr
            conductors: conductorsArr

        res.render 'stats', context

getTowerDisplayName = (tower) ->
    if tower.Place2?
        return "#{tower.Place}, #{tower.Place2}, #{tower.Dedicn}, #{tower.County}"
    return "#{tower.Place}, #{tower.Dedicn}, #{tower.County}"

Db.start (err) ->
    if err? then throw new Error "DB start failed: #{err}"

    app.listen _port, _ipAddress, ->
        console.log "Web server started"

