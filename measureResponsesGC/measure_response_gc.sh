#!/usr/bin/env bash

url=$1
buildNo=$2

if [ -z ${url} ]; then
    echo url must be given
    exit 1
fi

if [ -z ${buildNo} ]; then
    echo buildNo must be given
    exit 1
fi
main(){

echo $url
echo $buildNo

# URL='http://104.155.116.131:31916/allthenews?style=plain --insecure -s -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}'
# tries=100;
# total_connect=()
# total_start=()
# total_time=()
# echo ' Time_Connect Time_startTransfer Time_total ';
#         while [ $tries -gt 0 ]; do
#                 result=`curl $URL`
# #               echo $result;
#                 var=$(echo $result | awk -F':' '{print $1, $2, $3}')
#                 set -- $var
#                 total_connect+=('$1,')
#                 total_start+=('$2,')
#                 total_time+=('$3,')
#                 echo $tries
#                 ((tries--))
#         done
# echo '${total_connect[@]}' >> ./total_connect.csv
# echo '${total_start[@]}' >> ./total_start.csv
# echo '${total_time[@]}' >> ./total_time.csv
#echo 'average time connect: `echo 'scale=10; $total_connect/100' | bc`';
#echo 'average time start: `echo 'scale=10; $total_start/100' | bc`';
#echo 'average time taken: `echo 'scale=10; $total_time/100' | bc`';


# Construct curl
#curl -i -H 'Accept: application/json' -H 'Content-Type:application/json' -X POST --data '{'filename':'${buildNo}name.png', 'plottype':'line', 'x':['1', '2', '3', '4', '5'], 'y':['10', '8', '6', '15', '22', '0', '10', '8', '6', '15'], 'ylab':['first line', 'second line']}' $url

curl --location --request POST 'https://europe-west2-mscdevopscaauto.cloudfunctions.net/plotFunc' \
--header 'Content-Type: application/json' \
--data-raw '{"filename":"fname.png", "plottype":"line", "x":["1", "2", "3", "4", "5"], "y":["10", "8", "6", "15", "22", "0", "10", "8", "6", "15"], "ylab":["first line", "second line"]}'

# curl --location --request POST "$url" \
# --header 'Content-Type: application/json' \
# --data-raw '{"filename":'${buildNo}'name.png, "plottype":"line", "x":["1", "2", "3", "4", "5"], "y":["10", "8", "6", "15", "22", "0", "10", "8", "6", "15"], "ylab":["first line", "second line"]}'


# wget --no-check-certificate --quiet \
#   --method POST \
#   --timeout=0 \
#   --header 'Content-Type: application/json' \
#   --body-data '{"filename":"${buildNo}name.png", "plottype":"line", "x":["1", "2", "3", "4", "5"], "y":["10", "8", "6", "15", "22", "0", "10", "8", "6", "15"], "ylab":["first line", "second line"]}' \
#   "$url"

}


main

#eof