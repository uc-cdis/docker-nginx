#!/bin/sh

GEN3_DEBUG="${GEN3_DEBUG:-False}"
GEN3_DRYRUN="${GEN3_DRYRUN:-False}"
GEN3_UWSGI_TIMEOUT="${GEN3_UWSGI_TIMEOUT:-45s}"

run() {
  if [ "$GEN3_DRYRUN" = True ]; then
    echo "DRY RUN - not running: $@"
  else
    echo "Running $@"
    "$@"
  fi
}

help() {
    cat - <<EOM
Gen3 base (generic) launch script
Use: 
  dockkerrun.bash [--help] [--debug=False] [--dryrun=False]
EOM
}

while [ $# -gt 0 ]; do
  arg="$1"
  shift
  key=""
  value=""
  key="$(echo "$arg" | sed -e 's/^-*//' | sed -e 's/=.*$//')"
  value="$(echo "$arg" | sed -e 's/^.*=//')"

  if [ "$value" = "$arg" ]; then # =value not given, so use default
    value=""
  fi
  case "$key" in
  debug)
    GEN3_DEBUG="${value:-True}"
    ;;
  dryrun)
    GEN3_DRYRUN="${value:-True}"
    ;;
  help)
    help
    exit 0
    ;;
  *)
    echo "ERROR: unknown argument $arg - bailing out"
    exit 1
    ;;
  esac
done

cat - <<EOM
Got configuration:
GEN3_DEBUG=$GEN3_DEBUG
GEN3_DRYRUN=$GEN3_DRYRUN
EOM

cp /nginx.conf /etc/nginx/

if [[ $GEN3_DRYRUN == "False" ]]; then
  (
    while true; do
      logrotate --force /etc/logrotate.d/nginx
      sleep 86400
    done
  ) &
fi

if [[ $GEN3_DRYRUN == "False" ]]; then
  (
    while true; do
      curl -s http://127.0.0.1:9113/metrics >> /var/www/metrics/metrics.txt
      curl -s http://127.0.0.1:4040/metrics >> /var/www/metrics/metrics.txt
      sleep 10
    done
  ) &
fi

run nginx -g 'daemon off;'
wait
