#!/usr/bin/env bash
#
# Usage:
#   rsem_ref.sh <gtf> <fna> <ref_prefix> <thread>
#
# Arguments:
#   <gtf>         Path to a reference GTF file
#   <fna>         Path to a reference FASTA file
#   <ref_prefix>  Path prefix of output reference
#   <thread>      Number of threads

set -uex

IN_REF_GTF="${1}"
IN_REF_FNA="${2}"
OUT_REF_PREFIX="${3}"
THREAD="${4}"
OUT_REF_DIR=$(dirname "${OUT_REF_PREFIX}")
OUT_REF_FNA="${OUT_REF_PREFIX}.fna"
OUT_REF_PA_FNA="${OUT_REF_PREFIX}.primary_assembly.fna"
OUT_REF_GTF="${OUT_REF_PREFIX}.gtf"
REF_NAME=$(basename "${OUT_REF_PREFIX}")
LOG_DIR="${OUT_REF_DIR}/../log"
LOG_TXT="${LOG_DIR}/rsem.ref.${REF_NAME}.log.txt"

[[ -f "${IN_REF_GTF}" ]]
[[ -f "${IN_REF_FNA}" ]]

for p in ${OUT_REF_DIR} ${LOG_DIR}; do
  [[ -d "${p}" ]] || mkdir "${p}"
done

[[ -f "${OUT_REF_GTF}" ]] \
  || pigz -p "${THREAD}" -dc "${IN_REF_GTF}" > "${OUT_REF_GTF}"
[[ -f "${OUT_REF_FNA}" ]] \
  || pigz -p "${THREAD}" -dc "${IN_REF_FNA}" > "${OUT_REF_FNA}"

rsem-refseq-extract-primary-assembly \
  "${OUT_REF_FNA}" \
  "${OUT_REF_PA_FNA}" \
  2>&1 | tee "${LOG_TXT}"

rsem-prepare-reference \
  --star \
  --num-threads "${THREAD}" \
  --gtf "${OUT_REF_GTF}" \
  "${OUT_REF_PA_FNA}" \
  "${OUT_REF_PREFIX}" \
  2>&1 | tee -a "${LOG_TXT}"
