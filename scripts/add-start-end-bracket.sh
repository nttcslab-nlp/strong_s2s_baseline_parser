#!/bin/bash
sed 's/^(/(TOP (/g'|\
sed 's/)$/))/g'
