IndelCheck.sh processes bam files to obtain non-covered regions and genes affected by those. 
Usage:
```
bash IndelCheck.sh /path/to/bam/directory /path/to/output reference.bed gapSize genes.bed
```

It produces as output the following files:
- Missingregions_min500bp_${gap}.tsv: file containing missing regions, with regions separated by gapSize bp appart merged. It contains 5 columns with: Name of the Sample, start coordinate, end coordinate, size of the region, percent of the region covered
- Missinggenes.tsv: file containing the genes affected by deletions.

See Rnotebook, section indels to see a way to analyse this data.
