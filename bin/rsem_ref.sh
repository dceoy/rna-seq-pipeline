#!/usr/bin/env bash
#
# Usage:
#   rsem_ref.sh <gff> <fna> <ref_prefix> <thread>
#
# Arguments:
#   <gff>         Path to a reference GFF file
#   <fna>         Path to a reference FASTA file
#   <ref_prefix>  Path prefix of output reference
#   <thread>      Number of threads

set -uex

GFF="${1}"
FNA="${2}"
OUT_REF_PREFIX="${3}"
THREAD="${4}"
OUT_REF_DIR=$(dirname "${OUT_REF_PREFIX}")
OUT_REF_FNA="${OUT_REF_PREFIX}.fna"
OUT_REF_GFF="${OUT_REF_PREFIX}.gff"

mkdir "${OUT_REF_DIR}"
pigz -p "${THREAD}" -dc "${GFF}" > "${OUT_REF_GFF}"
pigz -p "${THREAD}" -dc "${FNA}" > "${OUT_REF_FNA}"

rsem-prepare-reference \
  --star \
  --num-threads "${THREAD}" \
  --gff3 "${OUT_REF_GFF}" \
  "${OUT_REF_FNA}" \
  "${OUT_REF_PREFIX}"
