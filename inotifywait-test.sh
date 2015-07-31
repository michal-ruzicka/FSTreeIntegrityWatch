#!/bin/bash

watchdir=$(readlink -f $(dirname "${0}"))"/testdata/"

echo "### Watching for changes to \""${watchdir}"\" for ${timeout} seconds."
echo "### Work with \""${watchdir}"\" now."
echo

inotifywait --recursive --monitor --csv "${watchdir}"
