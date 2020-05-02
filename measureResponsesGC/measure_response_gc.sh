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
fileName = "eadesign_sync_${buildNo}"
echo $fileName
URL='http://104.155.116.131:31916/allthenews?style=plain --insecure -s -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}'
tries=1;
total_connect=()
total_start=()
total_time=()
counter=()
echo " Time_Connect Time_startTransfer Time_total ";

        while [ $tries -lt 100 ]; do
                result=`curl $URL`
                var=$(echo $result | awk -F":" '{print $1, $2, $3}')
                set -- $var
                total_connect+=("\"$1\",")
                total_start+=("$2,")
                total_time+=("$3,")
                ((tries++))
                counter+=("\"$tries\"")
        done

#echo "${counter[@]}"
#echo "${total_connect[@]}"
# echo "${total_connect[@]}" >> ./total_connect.csv
# echo "${total_start[@]}" >> ./total_start.csv
# echo "${total_time[@]}" >> ./total_time.csv
#echo "average time connect: `echo "scale=10; $total_connect/100" | bc`";
#echo "average time start: `echo "scale=10; $total_start/100" | bc`";
#echo "average time taken: `echo "scale=10; $total_time/100" | bc`";


curl --location --request POST "$url" --header 'Content-Type: application/json' \
--data-raw "{\"filename\":\"total_connect_${fileName}.png\", \"plottype\":\"line\", \"x\":[${counter[@]}], \"y\":[${total_connect[@]}], \"ylab\":[\"first line\", \"second line\"]}"

echo "\n"
echo "https://storage.cloud.google.com/eadesignca1/total_connect_${fileName}.png"

}


main

#eof