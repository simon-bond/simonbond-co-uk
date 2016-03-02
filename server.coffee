#!/bin/env node
Express = require('express');
Mongo = require('mongodb');


    # /*  ================================================================  */
    # /*  Helper functions.                                                 */
    # /*  ================================================================  */

    # /**
    #  *  Set up server IP address and port # using env variables/defaults.
    #  */
    # self.setupVariables = function() {
    #     //  Set the environment variables we need.
    #     self.ipaddress = process.env.OPENSHIFT_NODEJS_IP;
    #     self.port      = process.env.OPENSHIFT_NODEJS_PORT || 8080;

    #     if (typeof self.ipaddress === "undefined") {
    #         //  Log errors on OpenShift but continue w/ 127.0.0.1 - this
    #         //  allows us to run/test the app locally.
    #         console.warn('No OPENSHIFT_NODEJS_IP var, using 127.0.0.1');
    #         self.ipaddress = "127.0.0.1";
    #     };
    # };


app = Express()

app.get '/', (req, res) ->
    res.send('Nothing here yet!')

_ipAddress = process.env.OPENSHIFT_NODEJS_IP ? '127.0.0.1'
_port = process.env.OPENSHIFT_NODEJS_PORT ? 8080

app.listen _ipAddress, _port, ->
        console.log "Node server started"

