#!/bin/bash

# Configuration
CLUSTER_NAME="isca"
PERL_SCRIPT="./sacct2csv_v4a.pl"

# 2024-01-01 is a Monday
START_DATE="2020-08-17"
#START_DATE="2025-03-03"
END_DATE="2025-09-01"
END_DATE="$(date +'%F')"
DEBUG=""

# Uncomment the next line to enable debug output
# DEBUG="--debug"

# Function to convert date to epoch
to_epoch() {
  date -d "$1" +"%s"
}

# Function to add 7 days
add_week() {
  date -d "$1 +7 days" +"%Y-%m-%d"
}

# Initialize
current_date="$START_DATE"

while [ "$(to_epoch "$current_date")" -lt "$(to_epoch "$END_DATE")" ]; do
  echo "Running for week starting $current_date"
  
 perl $PERL_SCRIPT \
    --starttime="$current_date" \
    --duration=week \
    --cluster="$CLUSTER_NAME" \
    $DEBUG

  # Move to next week
  current_date=$(add_week "$current_date")
done

echo "All weeks processed."
