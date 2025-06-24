# ExomePipeline___Quality_Control_QC

# VCF Quality Control Pipeline (Post-Variant Filtering)

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

- `.relatedness` and `.relatedness2` – for pairwise relatedness analysis  
- `.sex` and `.sex2` – for **gender checks**  
- `.IBD.genome` – IBD sharing coefficients  
- `.HET.het` – **heterozygosity** per individual
-  Among others

All intermediate PLINK files and logs are stored in a `cache/` directory for organization.

## Notes

- Update `input_vcf`, `output_directory`, and `vcf_prefix` to match your data.  
- Requires a conda environment with `vcftools`, `plink`, and `htslib`.  
