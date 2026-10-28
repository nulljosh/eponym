#!/bin/sh
# Builds the watch app's models for the Mac and checks them against the live API.
set -e
cd "$(dirname "$0")"
swiftc -swift-version 6 -o /tmp/eponym-watch-tests Models/*.swift Harness/tests/main.swift
/tmp/eponym-watch-tests
