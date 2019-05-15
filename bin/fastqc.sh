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

[[ -d "${OUT_QC_DIR}" ]] || mkdir "${OUT_QC_DIR}"

fastqc \
  --nogroup \
  --threads "${THREAD}" \
  --outdir "${OUT_QC_DIR}/${FQ_NAME}" \
  "${IN_FQ_PREFIX}_R1.fastq.gz" \
  "${IN_FQ_PREFIX}_R2.fastq.gz"
