#!/usr/bin/env bash

siteUrl=$1
functionUrl=$2
buildNo=$3

if [ -z ${siteUrl} ]; then
    echo siteUrl must be given
    exit 1
fi

if [ -z ${functionUrl} ]; then
    echo functionUrl must be given
    exit 1
fi

if [ -z ${buildNo} ]; then
    echo buildNo must be given
    exit 1
fi

main(){

URL="${siteUrl} --insecure -s -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}"

tries=100;
total_connect=0
total_start=0
total_time=0

        while [ $tries -gt 0 ]; do
                result=`curl $URL`
                var=$(echo $result | awk -F":" '{print $1, $2, $3}')
                set -- $var

                total_connect=`echo "scale=10; $total_connect + $1" | bc`;
                total_start=`echo "scale=10; $total_start + $2" | bc`;
                total_time=`echo "scale=10; $total_time + $3" | bc`;
                ((tries--))
        done

avgTimeConn=$(echo "`echo "scale=4; $total_connect/100" | bc`")
avgStartTime=$(echo "`echo "scale=4; $total_start/100" | bc`")
avgTakenTime=$(echo "`echo "scale=4; $total_time/100" | bc`")

# Write resultsto csv files
echo $avgTimeConn >> ./total_connect.csv
echo $avgStartTime >> ./total_start.csv
echo $avgTakenTime >> ./total_time.csv
#echo "`echo "scale=10; $total_connect/100" | bc`," >> ./total_connect.csv
#echo "`echo "scale=10; $total_start/100" | bc`," >> ./total_start.csv
#echo "`echo "scale=10; $total_time/100" | bc`," >> ./total_time.csv

echo $avgTimeConn
echo $avgStartTime 
echo $avgTakenTime 

curl --location --request POST "${functionUrl}" --header 'Content-Type: application/json' \
--data-raw "{\"filename\":\"average_responses_${buildNo}.png\", \"plottype\":\"line\", \"x\":[\"averagetimeconn\",\"averagestarttime\",\"averagetakentime\"], \"y\":[\"${avgTimeConn}\",\"${avgStartTime}\",\"${avgTakenTime}\"], \"ylab\":[\"first line\", \"second line\"]}"

echo "\n"
echo "https://storage.cloud.google.com/eadesignca2/average_responses_${buildNo}.png"

}


main

#eof