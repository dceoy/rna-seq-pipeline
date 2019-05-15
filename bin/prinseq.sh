#!/usr/bin/env bash
#
# Usage:
#   prinseq.sh <fq_prefix> <out_good> <out_bad>
#
# Arguments:
#   <fq_prefix>   Path prefix of input FASTQ (gzipped)
#   <out_good>    Path prefix of output good FASTQ
#   <out_bad>     Path prefix of output bad FASTQ

set -uex

IN_FQ_PREFIX="${1}"
OUT_FQ_DIR="${2}"
FQ_NAME=$(basename "${IN_FQ_PREFIX}")
OUT_FQ_PREFIX="${OUT_FQ_DIR}/${FQ_NAME}"
LOG_DIR="${OUT_FQ_DIR}/../log"
LOG_TXT="${LOG_DIR}/prinseq.${FQ_NAME}.log.txt"

[[ -d "${OUT_FQ_DIR}" ]] || mkdir "${OUT_FQ_DIR}"
[[ -d "${LOG_DIR}" ]] || mkdir "${LOG_DIR}"

prinseq-lite.pl \
  -trim_tail_right 5 \
  -trim_qual_right 30 \
  -trim_qual_left 30 \
  -min_len 30 \
  -fastq <(gzip -dc "${IN_FQ_PREFIX}_R1.fastq.gz") \
  -fastq2 <(gzip -dc "${IN_FQ_PREFIX}_R2.fastq.gz")  \
  -out_good "${OUT_FQ_PREFIX}.prinseq_good" \
  -out_bad "${OUT_FQ_PREFIX}.prinseq_bad" \
  2>&1 | tee "${LOG_TXT}"

gzip "${OUT_FQ_PREFIX}".prinseq_*.fastq
