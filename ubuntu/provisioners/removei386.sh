#!/bin/sh

# remove i386 architecture (causes problems with rocci)
dpkg --remove-architecture i386
