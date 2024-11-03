# Nextflow Pipeline for 16S Analysis

This repository contains a Nextflow pipeline for analyzing 16S rRNA sequencing data using QIIME2.

## Overview
The pipeline automates the following steps:
1. Importing paired-end FASTQ files.
2. Summarizing demultiplexed data.
3. Performing DADA2 denoising.
4. Summarizing the feature table and representative sequences.
5. Taxonomy classification using a pre-trained classifier.
6. Generating a taxa barplot.

## Requirements
- [Nextflow](https://www.nextflow.io/)
- QIIME2 container (`qiime2/qiime2:2024.5.0`)

## Input Files
- `casava_folder`: Directory with demultiplexed FASTQ files in Casava 1.8 format.
- `metadata.tsv`: Metadata file containing sample information.
- `classifier.qza`: Pre-trained QIIME2 classifier (e.g., SILVA 138-99).

## Parameters
- `trim_left_f` and `trim_left_r`: Positions to start trimming from the 5' end of forward and reverse reads.
- `trunc_len_f` and `trunc_len_r`: Positions to truncate forward and reverse reads.

## Running the Pipeline
To run the pipeline, execute the following command:

```bash
nextflow run main.nf \
  --casava_folder /path/to/casava_folder \
  --metadata /path/to/metadata.tsv \
  --classifier /path/to/classifier.qza \
  --trim_left_f 0 --trim_left_r 0 --trunc_len_f 0 --trunc_len_r 0
