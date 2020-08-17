'use strict';
const healthModules = require("../../health/modules")
var logger = require("../../logger")

let instance = new healthModules()

exports.getHealth = function(req, res, next) {
    logger.info('/health', 'get')
    res.json(instance.get())
    next()
};
