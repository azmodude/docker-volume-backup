#!/bin/bash

usage="$(basename "$0") [-h] -v -a -o -- restore docker volume

where:
-h  show this help text
-v  volume name
-a  archive name (extension will be added automatically)
-o  input directory (default: $(pwd)/backup)
-f  force backup of containers currently in use (not recommended)"

while getopts ':hfv:a:i:' option; do
    case "$option" in
        h) echo "$usage"
            exit
            ;;
        v) volume=$OPTARG
            ;;
        a) archive=$OPTARG
            ;;
        i) inputdir=$OPTARG
            ;;
        f) force=1
            ;;
        :) printf "missing argument for -%s\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
        \?) printf "illegal option: -%s\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [[ -z "${volume}" || -z "${archive}" ]]; then
    echo "${usage}"
    exit
fi

if [[ ! -d "${inputdir}" ]]; then
    >&2 echo "'${inputdir}' is not a directory"
    exit 1
fi

volume_exists=$(docker volume ls | grep -c "${volume}")
if [[ $volume_exists -eq 0 ]]; then
    >&2 echo "volume '${volume}' does not seem to exist"
    exit 1
fi
containers_using_volume=$(docker ps --filter=volume="${volume}" | wc -l)
if [[ "${containers_using_volume}" -ne 1 && "${force}" -ne 1 ]]; then # headers result in 1
    >&2 echo "volume '${volume}' is in use - cowardly refusing to restore"
    exit 1
fi

>&2 echo -n "starting restore of volume '${volume}' from '${inputdir}' with "
>&2 echo "archivename '${archive}'"

docker run -v "${volume}":/volume -v "${inputdir}":/backup --rm volumebackup \
    restore "${archive}"
