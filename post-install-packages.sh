#!/bin/bash
mapfile -t packages < <(grep -vE '^\s*#|^\s*$'./packages.conf)
