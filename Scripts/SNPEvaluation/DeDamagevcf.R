#!/usr/bin/env Rscript

#Script to process vcf files to remove potential het calls due to damage
#the vcf files will then be used to evaluate the snps with snpEvaluation Tool
#libraries
library(argparser)
library(dplyr)
library(tidyverse)


parser <- argparser::arg_parser('DeDamagevcf.R allows to remove C -> T and G ->A genotyping calls that could be due to damage for further evaluation with SNP Evaluation (https://github.com/andreasKroepelin/SNP_Evaluation). IMPORTANT! Do not use the output .vcf for genotyping', 
                                name = 'DeDamagevcf.R')

parser <- argparser::add_argument(parser, 'input',
                                  type = 'character',
                                  nargs = 1,
                                  help = 'Path to table.tsv file containing: Sample_name Library_Prep AllVCF ForwardVCF ReverseVCF')
parser <- argparser::add_argument(parser, '--output',
                                  type = 'character',
                                  help = 'Specify path to output, default: current directory',
                                  default = "")
argv <- argparser::parse_args(parser)

##Functions

readVCF <- function(path) {
  gzvcf <- gzfile(path)
  vcf <- read.delim(gzvcf, comment.char = "#", header = F, col.names = c("#CHROM","POS","ID","REF","ALT","QUAL","FILTER","INFO","FORMAT","SAMPLE")) 
  return(vcf)  
}

writeVCF <- function(vcf, path, output) {
  output <- paste(output, gsub(".vcf.gz", "_forSNPEval.vcf.gz", basename(path)), sep = "/")
  print(output)
  write_tsv(vcf, output, col_names = F)
}

changeCtoT <- function(path,output){
  vcfForward <- readVCF(path) %>%
    mutate(SAMPLE = ifelse(REF == "C" & ALT =="T", "./.", as.character(SAMPLE))) %>%
    mutate(FORMAT = ifelse(REF == "C" & ALT == "T", "GT", as.character(FORMAT)))
  writeVCF(vcfForward, path, output)
}

changeGtoA <- function(path, output){
  vcfReverse <- readVCF(path) %>% 
    mutate(SAMPLE = ifelse(REF == "G" & ALT =="A", "./.", as.character(SAMPLE))) %>%
    mutate(FORMAT = ifelse(REF == "G" & ALT == "A", "GT", as.character(FORMAT)))
  writeVCF(vcfReverse, path, output)
}

changeCtoTandGtoA <- function(path, output){
  vcf <- readVCF(path) %>% 
    mutate(SAMPLE = ifelse(REF == "G" & ALT =="A", "./.", as.character(SAMPLE))) %>%
    mutate(FORMAT = ifelse(REF == "G" & ALT == "A", "GT", as.character(FORMAT))) %>%
    mutate(SAMPLE = ifelse(REF == "C" & ALT =="T", "./.", as.character(SAMPLE))) %>%
    mutate(FORMAT = ifelse(REF == "C" & ALT == "T", "GT", as.character(FORMAT)))
  writeVCF(vcf, path, output)
}

changeVCF <- function(pathTable, output){
  VCFtable <- read.delim(pathTable, header = F, col.names = c("Sample","libPrep","vcfAll", "vcfForward", "vcfReverse"))
  for (row in 1:nrow(VCFtable)) {
    Sample <- VCFtable[row, "Sample"]
    libPrep <- VCFtable[row, "libPrep"]
    vcfAll <- VCFtable[row, "vcfAll"]
    vcfForward <- VCFtable[row, "vcfForward"]
    vcfReverse <- VCFtable[row, "vcfReverse"]
#    return(c(Sample, libPrep, vcfAll, vcfForward, vcfReverse))
    if(libPrep == "sslib"){
      print(paste(Sample, "is sslib, forward and reverse mapping vcf will be treated differently", sep = " "))
      #C -> T in sslib is only observed in the forward mapping reads so we remove them
      changeCtoT(as.character(vcfForward), output)
      #G -> A in sslib is only observed in the reverse mapping reads so we remove them (they are a results of
      #reverse complement of the reads that contain C -> T)
      changeGtoA(as.character(vcfReverse), output)
     } else {
       print(paste(Sample, "is dslib, all potential damage calls will be removed", sep = " "))
      #nonUDG treated libraries have hets due to C ->T and G -> A that can be damage so we remove all of those
      changeCtoTandGtoA(as.character(vcfAll), output)
    }
  }
}
    
##END Functions

if(argv$output == "") {
  output <- getwd()
} else {
  output <- argv$output
}

changeVCF(argv$input, output)

print(paste("All samples have been treated, vcf files for further SNP evaluation can be found in:", output))
