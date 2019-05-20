#!/usr/bin/env bash
#
# Usage:
#   rsem_tpm.sh <fq_prefix> <ref_prefix> <out_dir> <seed> <thread>
#
# Arguments:
#   <fq_prefix>   Path prefix of input
#   <ref_prefix>  Path prefix of output reference
#   <out_dir>     Path to an output directory
#   <seed>        Random seed
#   <thread>      Number of threads

set -uex

IN_FQ_PREFIX="${1}"
IN_REF_PREFIX="${2}"
OUT_MAP_DIR="${3}"
SEED="${4}"
THREAD="${5}"
FQ_NAME=$(basename "${IN_FQ_PREFIX}")
OUT_MAP_PREFIX="${OUT_MAP_DIR}/${FQ_NAME}.rsem.star"
FQ1_GZ="${IN_FQ_PREFIX}_1.fastq.gz"
FQ2_GZ="${IN_FQ_PREFIX}_2.fastq.gz"

[[ -f "${FQ1_GZ}" ]]
[[ -f "${FQ2_GZ}" ]]

rsem-calculate-expression \
  --star \
  --star-gzipped-read-file \
  --seed "${SEED}" \
  --num-threads "${THREAD}" \
  --estimate-rspd \
  --calc-ci \
  --paired-end \
  "${FQ1_GZ}" \
  "${FQ2_GZ}" \
  "${IN_REF_PREFIX}" \
  "${OUT_MAP_PREFIX}"
