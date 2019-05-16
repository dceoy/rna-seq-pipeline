#!/usr/bin/env bash
#
# Usage:
#   rsem_ref.sh <gtf> <fna> <ref_prefix> <thread>
#
# Arguments:
#   <gtf>         Path to a reference GTF file (gzipped)
#   <fna>         Path to a reference FASTA file (gzipped)
#   <ref_prefix>  Path prefix of output reference
#   <thread>      Number of threads

set -uex

IN_REF_GTF_GZ="${1}"
IN_REF_FNA_GZ="${2}"
OUT_REF_PREFIX="${3}"
THREAD="${4}"
OUT_REF_DIR=$(dirname "${OUT_REF_PREFIX}")
REF_TAG=$(basename "${IN_REF_FNA_GZ}" | sed -e 's/\.[a-z]\+\.gz$//')
TMP_REF_GTF="${OUT_REF_DIR}/${REF_TAG}.gtf"
TMP_REF_FNA="${OUT_REF_DIR}/${REF_TAG}.fna"
REF_PA_FNA="${OUT_REF_DIR}/${REF_TAG}.primary_assembly.fna"

[[ -f "${IN_REF_GTF_GZ}" ]]
[[ -f "${IN_REF_FNA_GZ}" ]]

pigz -p "${THREAD}" -dc "${IN_REF_GTF_GZ}" > "${TMP_REF_GTF}"
pigz -p "${THREAD}" -dc "${IN_REF_FNA_GZ}" > "${TMP_REF_FNA}"

rsem-refseq-extract-primary-assembly \
  "${TMP_REF_FNA}" \
  "${REF_PA_FNA}"
rm -f "${TMP_REF_FNA}"

rsem-prepare-reference \
  --star \
  --num-threads "${THREAD}" \
  --gtf "${TMP_REF_GTF}" \
  "${REF_PA_FNA}" \
  "${OUT_REF_PREFIX}"

pigz -p "${THREAD}" "${REF_PA_FNA}"
rm -f "${TMP_REF_GTF}"
