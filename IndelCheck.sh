#!/usr/bin/env bash

##Functions
#Function to merge windows that are less than the indicated number of bp in the gap
#$1=bg bed file generated by bedtools coverage
#$2=size in bp of gap of this size or less to merge windows
function mergingWindows {
bgFile=$1
bgNoMissing=$2
gapSpand=$3
name=$4
output=$(echo ${bgFile%.missing.*})
echo "Processing ${bgFile}"
counter=0
counterFile=0

cat ${bgFile} | awk 'BEGIN{FS=OFS="\t";} {print $1,$2,$3}' | awk -v gap=${gapSpand} 'BEGIN{FS=OFS="\t";} NR>1 {if ($2-e <= gap) print $1,s,$3; else print $0} {e=$3;s=$2}' > ${output}.tmp.${counter}.txt
awk 'NR==FNR{count [$2]++; if (count[$2] == 1) del[NR-1]; next} !(FNR in del)' ${output}.tmp.${counter}.txt ${output}.tmp.${counter}.txt | head -n -1 > ${output}_duplicates.txt
grep -v -f ${output}_duplicates.txt ${output}.tmp.${counter}.txt > ${output}.tmp.${counter}_rmdup.txt
mv ${output}.tmp.${counter}_rmdup.txt ${output}.tmp.${counter}.txt

initial=$(cat ${bgFile} | awk -F '\t' '{if ($3-$2 >= 500) print $0}' | wc -l )


lineNumber=$(cat ${output}.tmp.${counter}.txt | wc -l)

while [[ $lineNumber != $initial ]]; do
	initial=$(cat ${output}.tmp.${counter}.txt | wc -l)
	counterFile=$(($counterFile + 1))
	cat ${output}.tmp.${counter}.txt | awk 'BEGIN{FS=OFS="\t";} {print $1,$2,$3}' | awk -v gap=${gapSpand} 'BEGIN{FS=OFS="\t";} {if ($2-e <= gap) print $1,s,$3; else print $0} {e=$3;s=$2}' > ${output}.tmp.${counterFile}.txt
	awk 'NR==FNR{count [$2]++; if (count[$2] == 1) del[NR-1]; next} !(FNR in del)' ${output}.tmp.${counterFile}.txt ${output}.tmp.${counterFile}.txt | head -n -1 > ${output}_duplicates.txt
	grep -v -f ${output}_duplicates.txt ${output}.tmp.${counterFile}.txt > ${output}.tmp.${counterFile}_rmdup.txt
	mv ${output}.tmp.${counterFile}_rmdup.txt ${output}.tmp.${counterFile}.txt
	sleep 1
	lineNumber=$(cat ${output}.tmp.${counterFile}.txt | wc -l)
	counter=$((${counter} + 1))
	echo "Initial lines ${initial}= End lines ${lineNumber}"
done
sed 's$\t\t$\t0\t$' ${output}.tmp.${counterFile}.txt | bedtools coverage -a - -b ${bgNoMissing} -hist | awk '$4==1' | awk 'BEGIN{FS=OFS="\t";} {if ($(NF-1) >= 500) print $1,$2,$3,$(NF-1),$NF}' > ${output}.${gapSpand}.txt
sed 's$\t\t$\t0\t$' ${output}.tmp.${counterFile}.txt | bedtools coverage -a - -b ${bgNoMissing} -hist | awk '$4==0 && $7==1.0000000' | awk 'BEGIN{FS=OFS="\t";} {if ($(NF-1) >= 500) print $1,$2,$3,$(NF-1),"0.0000000"}' >> ${output}.${gapSpand}.txt
awk -v name=${name} 'BEGIN{FS=OFS="\t";} $1=name' ${output}.${gapSpand}.txt > ${output}.${gapSpand}.def.txt
rm ${output}_duplicates.txt ${output}.tmp.*
echo "${output}.${gapSpand}.def.txt generated"
}

##END functions


BAMFILES=($(find ${1} -name "*.bam"))
OUTPUT=${2}
chromosomeFile=${3}
gap=${4}
bedGenes=${5}
#bedGenes=/projects1/pestis/lnba_paper_2020/indels/Y_pestis_NC_003143_genes.bed

echo "Running command: IndelCheck.sh ${1} ${2} ${3} ${4} ${5}"

for bam in ${BAMFILES[@]}; do
name=$(echo ${bam##*/} | awk 'BEGIN{FS=OFS="_";} {print $1,$2}' | sed 's/.bam//')
echo ${name}
file=${OUTPUT}/${name}.missing.genes.bed.gz
if [[ ! -e $file ]]; then
#Histogram per base
#bedtools genomecov -d -ibam ${bam} | awk -v name=${name} '$1=name' > ${OUTPUT}/${name}.histogramperbase.bed
#Regions covered -bg option:
bedtools genomecov -bg -ibam ${bam} > ${OUTPUT}/${name}.bg.bed
#Regions missing
chromosomeName=$(awk '{print $1}' ${chromosomeFile} | uniq)
awk -v name=${chromosomeName} 'BEGIN{FS=OFS="\t";} $1=name' ${OUTPUT}/${name}.bg.bed | bedtools genomecov -bga -i - -g ${chromosomeFile} | grep -w 0$ | awk 'BEGIN{FS=OFS="\t";} {print $0,($3-$2)}' > ${OUTPUT}/${name}.missing.bed
mergingWindows ${OUTPUT}/${name}.missing.bed ${OUTPUT}/${name}.bg.bed ${gap} ${name}
#Retrieve genes in the missing regions
chromosomeName=$(awk '{print $1}' ${bedGenes} | uniq)
awk -v name=${chromosomeName} 'BEGIN{FS=OFS="\t";} $1=name' ${OUTPUT}/${name}.missing.bed | bedtools intersect -a $bedGenes -b - | awk 'BEGIN{FS=OFS="\t";} {print $0,($3-$2)}' | awk -v name=${name} 'BEGIN{FS=OFS="\t";} $1=name' > ${OUTPUT}/${name}.missing.genes.bed
gzip ${OUTPUT}/${name}*.bed
else
echo $file " exists!"
fi
done

cat ${OUTPUT}/*.${gap}.def.txt >> ${OUTPUT}/Missingregions_min500bp_${gap}.tsv
zcat ${OUTPUT}/*.missing.genes.bed.gz >> ${OUTPUT}/Missinggenes.tsv
