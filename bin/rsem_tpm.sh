#!/usr/bin/env bash
#
# Usage:
#   rsem_tpm.sh <fq_prefix> <ref_prefix> <out_dir> <thread>
#
# Arguments:
#   <fq_prefix>   Path prefix of input
#   <ref_prefix>  Path prefix of output reference
#   <out_dir>     Path to an output directory
#   <thread>      Number of threads

set -uex

IN_FQ_PREFIX="${1}"
OUT_REF_PREFIX="${2}"
OUT_MAP_DIR="${3}"
THREAD="${4}"
FQ_NAME=$(basename "${IN_FQ_PREFIX}")
OUT_MAP_PREFIX="${OUT_MAP_DIR}/${FQ_NAME}"
LOG_DIR="${OUT_MAP_DIR}/../log"
FQ1_GZ="${IN_FQ_PREFIX}.R1.fastq.gz"
FQ2_GZ="${IN_FQ_PREFIX}.R2.fastq.gz"

[[ -f "${FQ1_GZ}" ]]
[[ -f "${FQ2_GZ}" ]]

for p in ${OUT_MAP_DIR} ${LOG_DIR}; do
  [[ -d "${p}" ]] || mkdir "${p}"
done

rsem-calculate-expression \
  --star \
  --gzipped-read-file \
  --num-threads "${THREAD}" \
  --estimate-rspd \
  --calc-ci \
  --paired-end \
  "${FQ1_GZ}" \
  "${FQ2_GZ}" \
  "${OUT_REF_PREFIX}" \
  "${OUT_MAP_PREFIX}" \
  2>&1 | tee "${LOG_DIR}/rsem.star.map.${FQ_NAME}.log.txt"
