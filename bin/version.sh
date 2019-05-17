#!/usr/bin/env bash
#
# Usage:
#   version.sh [<log_txt>]
#
# Arguments:
#   <log_txt>     Path to a log file

set -ue
[[ ${#} -ge 1 ]] \
  && [[ "${1}" = '--debug' ]] \
  && shift 1 \
  && set -x

CMDS=(
  'cat /etc/lsb-release'
  'bash --version'
  'pigz --version'
  'python --version'
  'perl --version'
  'java -version'
  'rsem-calculate-expression --version'
  'STAR --version'
  'prinseq-lite.pl --version'
  'fastqc --version'
)

if [[ ${#} -ge 1 ]]; then
  LOG_TXT="${1}"
  echo -n > "${LOG_TXT}"
  for c in "${CMDS[@]}"; do
    echo "\$ ${c}" | tee -a "${LOG_TXT}"
    bash -c "${c}" 2>&1 | tee -a "${LOG_TXT}"
  done
else
  for c in "${CMDS[@]}"; do
    echo "\$ ${c}"
    bash -c "${c}"
  done
fi
