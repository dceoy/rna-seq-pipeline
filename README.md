rna-seq-pipeline
================

RNA-seq analytical pipeline with RSEM, STAR, PRINSEQ, and FastQC

Dependencies:

- Docker
- Docker Compose

Docker image
------------

Pull the image from [Docker Hub](https://hub.docker.com/r/dceoy/rna-seq-pipeline/).

```sh
$ docker image pull dceoy/rna-seq-pipeline
```

Pipeline components
-------------------

- Command-line interface: `bin/workflow.sh`
- Text logger of STDOUT/STDERR: `bin/logger.sh`
- Read QC checks: `bin/fastqc.sh`
- Read Trimming and filtering: `bin/prinseq.sh`
- Mapping reference preparation:`bin/rsem_ref.sh`
- Read mapping and TPM calculation: `bin/rsem_tpm.sh`

Usage
-----

Example: Human RNA-seq

1.  Check out the repository.

    ```sh
    $ git clone https://github.com/dceoy/rna-seq-pipeline.git
    $ cd rna-seq-pipeline
    ```

2.  Download reference genome data in `input/ref`.

    ```sh
    $ mkdir -p input/ref
    $ ./misc/download_GRCh38.sh input/ref
    ```

    `misc/download_GRCh38.sh` requires `wget`.

3.  Put paired-end FASTQ data in `input/fq`.

    - File name format:
      - R1: `<sample_name>.R1.fastq.gz`
      - R2: `<sample_name>.R2.fastq.gz`

    ```sh
    $ mkdir input/fq
    $ cp /path/to/fastq/*.R[12].fastq.gz input/fq
    ```

4.  Execute the pipeline.

    ```sh
    $ mkdir output
    $ docker-compose up
    ```

    Execution using custom reference data:

    ```sh
    $ mkdir output
    $ docker-compose run --rm rna-seq-pipeline \
        --qc \
        --ref-gtf=/path/to/<ref>.gtf.gz \
        --ref-fna=/path/to/<ref>.fna.gz \
        --in-dir=input/fq \
        --out-dir=output \
        --seed=0
    ```

    Run `docker-compose run --rm rna-seq-pipeline --help` for more details of options.
