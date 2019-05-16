#!/usr/bin/env bash
#
# Usage:
#   logger.sh <log_txt> <command>...
#
# Arguments:
#   <log_txt>     Path to a log file
#   <command>     Bash command argument

set -uex

LOG_TXT="${1}" && shift 1

bash -c "${*}" 2>&1 | tee "${LOG_TXT}" && exit "${PIPESTATUS[0]}"
