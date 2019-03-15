#!/bin/bash
perl -pe 'chomp; $_="<s> ".$_." </s>\n"'
