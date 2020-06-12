#!/bin/bash

if [ ! -x "$(command -v jq)" ]; then
  echo 'You must install jq for this to work.'
  echo 'Run `brew install jq` to install.'
  exit 0
fi

# The location to download to, defaults to the current folder if a .download file doesn't exist
if [ -f .download_location ]; then
    DOWNLOADTO=`cat .download_location`
else
    DOWNLOADTO="$(pwd)/images"
fi

# Paste the value of the -H 'Cookie: ' param into the .cookie file
COOKIE=`cat .cookie`

# Paste the value of the -H 'x-tadpoles-uid: ' param into the .email file
EMAIL=`cat .email`

# Get dates from the user
start_date=$( date -v -30d +"%Y-%m-%d" )
echo "What start date should I use? (format: YYYY-mm-dd, default: $start_date)"
read start_date_in
if [ "$start_date_in" != "" ]; then
	start_date=$start_date_in
fi

end_date=$( date -j -u -f "%Y-%m-%d" -v +30d "${start_date}" +"%Y-%m-%d" )
#end_date=$( date +"%Y-%m-%d" )
echo "What end date should I use? (format: YYYY-mm-dd, default: $end_date)"
read end_date_in
if [ "$end_date_in" != "" ]; then
	end_date=$end_date_in
fi

echo "Retrieving images between $start_date and $end_date"

# Convert to timestamp
start_date_timestamp=$( date -j -u -f "%Y-%m-%d" "${start_date}" +"%s" )
end_date_timestamp=$( date -j -u -f "%Y-%m-%d" "${end_date}" +"%s" )

# Create files for these ranges
output_file="attachments_${start_date}_${end_date}.json"
events_file="events_${start_date}_${end_date}.json"

# Download all the events for this period
curl -sS "https://www.tadpoles.com/remote/v1/events?direction=range&earliest_event_time=${start_date_timestamp}&latest_event_time=${end_date_timestamp}&num_events=300&client=dashboard" -H "cookie: ${COOKIE}" -H "x-tadpoles-uid: ${EMAIL}" -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: en-US,en;q=0.9' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36' -H 'accept: application/json, text/javascript, */*; q=0.01' -H 'referer: https://www.tadpoles.com/parents' -H 'authority: www.tadpoles.com' -H 'x-requested-with: XMLHttpRequest' --compressed > ${events_file}

# Get the data we need from that list of events
jq --compact-output ".events | .[] | {event_date: .event_date, key: .new_attachments | .[] | .key, mime_type: .new_attachments | .[] | .mime_type}" ${events_file}  >> ${output_file}

# How many are we getting?
totalimages=$(wc -l < "${output_file}")
# trim spaces
totalimages=${totalimages//[[:blank:]]}

if [ $totalimages -lt 215 ]; then
    echo "Found ${totalimages} for date range"
else
    echo "Found ${totalimages} for date range. You should download a smaller time range as this may not include all available images."
fi

# Get the images
index=0

# Read through the output file of image locations and download each one
exec 4< ${output_file}
while read <&4 LINE; do
	index=$((index+1))

	date=$(echo ${LINE} | jq --raw-output .event_date)
	chrlen=${#date} # count char
    yearmonth=${date:0:($chrlen-3)} # remove day (-01)

    mkdir -p "${DOWNLOADTO}/${yearmonth}"

	key=$(echo ${LINE} | jq --raw-output .key)

	FILE_EXT=".jpg"
	mime_type=$(echo ${LINE} | jq --raw-output .mime_type)
	if [ "$mime_type" == "image/jpeg" ]; then
		FILE_EXT=".jpg"
	elif [ "$mime_type" == "video/mp4" ]; then
		FILE_EXT=".mp4"
	elif [ "$mime_type" == "application/pdf" ]; then
		FILE_EXT=".pdf"
	fi

    FILENAME="${DOWNLOADTO}/${yearmonth}/tadpoles_${key}_${INDEX}${FILE_EXT}"
    if [ ! -e $FILENAME ]; then
    	echo -ne "   Downloading Images $index of $totalimages                \r"
		pd=$(curl -sS --compressed -o "$FILENAME" "https://www.tadpoles.com/remote/v1/attachment?key=${key}" -H "Cookie: ${COOKIE}" -H 'Host: www.tadpoles.com' -H 'Accept: */*' -H 'Connection: keep-alive' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:52.0) Gecko/20100101 Firefox/52.0' -H 'Accept-Language: en-US,en;q=0.5' -H 'Referer: https://www.tadpoles.com/parents')
    else
        echo -ne "   Already downloaded images $index of $totalimages         \r"
    fi
done

# Wait for all downloads to complete
wait $pd

rm ${output_file}
rm ${events_file}

echo -ne "\n"
echo "Done!"
