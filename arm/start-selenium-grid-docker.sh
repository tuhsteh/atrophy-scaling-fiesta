#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Node Docker..."

function append_se_opts() {
  local option="${1}"
  local value="${2:-""}"
  local log_message="${3:-true}"
  if [[ "${SE_OPTS}" != *"${option}"* ]]; then
    if [ "${log_message}" = "true" ]; then
      echo "Appending Selenium option: ${option} ${value}"
    else
      echo "Appending Selenium option: ${option} $(mask ${value})"
    fi
    SE_OPTS="${SE_OPTS} ${option}"
    if [ ! -z "${value}" ]; then
      SE_OPTS="${SE_OPTS} ${value}"
    fi
  else
    echo "Selenium option: ${option} already set in env variable SE_OPTS. Ignore new option: ${option} ${value}"
  fi
}

if [[ -z "${SE_EVENT_BUS_HOST}" ]]; then
  echo "SE_EVENT_BUS_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_PUBLISH_PORT}" ]]; then
  echo "SE_EVENT_BUS_PUBLISH_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_SUBSCRIBE_PORT}" ]]; then
  echo "SE_EVENT_BUS_SUBSCRIBE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_NODE_GRID_URL" ]; then
  echo "Appending Grid url: ${SE_NODE_GRID_URL}"
  SE_GRID_URL="--grid-url ${SE_NODE_GRID_URL}"
fi

if [ ! -z "$SE_LOG_LEVEL" ]; then
  append_se_opts "--log-level" "${SE_LOG_LEVEL}"
fi

if [ ! -z "$SE_HTTP_LOGS" ]; then
  append_se_opts "--http-logs" "${SE_HTTP_LOGS}"
fi

if [ ! -z "$SE_STRUCTURED_LOGS" ]; then
  append_se_opts "--structured-logs" "${SE_STRUCTURED_LOGS}"
fi

if [ ! -z "$SE_EXTERNAL_URL" ]; then
  append_se_opts "--external-url" "${SE_EXTERNAL_URL}"
fi

if [ "${SE_ENABLE_TLS}" = "true" ]; then
  # Configure truststore for the server
  if [ ! -z "$SE_JAVA_SSL_TRUST_STORE" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
  fi
  if [ -f "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Getting Truststore password from ${SE_JAVA_SSL_TRUST_STORE_PASSWORD} to set Java options: -Djavax.net.ssl.trustStorePassword"
    SE_JAVA_SSL_TRUST_STORE_PASSWORD="$(cat ${SE_JAVA_SSL_TRUST_STORE_PASSWORD})"
  fi
  if [ ! -z "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStorePassword=$(mask ${SE_JAVA_SSL_TRUST_STORE_PASSWORD})"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${SE_JAVA_SSL_TRUST_STORE_PASSWORD}"
  fi
  echo "Appending Java options: -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  # Configure certificate and private key for component communication
  if [ ! -z "$SE_HTTPS_CERTIFICATE" ]; then
    append_se_opts "--https-certificate" "${SE_HTTPS_CERTIFICATE}"
  fi
  if [ ! -z "$SE_HTTPS_PRIVATE_KEY" ]; then
    append_se_opts "--https-private-key" "${SE_HTTPS_PRIVATE_KEY}"
  fi
fi

if [ ! -z "${SE_NODE_DOCKER_CONFIG_FILENAME}" ]; then
  CONFIG_FILE="/opt/selenium/${SE_NODE_DOCKER_CONFIG_FILENAME}"
fi

echo "Selenium Grid Node Docker configuration: "
cat "${CONFIG_FILE}"

EXTRA_LIBS=""
if [ -n "${SE_EXTRA_LIBS}" ]; then
  EXTRA_LIBS="--ext ${SE_EXTRA_LIBS}"
fi

if [ "${SE_ENABLE_TRACING}" = "true" ] && [ -n "${SE_OTEL_EXPORTER_ENDPOINT}" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  if [ -n "${EXTRA_LIBS}" ] && [ -n "${EXTERNAL_JARS}" ]; then
    EXTRA_LIBS="${EXTRA_LIBS}:${EXTERNAL_JARS}"
  elif [ -z "${EXTRA_LIBS}" ] && [ -n "${EXTERNAL_JARS}" ]; then
    EXTRA_LIBS="--ext ${EXTERNAL_JARS}"
  fi
  echo "Tracing is enabled"
  if [ -n "$SE_OTEL_SERVICE_NAME" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.resource.attributes=service.name=${SE_OTEL_SERVICE_NAME}${SE_OTEL_RESOURCE_ATTRIBUTES:+,${SE_OTEL_RESOURCE_ATTRIBUTES}}"
  fi
  if [ -n "$SE_OTEL_TRACES_EXPORTER" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.traces.exporter=${SE_OTEL_TRACES_EXPORTER}"
  fi
  if [ -n "$SE_OTEL_EXPORTER_ENDPOINT" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.exporter.otlp.endpoint=$(envsubst < <(echo ${SE_OTEL_EXPORTER_ENDPOINT}))"
  fi
  if [ -n "$SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.java.global-autoconfigure.enabled=${SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED}"
  fi
  if [ -n "$SE_OTEL_JVM_ARGS" ]; then
    SE_JAVA_OPTS="$SE_JAVA_OPTS ${SE_OTEL_JVM_ARGS}"
  fi
else
  append_se_opts "--tracing" "false"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Dwebdriver.remote.enableTracing=false"
  echo "Tracing is disabled"
fi

if [ -n "${EXTRA_LIBS}" ]; then
  echo "Classpath will be enriched with these external jars : ${EXTRA_LIBS}"
fi

if [ -n "${SE_JAVA_HTTPCLIENT_VERSION}" ]; then
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Dwebdriver.httpclient.version=${SE_JAVA_HTTPCLIENT_VERSION}"
fi

if [ -n "${SE_JAVA_OPTS_DEFAULT}" ]; then
  SE_JAVA_OPTS="${SE_JAVA_OPTS_DEFAULT} $SE_JAVA_OPTS"
fi

function handle_heap_dump() {
  /opt/bin/handle_heap_dump.sh /opt/selenium/logs
}
if [ "${SE_JAVA_HEAP_DUMP}" = "true" ]; then
  SE_JAVA_OPTS="$SE_JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/selenium/logs"
  trap handle_heap_dump ERR SIGTERM SIGINT
fi

if [ -n "${JAVA_OPTS}" ]; then
  SE_JAVA_OPTS="$SE_JAVA_OPTS ${JAVA_OPTS}"
fi

echo "Using JAVA_OPTS: ${SE_JAVA_OPTS}"

java ${SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} node \
  --publish-events tcp://"${SE_EVENT_BUS_HOST}":${SE_EVENT_BUS_PUBLISH_PORT} \
  --subscribe-events tcp://"${SE_EVENT_BUS_HOST}":${SE_EVENT_BUS_SUBSCRIBE_PORT} \
  --bind-host ${SE_BIND_HOST} \
  --detect-drivers false \
  --config ${CONFIG_FILE} \
  ${SE_GRID_URL} ${SE_OPTS}

