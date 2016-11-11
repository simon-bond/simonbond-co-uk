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
    for key, val of req.query when val.length
        switch key
            when 'year'
                selector.date =
                    $gte: new Date(parseInt(val), 0, 1)
                    $lt: new Date(parseInt(val)+1, 0, 1)
            when 'length'
                if val is 'quarter'
                    selector.Length = $lt: 5000
                if val is 'peal'
                    selector.Length = $gte: 5000


    Db.collections.lengths.find(selector).sort(date: 1).toArray (err, lengths) ->
        if err? then return res.status(500).send(err)

        totalRows = countQ = countP = 0

        mappedLengths = lengths.map (length) ->
            totalRows += length.Length
            if length.Length > 4999 then countP++ else countQ++
            length.formatDate = Moment(length.date).format 'ddd D MMMM YYYY'
            if lengths.footnotes?
                lengths.formatFootnotes = lengths.footnotes.replace '\n', '<br>'
            return length
        context = req.query # pass it back for display in the filters
        context.performances = lengths
        context.totalRows = totalRows
        context.countP = countP
        context.countQ = countQ
        context.years = [new Date().getFullYear()..2002]
        res.render 'ringing', context


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

            title = perf.Method or "(#{perf.numMeth}m)"
            methods[perf.stage][title] ?= 0
            methods[perf.stage][title]++

            tower = perf.tower or perf.venue

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

app.get '/new', (req, res) ->
    console.log 'new'
    return Db.collections.towers.find({isHand: $ne: true}).sort({doveId: 1}).toArray (err, towers) ->
        if err? then return res.status(500).send(err)
        towers = towers.map (tower) ->
            tower.formattedPlace = tower.place
            if tower.place2 then tower.formattedPlace += ", #{tower.place2}"
            tower.formattedPlace += ", #{tower.dedication}"
            return tower
        context = towers: towers

        return res.render 'new', context

getTowerDisplayName = (tower) ->
    if tower.Place2?
        return "#{tower.Place}, #{tower.Place2}, #{tower.Dedicn}, #{tower.County}"
    return "#{tower.Place}, #{tower.Dedicn}, #{tower.County}"

Db.start (err) ->
    if err? then throw new Error "DB start failed: #{err}"

    app.listen _port, _ipAddress, ->
        console.log "Web server started"

