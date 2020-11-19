#!/usr/bin/env bash

input="/projects1/pestis/lnba_paper_2020/rawdata/PE/maria_boston/data_cleaned_barcodes/"
output="/projects1/pestis/lnba_paper_2020/rawdata/PE/HiSeq"
#for f in $(find $input -name *truncated.prefixed.pair1); do
#name=$(echo $f | awk -F "/" '{print $(NF-1)"_trimmed.YP2.1"}')
#file=$(echo $f | awk -F "/" '{print $NF}' | sed 's/.pair1/_S0_L007_R1_001.fastq.pre.gz'/)
#mkdir $output/$name
#cat $f | fastx_trimmer -f 8 | fastx_trimmer -t 7 -m 30 | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" | sed 's/^@F_/@/g' | gzip > $output/$name/$file
#gzip $f
#zcat $output/$name/$file | grep '@K' | awk -F " " 'BEGIN{OFS="\t";} {print $1,"R1"}' > $output/$name/$file.reads_R1_def.txt
#echo "${file} done"
#done

#for f in $(find $input -name *truncated.prefixed.pair2); do
#name=$(echo $f | awk -F "/" '{print $(NF-1)"_trimmed.YP2.1"}')
#file=$(echo $f | awk -F "/" '{print $NF}' | sed 's/.pair2/_S0_L007_R2_001.fastq.pre.gz'/)
#mkdir $output/$name
#cat $f | fastx_trimmer -f 8 | fastx_trimmer -t 7 -m 30 | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" | sed 's/^@R_/@/g' | gzip > $output/$name/$file
#gzip $f
#zcat $output/$name/$file | grep '@K' | awk -F " " 'BEGIN{OFS="\t";} {print $1,"R2"}' > $output/$name/$file.reads_R2_def.txt
#echo "${file} done"
#done


#for f in $(find $output -name "XXX*" -type d); do
#cat $f/*reads_R*_def.txt | awk -F "\t" '{print $1}' | sort | uniq -c | grep '1 ' | awk -F " " '{print $NF}' >> $f/reads_to_remove.txt
#done

source activate bbmap
for f in $(find $output -name *_S0_L007_R1_001.fastq.pre.gz); do
name=$(echo $f | sed 's/.pre.gz/.gz/')
folder=$(echo $f | awk -F '/' 'BEGIN{OFS="/";} {$NF=""; print $0}')
filterbyname.sh in=$f names=$folder/reads_to_remove.txt out=$name ths
done

for f in $(find $output -name *_S0_L007_R2_001.fastq.pre.gz); do
folder=$(echo $f | awk -F '/' 'BEGIN{OFS="/";} {$NF=""; print $0}')
name=$(echo $f | sed 's/.pre.gz/.gz/')
filterbyname.sh in=$f names=$folder/reads_to_remove.txt out=$name ths
done

