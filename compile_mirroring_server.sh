#!/bin/bash -xe

STACK_ROOT=$HOME/new-stack-root


STACK_SETUP_FILE_REMOTE_URL=https://raw.githubusercontent.com/fpco/stackage-content/master/stack/stack-setup-2.yaml
STACK_SETUP_LOCAL_FILEPATH=stack-setup-2.yaml


curl -o $STACK_SETUP_LOCAL_FILEPATH -L --insecure $STACK_SETUP_FILE_REMOTE_URL


sed "s/https\:\//http\:\/\/localhost\:3000\/https/g" $STACK_SETUP_LOCAL_FILEPATH > setup.yaml
mkdir -p $STACK_ROOT

cp config.yaml $STACK_ROOT

# =================================
# Run fileserver

HTTP_REDIRECT_BINARY_FILENAME=http-redirect

cabal update
cabal install -j1 --ghc-options=-j

cp dist/build/http-redirect/$HTTP_REDIRECT_BINARY_FILENAME .

./$HTTP_REDIRECT_BINARY_FILENAME
