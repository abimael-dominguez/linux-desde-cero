#!/bin/bash

what_day_is_it() {
    date=$(date | cut -d " " -f1)
    echo "$date"
}

what_day_is_it