#!/usr/bin/env bash
#
# RNA-seq analytical pipeline with PRINSEQ, STAR, and RSEM
#
# Usage:
#   workflow.sh --ref-gff=<path> --ref-fna=<path> [--in-dir=<path>]
#               [--out-dir=<path>] [--qc] [--only-ref-prep] [--thread=<int>]
#   workflow.sh -h|--help
#
# Options:
#   --ref-gff=<path>  Path to a reference GFF file
#   --ref-fna=<path>  Path to a reference FASTA file
#   --in-dir=<path>   Path to input FASTQ directory [default: .]
#   --out-dir=<path>  Path to output directory [default: .]
#   --qc              Execute QC checks
#   --only-ref-prep   Prepare only references
#   --thread=<url>    Limit CPUs for multiprocessing
#   -h, --help        Print usage

set -ue

SCRIPT_PATH=$(realpath "${0}")
if [[ ${#} -ge 1 ]]; then
  for a in "${@}"; do
    [[ "${a}" = '--debug' ]] && set -x && break
  done
fi

SCRIPT_NAME=$(basename "${SCRIPT_PATH}")
SCRIPT_VERSION='v0.0.1'
BIN_DIR=$(dirname "${SCRIPT_PATH}")
PRINSEQ_SH="${BIN_DIR}/prinseq.sh"
FASTQC_SH="${BIN_DIR}/fastqc.sh"
RSEM_REF_SH="${BIN_DIR}/rsem_ref.sh"
RSEM_TPM_SH="${BIN_DIR}/rsem_tpm.sh"

REF_GFF=''
REF_FNA=''
IN_DIR="${PWD}"
OUT_DIR="${PWD}"
QC=0
ONLY_REF_PREP=0
THREAD=1

function print_version {
  echo "${SCRIPT_NAME}: ${SCRIPT_VERSION}"
}

function print_usage {
  sed -ne '1,2d; /^#/!q; s/^#$/# /; s/^# //p;' "${SCRIPT_PATH}"
}

function abort {
  {
    if [[ ${#} -eq 0 ]]; then
      cat -
    else
      SCRIPT_NAME=$(basename "${SCRIPT_PATH}")
      echo "${SCRIPT_NAME}: ${*}"
    fi
  } >&2
  exit 1
}

function find_fq_prefixes {
  find "${*}" -name '*.fastq.gz' \
    | sed -e 's/.R[12]\.fastq\.gz$//' \
    | sort \
    | uniq
}

while [[ ${#} -ge 1 ]]; do
  case "${1}" in
    '--debug' )
      shift 1
      ;;
    '--ref-gff' )
      REF_GFF=$(realpath "${2}") && shift 2
      ;;
    --ref-gff=* )
      REF_GFF=$(realpath "${1#*\=}") && shift 1
      ;;
    '--ref-fna' )
      REF_FNA=$(realpath "${2}") && shift 2
      ;;
    --ref-fna=* )
      REF_FNA=$(realpath "${1#*\=}") && shift 1
      ;;
    '--in-dir' )
      IN_DIR=$(realpath "${2}") && shift 2
      ;;
    --in-dir=* )
      IN_DIR=$(realpath "${1#*\=}") && shift 1
      ;;
    '--out-dir' )
      OUT_DIR=$(realpath "${2}") && shift 2
      ;;
    --out-dir=* )
      OUT_DIR=$(realpath "${1#*\=}") && shift 1
      ;;
    '--qc' )
      QC=1 && shift 1
      ;;
    '--only-ref-prep' )
      ONLY_REF_PREP=1 && shift 1
      ;;
    '--thread' )
      THREAD="${2}" && shift 2
      ;;
    --thread=* )
      THREAD="${1#*\=}" && shift 1
      ;;
    '-h' | '--help' )
      print_usage && exit 0
      ;;
    * )
      abort "invalid argument \`${1}\`"
      ;;
  esac
done

[[ -z "${REF_GFF}" ]] && abort 'missing argument: --ref-gff'
[[ -z "${REF_FNA}" ]] && abort 'missing argument: --ref-fna'

if [[ -z "${THREAD}" ]]; then
  case "${OSTYPE}" in
    darwin* )
      THREAD=$(sysctl -n hw.ncpu)
      ;;
    linux* )
      THREAD=$(grep -ce '^processor\s\+:' /proc/cpuinfo)
      ;;
    * )
      THREAD=1
      ;;
  esac
fi
OUT_QC_DIR="${OUT_DIR}/qc"
OUT_FQ_DIR="${OUT_DIR}/fq"
OUT_REF_DIR="${OUT_DIR}/ref"
OUT_MAP_DIR="${OUT_DIR}/map"

FNA_NAME=$(basename "${REF_FNA}" | sed -e 's/\.[a-z]\+\.gz$//')
OUT_REF_PREFIX="${OUT_REF_DIR}/${FNA_NAME}"
if [[ -d "${OUT_REF_DIR}" ]]; then
  echo ">>> STAR references exist: ${OUT_REF_PREFIX}"
else
  echo ">>> Prepare references using STAR and RSEM: ${OUT_REF_PREFIX}"
  ${RSEM_REF_SH} \
    "${REF_GFF}" "${REF_FNA}" "${OUT_REF_PREFIX}" "${THREAD}"
fi
[[ ${ONLY_REF_PREP} -eq 0 ]] || exit

FQ_PREFIXES=$(find_fq_prefixes "${IN_DIR}")
echo ">>> Input FASTQ samples:"
echo "${FQ_PREFIXES}"

if [[ ${QC} -ne 0 ]]; then
  echo ">>> Execute QC checks using FastQC: ${IN_DIR} => ${OUT_QC_DIR}"
  for p in ${FQ_PREFIXES}; do
    ${FASTQC_SH} "${p}" "${OUT_QC_DIR}" "${THREAD}"
  done
fi

if [[ -z "${FQ_PREFIXES}" ]]; then
  abort "FASTQ not found: ${IN_DIR}"
else
  echo ">>> Trim reads using PRINSEQ: ${IN_DIR} => ${OUT_FQ_DIR}"
  echo "${FQ_PREFIXES}" \
    | xargs -L 1 -P "${THREAD}" -t -i "${PRINSEQ_SH}" {} "${OUT_FQ_DIR}"
fi

for p in ${FQ_PREFIXES}; do
  fq_name=$(basename "${p}")
  good_fq_prefix="${OUT_FQ_DIR}/${fq_name}.prinseq_good"
  echo ">>> Calculate TPMs using STAR and RSEM: ${good_fq_prefix} => ${OUT_MAP_DIR}"
  ${RSEM_TPM_SH} \
    "${good_fq_prefix}" "${OUT_REF_PREFIX}" "${OUT_MAP_DIR}" "${THREAD}"
done
