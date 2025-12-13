#!/bin/bash

cat ./data/basketball_scores.csv | sed 's/Lakers/LA Lakers/g' | sed 's/Celtics/Boston Celtics/g' > ./data/basketball_scores_edited.csv
