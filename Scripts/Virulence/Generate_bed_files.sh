#!/bin/bash
#SBATCH -c 1                      # number of CPUs (here 4)
#SBATCH --mem 4000                # memory pool for all cores (here 32GB)
#SBATCH -o slurm.%N.%j.out        # STDOUT (the standard output stream)
#SBATCH -e slurm.%N.%j.err        # STDERR (the output stream for errors)
#SBATCH -p short	#which partition to submit (short, medium, long)
#SBATCH -t 01:00:00                  # The maximum time the job is allowed to run, here 24 hours (the max allowed in the medium queue is 48h)
#SBATCH --mail-type=begin         # notifications for job to begin 
#SBATCH --mail-type=end           # notifications for job to end
#SBATCH --mail-type=fail          # notifications for job to abort
##SBATCH --mail-user=gneumann@shh.mpg.de # these notifications will be sent to your shh.mpg.de email-address. 
#SBATCH --array=0-15%7
#SBATCH -J "Virulence_BAMtoBed"






#$BAMDIR = directory BAMS
BAMDIR=$1
BAMFILES=($(find $BAMDIR -name *.bam))
BAM=${BAMFILES[$SLURM_ARRAY_TASK_ID]}

#$OUTDIR = output directory for final bed files
OUTDIR=$2
#$BED = Bed file containing coordinates for the genes. Choose from:  
BED=$3
#$GENE_NAMES = Path to bed file with genes name
GENE_NAMES=$4
NAME=$(echo $BAM | awk -F "/" '{print $NF}' | awk -F "." '{print $1"."$2"."$3}' | sed 's/_L001_R1_001//;s/.fastq//')
mkdir $OUTDIR/Final_bed_files


FILE=$OUTDIR/Final_bed_files/$NAME.virulence.sorted.filtered.final.bed
if [ ! -e $FILE ]; then
	echo "$FILE does not exists, processing it now"
	bedtools genomecov -ibam $BAM -bg > $OUTDIR/$NAME.histogram.bed
	bedtools coverage -a $BED -b $OUTDIR/$NAME.histogram.bed -hist | awk '$4==1' > $OUTDIR/$NAME.virulence_only1.bed
	bedtools coverage -a $BED -b $OUTDIR/$NAME.histogram.bed -hist | awk '$4==0' | awk '$7==1.0000000' > $OUTDIR/$NAME.virulence_only0.bed
	sed 's/\t1.0000000/\t0.0000000/g' $OUTDIR/$NAME.virulence_only0.bed > $OUTDIR/$NAME.virulence_only0_with0.bed
	cat $OUTDIR/$NAME.virulence_only1.bed $OUTDIR/$NAME.virulence_only0_with0.bed > $OUTDIR/$NAME.virulence.bed
	bedtools sort -i $OUTDIR/$NAME.virulence.bed > $OUTDIR/$NAME.virulence.sorted.bed
	awk '{print $1 "\t" $7}' $OUTDIR/$NAME.virulence.sorted.bed | awk '{$1="$NAME"; print ;}' | sed 's/\$NAME/'$NAME'/g' > $OUTDIR/$NAME.virulence.sorted.filtered.bed
	paste <(awk '{print $1 "\t" $2}' $OUTDIR/$NAME.virulence.sorted.filtered.bed ) <(awk -F "\t" '{print $4}' $GENE_NAMES ) > $OUTDIR/Final_bed_files/$NAME.virulence.sorted.filtered.final.bed
	rm $OUTDIR/$NAME.*.bed
else
	echo "$FILE exists!"
fi
