#!/bin/sh

killall XCreds

if [ -d "/Applications/XCreds.app" ] ; then 
    rm -rf "/Applications/XCreds.app" 
fi

