// Copyright (c) Alex Ellis 2017. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

"use strict"

const express = require('express')
const app = express()
const handler = require('./function/handler');
const bodyParser = require('body-parser')

// app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(bodyParser.raw());
app.use(bodyParser.text({ type : "text/*" }));
app.disable('x-powered-by');

let isArray = (a) => {
    return (!!a) && (a.constructor === Array);
};

let isObject = (a) => {
    return (!!a) && (a.constructor === Object);
};

if (isObject(handler)) {
    _.forOwn(handler, function(value, key) {
        if (_.isFunction(value)) {
            if ('root' === key) {
                console.log("Dynamically registered route: /");
                app.get('/', value);
                app.post('/', value);
            } else {
                console.log("Dynamically registered route: /" +  key);
                app.post('/' + key, value);
                app.get('/' + key, value);
            }
        }
    });
} else {
    console.log("Registered catch-all route: /*");
    app.get('/*', handler);
    app.post('/*', handler);
}

const port = process.env.http_port || 3000;

app.listen(port, () => {
    console.log(`OpenFaaS Node.js listening on port: ${port}`)
});