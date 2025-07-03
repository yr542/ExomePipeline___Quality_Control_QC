# Exome Pipeline: Quality Control (QC) Step

This step is optional in the exome pipeline. Quality Control (QC) is performed after the variant filtering step to ensure the integrity and reliability of the variant dataset before downstream analyses. 

## Overview Of Exome Pipeline:

The overall pipeline consists of multiple steps as outlined below:

| Step                     | Description                                                                                   |
|--------------------------|-----------------------------------------------------------------------------------------------|
| Step 0: Optional MNP Removal | Filter out Multi-Nucleotide Polymorphism (MNP) sites                                            |
| Step 1: PreProcessing        | Preprocessing steps including indexing GVCF files and building a sample map for variant calling |
| Step 2a: Variant Calling (VC)   | Import and merge GVCFs from multiple samples using GenomicsDBImport; perform joint genotyping on the GenomicsDB workspace (For Ensembl, use Step_2a___Part_1___Ensembl_GenomicsDBImport.sh script) |
| Step 2b: Variant Filtering (VF) | Filter variant calls and select a subset of variants from callset; merge all cohort VCF files into a single VCF file |
| Step 2c: **Quality Control (QC)** | Perform quality control on merged VCF file and generate quality control metrics              |
| Step 3: ANNOVAR             | Annotate variants with GnomAD4.0                                                             |
| Step 4: Mendelian Filtering | Perform Mendelian Filtering on variants                                                      |
| Step 5: Post Processing  | Perform post processing                                                                      |
| Step 6: Manual Checks                        | Conduct manual review and verification, typically performed by experts                                     |
| Step 7: Variant Identification Application   | Uses the [Variant Identification Application Version 2 (VIA V2)](https://github.com/yr542/Variant_Identification_Applicaton___VIA___V2/tree/main); for details, refer to the VIA V2 GitHub repository |

We are focusing on the Quality Control (QC) in this repository.

## Purpose
After performing variant filtering, **quality control (QC)** is essential to ensure the integrity of your data before proceeding to downstream analyses such as association testing or population structure inference. This script performs several key QC steps on a merged VCF file, including:

- Gender check  
- Sample relatedness and kinship analysis  
- Inbreeding estimation  
- IBD (Identity By Descent)  
- Heterozygosity assessment  

These steps help to identify and exclude problematic samples or artifacts that may confound results.

## Why Quality Control is Important After Variant Filtering

Even after filtering variants for quality (e.g., depth, genotype quality, missingness), **sample-level artifacts** and **study design mismatches** can persist. QC steps performed here address issues such as:

- Sample contamination or swaps  
- Cryptic relatedness (e.g., unreported familial relationships)  
- Gender discrepancies based on genotype vs metadata  
- Excess heterozygosity  
- Duplicate samples or unexpected relatedness (e.g., in GWAS)  

Performing sample-level QC is critical for **minimizing bias**, **controlling for confounders**, and **ensuring robustness** in downstream analyses like PCA, kinship estimation, and GWAS.


## Outputs

The script produces output VCFs and PLINK files containing:

| Description                   | File Extensions                              |
|------------------------------|----------------------------------------------|
| Pairwise relatedness analysis | `.C.2.relatedness2.relatedness2`, `.C.relatedness.relatedness`, `.relatedness2.relatedness2`, `.relatedness.relatedness` |
| Gender checks                | `2.C.sexcheck.sexcheck`, `sex.sexcheck`, `sex2.sexcheck`               |
| IBD (Identity By Descent) sharing coefficients | `.IBD.genome`                                |
| Heterozygosity per individual | `.HET.het`                                  |

-  Among others

All intermediate PLINK files and logs are stored in a `cache/` directory for organization.

## Notes

- Update `vcf_prefix`, `input_vcf` and `output_directory` to match your data.
- Update the `mem` as needed. 
- Requires a conda environment with `vcftools`, `plink`, and `htslib`.  

## Docker Image

The Apptainer image used in this workflow is publicly available on Docker Hub:  
[`yr542/exome_pipelines_quality_control_qc`](https://hub.docker.com/r/yr542/exome_pipelines_quality_control_qc)

The image is public and does not require authentication specific to this repository. However, users may need to be authenticated with Docker Hub depending on their system configuration or Docker Hub’s access policies.


## Acknowledgements

We gratefully acknowledge the contributions of:

- **[Isabelle Schrauwen](https://phoenixmed.arizona.edu/isabelle-schrauwen-phd)** – Principal Investigator of our lab, providing guidance and support.  
- **[Gao Wang](https://www.neurology.columbia.edu/profile/gao-wang-phd)** – Principal Investigator who originally developed and hosted the pipeline using [SoS](https://vatlab.github.io/sos-docs/) workflow, available in the [GitHub Bioworkflows Repository](https://github.com/cumc/bioworkflows).  
- **Hawa Nasiri** – Collaborator who contributed significantly to the development and adaptation of the in-house CUIMC version of the pipeline. Hawa also co-led the conversion of the pipeline to Bash and provided edits to the Quality Control components.  
- **Yasmin Rajendran** – Contributed to pipeline development and documentation; co-led the Bash conversion and led the development of the Nextflow Quality Control module, Docker setup, and repository.


