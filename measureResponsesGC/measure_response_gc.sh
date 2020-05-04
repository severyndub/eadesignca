#!/usr/bin/env bash
# Script sourced from intyernet source: https://www.hungred.com/useful-information/average-website-response-time-bash-script/

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

tries=0;
total_connect=()
total_start=()
total_time=()
counter=()

        while [ $tries -lt 100 ]; do
                result=`curl $URL`
                var=$(echo $result | awk -F":" '{print $1, $2, $3}')
                set -- $var
                total_connect+=("$1,")
                total_start+=("$2,")
                total_time+=("$3,")
                counter+=("\"$tries\",")
                ((tries++))
        done

# Record counter
counterOutput=$(echo "${counter[@]}")
counterOutputFormated=${counterOutput::-1}

# Total time connect
totalConnectOutput=$(echo "${total_connect[@]}")
totalConnectOutputFormated=${totalConnectOutput::-1}
echo $totalConnectOutputFormated

# Total start transfer
totalStartOutput=$(echo "${total_start[@]}")
totalStartOutputFormated=${totalStartOutput::-1}
echo $totalStartOutputFormated

# Total time
totalTimeOutput=$(echo "${total_time[@]}")
totalTimeOutputFormated=${totalTimeOutput::-1}
echo $totalTimeOutputFormated

curl --location --request POST "$functionUrl" --header 'Content-Type: application/json' \
--data-raw "{\"filename\":\"total_connect_${buildNo}.png\", \"plottype\":\"line\", \"x\":[${totalConnectOutputFormated}], \"y\":[${counterOutputFormated}], \"ylab\":[\"first line\", \"second line\"]}"

curl --location --request POST "$functionUrl" --header 'Content-Type: application/json' \
--data-raw "{\"filename\":\"total_start_transfer_${buildNo}.png\", \"plottype\":\"line\", \"x\":[${totalStartOutputFormated}], \"y\":[${counterOutputFormated}], \"ylab\":[\"first line\", \"second line\"]}"

curl --location --request POST "$functionUrl" --header 'Content-Type: application/json' \
--data-raw "{\"filename\":\"total_time_${buildNo}.png\", \"plottype\":\"line\", \"x\":[${totalTimeOutputFormated}], \"y\":[${counterOutputFormated}], \"ylab\":[\"first line\", \"second line\"]}"


echo "\n"
echo "https://storage.cloud.google.com/eadesignca2/total_connect_${buildNo}.png"
echo "https://storage.cloud.google.com/eadesignca2/total_start_transfer_${buildNo}.png"
echo "https://storage.cloud.google.com/eadesignca2/total_time_${buildNo}.png"


}


main

#eof