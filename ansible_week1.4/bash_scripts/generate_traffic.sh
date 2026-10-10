#!/bin/bash
set -euo pipefail
request_count="200"
website_url="http://nginx.dedicatted.com"

paths=("/" "/index.html" "/none" "/admin")

for ((i = 0; i < "$request_count"; i++));
do
    path="${paths[RANDOM % ${#paths[@]}]}"
    code=$(curl -s -o /dev/null -w "%{http_code}" "${website_url}${path}")
    echo "${path} -> ${code}"
done

