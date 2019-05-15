#!/usr/bin/env bash
#
# Usage:
#   download_ref.sh <out_dir>

set -uex

OUT_DIR="${1}"
BASE_URL='https://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/Homo_sapiens/all_assembly_versions/GCF_000001405.38_GRCh38.p12'
GENOMIC_GTF='GCF_000001405.38_GRCh38.p12_genomic.gtf.gz'
GENOMIC_FNA='GCF_000001405.38_GRCh38.p12_genomic.fna.gz'
MD5SUMS_TXT='md5checksums.txt'

cd "${OUT_DIR}"

for f in ${GENOMIC_GTF} ${GENOMIC_FNA} ${MD5SUMS_TXT}; do
  wget "${BASE_URL}/${f}"
done

PART_MD5SUMS_TXT='partial_md5checksums.txt'
cat \
  <(grep -e "${GENOMIC_GTF}\$" "${MD5SUMS_TXT}") \
  <(grep -e "${GENOMIC_FNA}\$" "${MD5SUMS_TXT}") \
  > "${PART_MD5SUMS_TXT}"
md5sum -c "${PART_MD5SUMS_TXT}"
