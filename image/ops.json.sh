#!/usr/bin/env bash

JSON_BODY=""

add_user() {
    USER='{"uuid": "'"$1"'", "level": "'"$2"'", "name": "'"$3"'", "bypassesPlayerLimit": '"$4"'}'
    if [[ -z $JSON_BODY ]]; then
        JSON_BODY="  $USER"
    else
        JSON_BODY="$JSON_BODY,
  $USER"
    fi
}

add_user 6cde5c61-9493-4726-b580-a74e751e5eb4 4 anatawa12 true
add_user 6682c0b9-3ce3-4cae-84b4-e6ffc42e664d 3 subaru1572 true

echo "[
$JSON_BODY
]" > ops.json
