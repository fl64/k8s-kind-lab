#!/usr/bin/env bash

while true; do
  TIMESTAMP=$(date +'%D %H:%M:%S')
  # echo "${SERVICE_TO_CURL}"
  # curl "${SERVICE_TO_CURL}" -H "x-v2: v2" -sq
  RESULT=$(curl --max-time 2 -H "x-v2: v2" "${SERVICE_TO_CURL}" -qs | jq --arg timestamp "${TIMESTAMP}" --arg my_node_name "${MY_NODE_NAME}" '. |
  {
    "timestamp": $timestamp,
    "pod": .env.pod_name,
    "pod_ip": .env.pod_ip,
    "ver": .env.version,
    "my_node_name": $my_node_name,
    "remote_node_name": .env.node_name,
    "headers": .request
  }')
  echo "${RESULT}" | jq .
  #curl --max-time 2 "${SERVICE_TO_CURL}/asdasd" -XGET
  sleep "${SLEEP_INTERVAL}"
  echo ---
done
