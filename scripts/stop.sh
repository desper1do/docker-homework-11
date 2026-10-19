#!/usr/bin/env bash
# Остановка стенда: удаляет контейнеры, volume и сеть сохраняются.
# С флагом --purge дополнительно удаляются volume и сеть.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
# shellcheck disable=SC1091
source ./project.env

NETWORK="${PROJECT}"
VOLUME="${PROJECT}-data"

echo "==> Удаляю контейнеры"
docker rm -f "${PROJECT}-backend" "${PROJECT}-frontend" >/dev/null 2>&1 || true

if [[ "${1:-}" == "--purge" ]]; then
  echo "==> Удаляю volume ${VOLUME} и сеть ${NETWORK}"
  docker volume rm "${VOLUME}" >/dev/null 2>&1 || true
  docker network rm "${NETWORK}" >/dev/null 2>&1 || true
else
  echo "Volume ${VOLUME} сохранён (для полной очистки: ./scripts/stop.sh --purge)"
fi