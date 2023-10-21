#!/bin/bash

export URL="http://localhost/"

ab -n 5000 -c 50 $URL
