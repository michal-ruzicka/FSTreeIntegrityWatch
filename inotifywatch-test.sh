#!/bin/bash

timeout=20
watchdir=$(readlink -f $(dirname "${0}"))"/testdata/"

echo "### Watching for changes to \""${watchdir}"\" for ${timeout} seconds."
echo "### Work with \""${watchdir}"\" now."
echo

inotifywatch --verbose --recursive --timeout "${timeout}" "${watchdir}"
