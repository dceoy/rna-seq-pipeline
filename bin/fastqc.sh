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
FQ1_GZ="${IN_FQ_PREFIX}.R1.fastq.gz"
FQ2_GZ="${IN_FQ_PREFIX}.R2.fastq.gz"

[[ -f "${FQ1_GZ}" ]]
[[ -f "${FQ2_GZ}" ]]

fastqc \
  --nogroup \
  --threads "${THREAD}" \
  --outdir "${OUT_QC_DIR}" \
  "${FQ1_GZ}" \
  "${FQ2_GZ}"
