#!/bin/sh
#
# Example external authenticator program for use with `ext_auth`.
#
INPUT=$(cat)

echo "$INPUT" > ./tmp.log
RESPONSE=$(curl -H "Content-Type: application/json" -X POST -d $INPUT --write-out %{http_code} --silent --output /dev/null http://authz:5000/authorized)

if [ "$RESPONSE" -ge "200" -a "$RESPONSE" -lt "300" ];then
    echo "valid request"
    exit 0
else
    echo "not valid request"
    exit 1
fi
exit 2