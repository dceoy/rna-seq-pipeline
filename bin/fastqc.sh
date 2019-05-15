#!/usr/bin/env bash
#
# Usage:
#   fastqc.sh <fq_prefix> <out_dir> <thread>
#
# Arguments:
#   <fq_prefix>   Path prefix of input FASTQ (gzipped)
#   <out_dir>     Path to an output directory
#   <thread>      Number of threads

set -uex

IN_FQ_PREFIX="${1}"
OUT_QC_DIR="${2}"
THREAD="${3}"
FQ_NAME=$(basename "${IN_FQ_PREFIX}")
LOG_DIR="${OUT_QC_DIR}/../log"
LOG_TXT="${LOG_DIR}/fastqc.${FQ_NAME}.log.txt"

[[ -d "${OUT_QC_DIR}" ]] || mkdir "${OUT_QC_DIR}"
[[ -d "${LOG_DIR}" ]] || mkdir "${LOG_DIR}"

fastqc \
  --nogroup \
  --threads "${THREAD}" \
  --outdir "${OUT_QC_DIR}/${FQ_NAME}" \
  "${IN_FQ_PREFIX}_R1.fastq.gz" \
  "${IN_FQ_PREFIX}_R2.fastq.gz" \
  2>&1 | tee "${LOG_TXT}"
