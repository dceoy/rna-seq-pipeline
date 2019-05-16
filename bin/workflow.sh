#!/usr/bin/env bash
#
# RNA-seq analytical pipeline with PRINSEQ, STAR, and RSEM
#
# Usage:
#   workflow.sh --ref-gtf=<path> --ref-fna=<path> [--in-dir=<path>]
#               [--out-dir=<path>] [--qc] [--only-ref-prep] [--thread=<int>]
#   workflow.sh -h|--help
#
# Options:
#   --ref-gtf=<path>  Path to a reference GTF file
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
LOGGER_SH="${BIN_DIR}/logger.sh"
FASTQC_SH="${BIN_DIR}/fastqc.sh"
PRINSEQ_SH="${BIN_DIR}/prinseq.sh"
RSEM_REF_SH="${BIN_DIR}/rsem_ref.sh"
RSEM_TPM_SH="${BIN_DIR}/rsem_tpm.sh"

REF_GTF_GZ=''
REF_FNA_GZ=''
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
    '--ref-gtf' )
      REF_GTF_GZ=$(realpath "${2}") && shift 2
      ;;
    --ref-gtf=* )
      REF_GTF_GZ=$(realpath "${1#*\=}") && shift 1
      ;;
    '--ref-fna' )
      REF_FNA_GZ=$(realpath "${2}") && shift 2
      ;;
    --ref-fna=* )
      REF_FNA_GZ=$(realpath "${1#*\=}") && shift 1
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

[[ -z "${REF_GTF_GZ}" ]] && abort 'missing argument: --ref-gtf'
[[ -z "${REF_FNA_GZ}" ]] && abort 'missing argument: --ref-fna'

case "${OSTYPE}" in
  darwin* )
    THREAD=$(sysctl -n hw.ncpu)
    ;;
  linux* )
    THREAD=$(grep -ce '^processor\s\+:' /proc/cpuinfo)
    ;;
  * )
    :
    ;;
esac
OUT_LOG_DIR="${OUT_DIR}/log"
OUT_QC_DIR="${OUT_DIR}/qc"
OUT_FQ_DIR="${OUT_DIR}/fq"
OUT_REF_DIR="${OUT_DIR}/ref"
OUT_MAP_DIR="${OUT_DIR}/map"


[[ -d "${OUT_LOG_DIR}" ]] || mkdir "${OUT_LOG_DIR}"

# FASTQ preprocecing
if [[ ${ONLY_REF_PREP} -eq 0 ]]; then
  # Seaching of input samples
  FQ_PREFIXES=$(find_fq_prefixes "${IN_DIR}")
  [[ -z "${FQ_PREFIXES}" ]] && abort "FASTQ not found: ${IN_DIR}"
  echo ">>> Search for input samples:"
  echo "${FQ_PREFIXES}"

  # ReadQC checks
  if [[ ${QC} -ne 0 ]]; then
    [[ -d "${OUT_QC_DIR}" ]] || mkdir "${OUT_QC_DIR}"
    echo ">>> Execute QC checks with FastQC: ${IN_DIR} => ${OUT_QC_DIR}"
    for p in ${FQ_PREFIXES}; do
      fq_name=$(basename "${p}")
      ${LOGGER_SH} \
        "${OUT_LOG_DIR}/fastqc.${fq_name}.log.txt" \
        "${FASTQC_SH} ${p} ${OUT_QC_DIR} ${THREAD}"
    done
  fi

  # Read trimming and filtering
  [[ -d "${OUT_FQ_DIR}" ]] || mkdir "${OUT_FQ_DIR}"
  echo ">>> Trim reads with PRINSEQ: ${IN_DIR} => ${OUT_FQ_DIR}"
  TMP_QUEUE_PRINSEQ_SH="${OUT_FQ_DIR}/tmp.queue.prinseq.sh"
  echo -n > "${TMP_QUEUE_PRINSEQ_SH}"
  for p in ${FQ_PREFIXES}; do
    fq_name=$(basename "${p}")
    fq_log_txt="${OUT_LOG_DIR}/prinseq.${fq_name}.log.txt"
    echo "${LOGGER_SH} ${fq_log_txt} ${PRINSEQ_SH} ${p} ${OUT_FQ_DIR}" \
      >> "${TMP_QUEUE_PRINSEQ_SH}"
  done
  < "${TMP_QUEUE_PRINSEQ_SH}" xargs -L 1 -P "${THREAD}" -t bash
  rm -f "${TMP_QUEUE_PRINSEQ_SH}"
fi


# Reference preparation
REF_TAG=$(basename "${REF_FNA_GZ}" | sed -e 's/\.[a-z]\+\.gz$//')
OUT_REF_PREFIX="${OUT_REF_DIR}/rsem.star.${REF_TAG}"
if [[ -d "${OUT_REF_DIR}" ]]; then
  echo ">>> RSEM/STAR references exist: ${OUT_REF_PREFIX}"
else
  echo ">>> Prepare references with RSEM/STAR: ${OUT_REF_PREFIX}"
  mkdir "${OUT_REF_DIR}"
  ${LOGGER_SH} \
    "${OUT_LOG_DIR}/rsem.star.ref.${REF_TAG}.log.txt" \
    "${RSEM_REF_SH} ${REF_GTF_GZ} ${REF_FNA_GZ} ${OUT_REF_PREFIX} ${THREAD}"
fi
[[ ${ONLY_REF_PREP} -eq 0 ]] || exit


# Read mapping and TPM calculation
[[ -d "${OUT_MAP_DIR}" ]] || mkdir "${OUT_MAP_DIR}"
echo ">>> Mapping and TPM calculation with RSEM/STAR: ${OUT_FQ_DIR} => ${OUT_MAP_DIR}"
for p in ${FQ_PREFIXES}; do
  fq_name=$(basename "${p}")
  fq_prefix="${OUT_FQ_DIR}/${fq_name}.prinseq_good"
  ${LOGGER_SH} \
    "${OUT_LOG_DIR}/rsem.star.tpm.${fq_name}.log.txt" \
    "${RSEM_TPM_SH} ${fq_prefix} ${OUT_REF_PREFIX} ${OUT_MAP_DIR} ${THREAD}"
done
