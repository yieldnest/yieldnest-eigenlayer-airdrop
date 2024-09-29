#!/bin/bash

set -e

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq could not be found. Please install jq to use this script."
    exit 1
fi

# Check if a CSV file was provided as an argument
if [ -z "$1" ]; then
    echo "Please provide a CSV file as an argument."
    exit 1
fi

# Get the CSV file name from the argument
csv_file="$1"
echo "Input CSV file: $csv_file"

# Convert the CSV file to JSON using jq
jq -R -s -c '
  split("\n") |
  .[0:] |
  map(split(",")) |
    map(
    if .[0] == "Total ynETH Holder Eigen Points" then
      {
        "Total ynETH Holder Eigen Points": .[1],

      }
    else if .[0] == "Total Eigen Points to Aug 15th" then
    {
        "Total Eigen Points to Aug 15th": .[1],
    }
    else
    {
      "addr": .[0],
      "points": .[1],
      "percentage": .[2] | rtrimstr("\r")
    }
    end
    end

    | select(.["addr"] != "" and .["points"] != "" and .["percentage"] != "")

  )

' "$csv_file" | jq '{
  eigenPoints: [
    .[] | select(.addr != null)
  ],
  totalYnETHHolderEigenPoints: (.[] | select(has("Total ynETH Holder Eigen Points"))."Total ynETH Holder Eigen Points"),
  totalEigenPointsToAug15th: (.[] | select(has("Total Eigen Points to Aug 15th"))."Total Eigen Points to Aug 15th")
}' | jq '
  del(.eigenPoints[].percentage)
  | .eigenPoints[].points |= (tonumber * 100 | floor)
  | .totalYnETHHolderEigenPoints |= (tonumber * 100 | floor)
  | .totalEigenPointsToAug15th |= (tonumber * 100 | floor)
' | jq . | tee "${csv_file%.csv}.json" > /dev/null

echo "Output JSON file: ${csv_file%.csv}.json"
