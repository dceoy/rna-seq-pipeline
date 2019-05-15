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
FQ1_GZ="${IN_FQ_PREFIX}.R1.fastq.gz"
FQ2_GZ="${IN_FQ_PREFIX}.R2.fastq.gz"
TMP_FQ1="${OUT_FQ_PREFIX}.tmp.R1.fastq"
TMP_FQ2="${OUT_FQ_PREFIX}.tmp.R2.fastq"

[[ -f "${FQ1_GZ}" ]]
[[ -f "${FQ2_GZ}" ]]

for p in ${OUT_FQ_DIR} ${LOG_DIR}; do
  [[ -d "${p}" ]] || mkdir "${p}"
done

gzip -dc "${FQ1_GZ}" > "${TMP_FQ1}"
gzip -dc "${FQ2_GZ}" > "${TMP_FQ2}"

prinseq-lite.pl \
  -trim_tail_right 5 \
  -trim_qual_right 30 \
  -trim_qual_left 30 \
  -min_len 30 \
  -fastq "${TMP_FQ1}" \
  -fastq2 "${TMP_FQ2}"  \
  -out_good "${OUT_FQ_PREFIX}.prinseq_good" \
  -out_bad "${OUT_FQ_PREFIX}.prinseq_bad" \
  2>&1 | tee "${LOG_DIR}/prinseq.${FQ_NAME}.log.txt"

rm -f "${TMP_FQ1}" "${TMP_FQ2}"
find "${OUT_FQ_DIR}" -maxdepth 1 -type f \
  -name "${FQ_NAME}.prinseq_*.fastq" \
  -exec gzip {} \;
