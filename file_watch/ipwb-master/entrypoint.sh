#!/usr/bin/env bash

set -e

if [[ ("$@" != "ipwb") && ("$@" != *" -h"*) && ("$@" != *" --help"*) ]]
then
    # Run the IPFS daemon in background, initialize configs if necessary
    ipfs daemon 
fi