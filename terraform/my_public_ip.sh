#!/usr/bin/env bash

echo '{ "ip": "'$(dig +short myip.opendns.com @resolver1.opendns.com)'"}'
