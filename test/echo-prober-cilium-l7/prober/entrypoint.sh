#!/usr/bin/env bash

: ${HEADER:="XXX: YYY"}
: ${JQ_QUERY:="{ ver: .env.version, node: .env.node_name, sa: .env.service_account }"}

while true; do
  echo "[ HTTPS ] =========================="
  curl --max-time 10 --connect-timeout 10 -k -XGET "https://${SERVICE_TO_CURL}:63443" -H"${HEADER}" -sq | jq "${JQ_QUERY}"
  echo "[ HTTP ] =========================="
  curl --max-time 10 --connect-timeout 10 -k -XGET "http://${SERVICE_TO_CURL}:63636" -H"${HEADER}" -sq | jq "${JQ_QUERY}"
  echo "[ TCP ] =========================="
  echo "${MY_POD_NAME}" | nc -v -w 2 -q 1 "${SERVICE_TO_CURL}" 61234


  curl --max-time 2  "http://echo-2.echo-cilium-2.svc:63636"
  curl --max-time 2  "http://echo-3.echo-cilium-3.svc:2222"
  sleep ${SLEEP_TIMEOUT:-1}
done
