#!/bin/bash

export PATH="$PATH:/home/pi/.rvm/bin"

cd /home/pi/disko2
rvm 2.2.3@disko exec foreman start > boot.log 2>&1
