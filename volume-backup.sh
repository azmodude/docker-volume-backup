#!/bin/sh

usage() {
    echo "Usage: volume-backup <backup|restore> <archive>"
    exit
}

backup() {
    mkdir -p $(dirname "/backup/${archive}")
    tar -cjf "/backup/${archive}" -C /volume ./
}

restore() {
    if ! [ -e "/backup/${archive}" ]; then
        echo "archive file $archive does not exist"
        exit 1
    fi

    rm -rf /volume/* /volume/..?* /volume/.[!.]*
    tar -C /volume/ -xjf "/backup/${archive}"
}

# Needed because sometimes pty is not ready when executing docker-compose run
# See https://github.com/docker/compose/pull/4738 for more details
# TODO: remove after above pull request or equivalent is merged
sleep 1

if [ $# -ne 2 ]; then
    usage
fi

operation=$1
archive=${2%%.tar.bz2}.tar.bz2

case "${operation}" in
    "backup" )
        backup
        ;;
    "restore" )
        restore
        ;;
    * )
        usage
        ;;
esac
