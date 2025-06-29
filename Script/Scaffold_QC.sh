# Your choice of job scheduling directives

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Initialize Conda
## Source your conda environment if required

# Activate your environment
conda activate Quality_Control

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Path to your output directory
output_directory="/path/to/QC/output/directory/

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Global Parameters 

# Custom Prefix to for ouput gvcf
vcf_prefix="MyBatchPrefix"

# Input vcf that is the merged output vcf from Step_2aP
input_vcf="/path/to/input/vcf/"

# Set memory limit
mem="4"

#__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Get the current timestamp:
start_timestamp=$(date "+%Y-%m-%d %H:%M:%S")

# Print the timestamp to stdout:
echo -e "\n\n**Job Started At:** $start_timestamp\n"

#__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Create the output directory and any missing intermediate directories
if [ -d "${output_directory}" ]; then
    echo "Output directory exists: ${output_directory}"
else
    echo "Output directory not found: ${output_directory}"
    mkdir -p "${output_directory}"
fi

echo -e "\n\n*Output Directory:* ${output_directory}"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# Create the directory if it doesn't exist
mkdir -p "${output_directory}/vcf_qc"
if [ -d "${output_directory}/vcf_qc" ]; then
    echo "Output directory exists: ${output_directory}/vcf_qc"
else
    echo "Output directory not found: ${output_directory}/vcf_qc"
    mkdir -p "${output_directory}/vcf_qc"
fi

echo -e "\n\n*Output vcf_qc Directory:* ${output_directory}/vcf_qc"

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 1 VCF QC:* Relatedness"

echo -e "\n\nThe input VCF used for the gender and relatedness check is: $input_vcf"

# VCF QC for relatedness
vcftools --relatedness --gzvcf "$input_vcf" --out "${output_directory}/vcf_qc/$(basename "$input_vcf" .vcf.gz).relatedness"
vcftools --relatedness2 --gzvcf "$input_vcf" --out "${output_directory}/vcf_qc/$(basename "$input_vcf" .vcf.gz).relatedness2"

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 2 VCF QC:* Gender"


# QC VCF for sex check
output_prefix="${output_directory}/vcf_qc/$(basename ${input_vcf} .vcf.gz)"

# PLINK
plink --vcf "${input_vcf}" --double-id --make-bed --out "${output_prefix}" --allow-extra-chr
plink --bfile "${output_prefix}" --check-sex --out "${output_prefix}.sex" --allow-extra-chr
plink --bfile "${output_prefix}" --check-sex 0.35 0.65 --out "${output_prefix}.sex2" --allow-extra-chr

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 3 VCF QC:* IBD"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

input_bed="${output_prefix}.bed"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# Verify the bed file exists
if [[ ! -f "$input_bed" ]]; then
    echo "Error: Input bed file not found: $input_bed"
    exit 1
fi

# Print statements for debugging (optional)
echo "*Input bed file:* ${input_bed}"
echo "*Output prefix:* ${output_prefix}"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# IBD QC using PLINK
# Missing rate per SNP (MAF and HWE cut-off)
plink --bfile "${input_bed%.*}" --geno 0.1 --hwe 0.00001 --maf 0.05 --make-bed --out "${output_prefix}.C" --allow-extra-chr
# LD pruning with window size 100, step size 10, and r^2 threshold 0.5 (MAF < 0.05)
plink --bfile "${output_prefix}.C" --indep-pairwise 50 5 0.5 --make-bed --out "${output_prefix}.CP" --allow-extra-chr
# IBD sharing
plink --bfile "${output_prefix}.CP" --genome --make-bed --out "${output_prefix}.IBD" --allow-extra-chr
# Inbreeding and absence of heterozygosity (het)
plink --bfile "${output_prefix}.CP" --het --make-bed --out "${output_prefix}.HET" --allow-extra-chr
# Inbreeding coefficient (IBCs)
plink --bfile "${output_prefix}.CP" --ibc --make-bed --out "${output_prefix}.IBC" --allow-extra-chr
# Cleaned sex
plink --bfile "${output_prefix}.C" --check-sex 0.35 0.65 --out "${output_prefix}.SEX.2.C.sexcheck" --allow-extra-chr
# Cleaned relatedness
plink --bfile "${output_prefix}.C" --recode vcf --out "${output_prefix}.C.VCF" --allow-extra-chr

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 4 VCF QC:* Relatedness Check 2"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

cleaned_vcf="${output_prefix}.C.VCF.vcf" 

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

bgzip "${cleaned_vcf}" && tabix -p vcf "${cleaned_vcf}.gz"
vcftools --relatedness --gzvcf "${cleaned_vcf}.gz" --out "${output_prefix}.C.relatedness"
vcftools --relatedness2 --gzvcf "${cleaned_vcf}.gz" --out "${output_prefix}.C.2.relatedness2"

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 5 VCF QC:* Homozygosity"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# Define input path (basename, not .bed file)
input_basename="${output_prefix}"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# Verify the PLINK fileset exists
if [[ ! -f "${input_basename}.bed" ]] || [[ ! -f "${input_basename}.bim" ]] || [[ ! -f "${input_basename}.fam" ]]; then
    echo "Error: Required PLINK files not found with basename: ${input_basename}"
    echo "Expected files:"
    echo "  ${input_basename}.bed"
    echo "  ${input_basename}.bim" 
    echo "  ${input_basename}.fam"
    exit 1
fi

echo "Input PLINK fileset: ${input_basename}"
output_basename="${input_basename}.HOM"

# _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

# Run PLINK commands
plink --bfile "${input_basename}" --geno 0.1 --hwe 0.00001 --maf 0.01 --make-bed --out "${input_basename}.CH" --allow-extra-chr

if [[ $? -ne 0 ]]; then
    echo "Error: First PLINK command failed"
    exit 1
fi

plink --bfile "${input_basename}.CH" --homozyg --make-bed --out "${output_basename}" --allow-extra-chr

if [[ $? -ne 0 ]]; then
    echo "Error: Second PLINK command failed"  
    exit 1
fi

echo "Output files: ${output_basename}"

#____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

echo -e "\n\n*Part 6 Cleaning Up:* Removing unwanted files."

# Move unwanted files to a cache directory
mkdir -p "${output_directory}/vcf_qc/cache"

mv "${output_directory}/vcf_qc"/*.bed "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.bim "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.fam "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.log "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.nosex "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.in "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.out "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.gz "${output_directory}/vcf_qc/cache"
mv "${output_directory}/vcf_qc"/*.tbi "${output_directory}/vcf_qc/cache"

#__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

# Get the timestamp when the command completes:
end_timestamp=$(date "+%Y-%m-%d %H:%M:%S")

# Print the end timestamp to stdout:
echo -e "\n**Job Ended At:** $end_timestamp\n"

#__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
