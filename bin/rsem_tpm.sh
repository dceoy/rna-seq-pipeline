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

mkdir "${OUT_MAP_DIR}"

rsem-calculate-expression \
  --star \
  --gzipped-read-file \
  --num-threads "${THREAD}" \
  --estimate-rspd \
  --calc-ci \
  --paired-end \
  "${IN_FQ_PREFIX}_R1.fastq.gz" \
  "${IN_FQ_PREFIX}_R2.fastq.gz" \
  "${OUT_REF_PREFIX}" \
  "${OUT_MAP_PREFIX}"
