#!/bin/bash

set -o errexit -o pipefail

RUNNER_ID=$1
RUNNER_NUMBER=$2

gcloud deployment-manager deployments describe yb-"$RUNNER_ID"-"$RUNNER_NUMBER" --format=json > output.json

# Find HOST
HOST_TO_TEST="$(jq '.outputs[3].finalValue' output.json | sed 's/"//g' | awk '{ print $2}')"

# Check UI Status
UI_HOST="$(jq '.outputs[0].finalValue' output.json | sed 's/"//g')"
UI_STATUS="$(curl -o /dev/null -s -w "%{http_code}\n" "$UI_HOST")"

if [[ "$UI_STATUS" -eq 200 ]]; then
  echo "UI is accessible"
else
  echo "UI isn't accessible"
fi

# Check YEDIS
REDIS_TEST="$(redis-cli -h "$HOST_TO_TEST" -p 6379 PING)"
if [[ "$REDIS_TEST" == "PONG" ]]; then
  echo "YEDIS API is accessible"
else
  echo "YEDIS API isn't accessible"

fi
# Check YSQL
echo "YSQL API Status"
pg_isready -h "$HOST_TO_TEST" -p 5433
