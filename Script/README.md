# Quality Control Script
This repository contains a Quality Control (QC) script that was originally implemented as a sub-step within a larger workflow for Variant Calling, Variant Filtering, and Quality Control.

## Running the Script with Apptainer
To execute the script using an Apptainer image, use the following command structure:

To execute the script in the docker pulled as apptainer:

```bash
# Your Job Scheduling directives
my_input_vcf="/path/to/your_file.vcf.bgz"
output_directory="/path/to/output/directory"
prefixes="MyBatchPrefix"
apptainer_image="/path/to/apptainer/pulled/yr542/exome_pipelines_quality_control_qc"

#__________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

apptainer exec \
  --bind "$(dirname "$my_input_vcf")" \
  --bind "$output_directory" \
  "${apptainer_image}" QC \
  --input_vcf "${my_input_vcf}" \
  --output_directory "${output_directory}" \
  --vcf_prefix "${prefixes}" \
  --mem 8
```

* This script cannot be parallelized.
* This uses the docker from docker hub [yr542/exome_pipelines_quality_control_qc](https://hub.docker.com/r/yr542/exome_pipelines_quality_control_qc) which was pulled with apptainer.
