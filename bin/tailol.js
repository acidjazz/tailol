#!/bin/sh
':' //; export TERM=xterm-256color
':' //; exec "$(command -v nodejs || command -v node)" "$0" "$@"
'use strict'
require('../source/javascript/index.js');
