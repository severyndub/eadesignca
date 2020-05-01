#!/usr/bin/env bash

ruleName='mscdevopsca-port'
portNumber=$1
ruleFullName="${ruleName}-${portNumber}"
result=0

if [ -z ${portNumber} ]; then
        echo port number must be present
        exit 1
fi

checkRuleExists(){
        ruleExists=($(gcloud compute firewall-rules list --format=json | grep ${ruleFullName} | awk 'NR<2 { print $2}' | cut -d "," -f 1 | cut -d "\"" -f 2))

        #ruleExists is empty, means the rule does not exists yet, creat it
        if [[ -z ${ruleExists} ]];
        then
                result=0
        fi

        # Validate rule exists
        if [[ ${ruleFullName} == ${ruleExists} ]];
        then
                # rule Exists contains the text, rule exists, do not create
                result=1
        else
                # rule does not exist, its not in the output, create
                result=0
        fi

}


main(){
        checkRuleExists
        echo $result

        if [[ $result == 1 ]];
        then
                echo "Rule with name ${ruleFullName} exists, doing nothing."
        else
                echo "Rule with name ${ruleFullName} does not exist, create now"
                gcloud config set project 'mscdevopscaauto'
                gcloud compute firewall-rules create ${ruleFullName} --allow tcp:${portNumber}
        fi
}

main