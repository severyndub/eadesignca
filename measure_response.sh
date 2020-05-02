#!/usr/bin/env bash



main(){

URL="http://104.155.116.131:31916/allthenews?style=plain --insecure -s -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}"
# tries=100;
# total_connect=()
# total_start=()
# total_time=()
# echo " Time_Connect Time_startTransfer Time_total ";

#         while [ $tries -gt 0 ]; do

#                 result=`curl $URL`
# #               echo $result;
#                 var=$(echo $result | awk -F":" '{print $1, $2, $3}')
#                 set -- $var

#                 total_connect+=("$1,")
#                 total_start+=("$2,")
#                 total_time+=("$3,")
#                 echo $tries
#                 ((tries--))
#         done
# echo "${total_connect[@]}" >> ./total_connect.csv
# echo "${total_start[@]}" >> ./total_start.csv
# echo "${total_time[@]}" >> ./total_time.csv
# #echo "average time connect: `echo "scale=10; $total_connect/100" | bc`";
# #echo "average time start: `echo "scale=10; $total_start/100" | bc`";
# #echo "average time taken: `echo "scale=10; $total_time/100" | bc`";




# }


# main


#################################################### KEEP old ver #############################################
# url=$1



# URL="${url} --insecure -s -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}"
tries=100;
total_connect=0
total_start=0
total_time=0
echo " Time_Connect Time_startTransfer Time_total ";

        while [ $tries -gt 0 ]; do

                result=`curl $URL`
                echo $result;
                var=$(echo $result | awk -F":" '{print $1, $2, $3}')
                set -- $var

                total_connect=`echo "scale=10; $total_connect + $1" | bc`;
                total_start=`echo "scale=10; $total_start + $2" | bc`;
                total_time=`echo "scale=10; $total_time + $3" | bc`;
                ((tries--))
        done
echo $total_connect
echo $total_start
echo $total_time
echo "average time connect: `echo "scale=10; $total_connect/100" | bc`";
echo "average time start: `echo "scale=10; $total_start/100" | bc`";
echo "average time taken: `echo "scale=10; $total_time/100" | bc`";

}


main

#eof