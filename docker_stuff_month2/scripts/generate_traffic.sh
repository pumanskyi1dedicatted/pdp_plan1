#!/bin/bash
set -euo pipefail
request_count="200"
website_url="http://127.0.0.1:8080/"

paths=("/" "/index.html" "/none" "/admin")

for ((i = 0; i < "$request_count"; i++));
do
    path="${paths[RANDOM % ${#paths[@]}]}"
    code=$(curl -s -o /dev/null -w "%{http_code}" "${website_url}${path}")
    echo "${path} -> ${code}"
done

