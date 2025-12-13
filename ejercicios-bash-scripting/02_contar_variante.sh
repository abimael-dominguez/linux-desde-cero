#!/bin/bash

cat ./data/basketball_scores.csv | grep -e "Lakers" -e "Celtics" | wc -l
