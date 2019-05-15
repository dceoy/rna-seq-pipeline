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

GTF="${1}"
FNA="${2}"
OUT_REF_PREFIX="${3}"
THREAD="${4}"
OUT_REF_DIR=$(dirname "${OUT_REF_PREFIX}")
OUT_REF_FNA="${OUT_REF_PREFIX}.fna"
OUT_REF_PA_FNA="${OUT_REF_PREFIX}.primary_assembly.fna"
OUT_REF_GTF="${OUT_REF_PREFIX}.gtf"

[[ -d "${OUT_REF_DIR}" ]] || mkdir "${OUT_REF_DIR}"
[[ -f "${OUT_REF_GTF}" ]] \
  || pigz -p "${THREAD}" -dc "${GTF}" > "${OUT_REF_GTF}"
[[ -f "${OUT_REF_FNA}" ]] \
  || pigz -p "${THREAD}" -dc "${FNA}" > "${OUT_REF_FNA}"
[[ -f "${OUT_REF_FNA}" ]] \
  || rsem-refseq-extract-primary-assembly "${OUT_REF_FNA}" "${OUT_REF_PA_FNA}"

rsem-prepare-reference \
  --star \
  --num-threads "${THREAD}" \
  --gtf "${OUT_REF_GTF}" \
  "${OUT_REF_PA_FNA}" \
  "${OUT_REF_PREFIX}"
