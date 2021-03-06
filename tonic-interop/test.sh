#!/usr/bin/env bash

set -eu
set -o pipefail

case "$OSTYPE" in
  darwin*)  OS="darwin" ;;
  linux*)   OS="linux" ;;
  *)        exit 2 ;;
esac

cargo build -p tonic-interop --bins

ARG="${1:-""}"
SERVER="tonic-interop/bin/server_${OS}_amd64"

# TLS_CA="tonic-interop/data/ca.pem"
TLS_CRT="tonic-interop/data/server1.pem"
TLS_KEY="tonic-interop/data/server1.key"

# run the test server
./"${SERVER}" $ARG --tls_cert_file $TLS_CRT --tls_key_file $TLS_KEY &
SERVER_PID=$!
echo ":; started grpc-go test server."

# trap exits to make sure we kill the server process when the script exits,
# regardless of why (errors, SIGTERM, etc).
trap 'echo ":; killing test server"; kill ${SERVER_PID};' EXIT

sleep 1

./target/debug/client \
 --test_case=empty_unary,large_unary,client_streaming,server_streaming,ping_pong,\
empty_stream,status_code_and_message,special_status_message,unimplemented_method,\
unimplemented_service,custom_metadata $ARG

echo ":; killing test server"; kill ${SERVER_PID};

# run the test server
./target/debug/server $ARG &
SERVER_PID=$!
echo ":; started tonic test server."

# trap exits to make sure we kill the server process when the script exits,
# regardless of why (errors, SIGTERM, etc).
trap 'echo ":; killing test server"; kill ${SERVER_PID};' EXIT

sleep 1

./target/debug/client \
--test_case=empty_unary,large_unary,client_streaming,server_streaming,ping_pong,\
empty_stream,status_code_and_message,special_status_message,unimplemented_method,\
unimplemented_service,custom_metadata $ARG
