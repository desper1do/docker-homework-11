#!/usr/bin/env bash
# Запуск стенда docker-homework-11. Повторный запуск безопасен:
# сеть и volume создаются только если их нет, контейнеры пересоздаются,
# данные в volume сохраняются.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
# shellcheck disable=SC1091
source ./project.env

NETWORK="${PROJECT}"
VOLUME="${PROJECT}-data"
BACKEND="${PROJECT}-backend"
FRONTEND="${PROJECT}-frontend"
BACKEND_IMAGE="${PROJECT}-backend:${VARIANT}"
FRONTEND_IMAGE="${PROJECT}-frontend:${VARIANT}"
# Внутренний порт nginx в контейнере. Нужен как переменная, чтобы потом
# воспроизвести неисправность варианта (неверный внутренний порт frontend).
FRONTEND_CONTAINER_PORT="${FRONTEND_CONTAINER_PORT:-80}"

echo "==> Сеть ${NETWORK}"
docker network inspect "${NETWORK}" >/dev/null 2>&1 || docker network create "${NETWORK}"

echo "==> Volume ${VOLUME}"
docker volume inspect "${VOLUME}" >/dev/null 2>&1 || docker volume create "${VOLUME}"

echo "==> Сборка образов"
docker build -q -f backend/Dockerfile -t "${BACKEND_IMAGE}" .
docker build -q -f frontend/Dockerfile -t "${FRONTEND_IMAGE}" .

echo "==> Удаляю старые контейнеры (если есть)"
docker rm -f "${BACKEND}" "${FRONTEND}" >/dev/null 2>&1 || true

echo "==> Запуск backend (порт на хост не публикуется)"
docker run -d --name "${BACKEND}" \
  --network "${NETWORK}" --network-alias backend \
  --cpus 0.5 --memory 128m --memory-swap 128m \
  -v "${VOLUME}:/data" \
  -e VARIANT="${VARIANT}" -e PERSONAL_ID="${PERSONAL_ID}" \
  "${BACKEND_IMAGE}" >/dev/null

echo "==> Запуск frontend (${HOST_PORT} -> ${FRONTEND_CONTAINER_PORT})"
docker run -d --name "${FRONTEND}" \
  --network "${NETWORK}" \
  --cpus 0.5 --memory 64m --memory-swap 64m \
  -p "${HOST_PORT}:${FRONTEND_CONTAINER_PORT}" \
  "${FRONTEND_IMAGE}" >/dev/null

echo "==> Жду healthcheck"
for name in "${BACKEND}" "${FRONTEND}"; do
  status=""
  for _ in $(seq 1 30); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "${name}" 2>/dev/null || true)"
    [[ "${status}" == "healthy" ]] && break
    sleep 1
  done
  echo "    ${name}: ${status:-unknown}"
  [[ "${status}" == "healthy" ]] || { echo "[ОШИБКА] ${name} не стал healthy" >&2; exit 1; }
done

echo
echo "Стенд запущен: http://localhost:${HOST_PORT}/  и  http://localhost:${HOST_PORT}/api"