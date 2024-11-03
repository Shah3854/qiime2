#!/usr/bin/env nextflow

// Define input paths and parameters for the workflow
params.casava_folder = "/home/vboxuser/Desktop/nextflow/fastq/casava-18-paired-end-demultiplexed"  
params.metadata = "/home/vboxuser/Desktop/nextflow/metadata.tsv" 
params.classifier = "/home/vboxuser/Desktop/nextflow/silva-138-99-nb-classifier.qza" 

params.trim_left_f = 0   
params.trim_left_r = 0   
params.trunc_len_f = 0 
params.trunc_len_r = 0 

process ImportCasavaFastq {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path casava_folder

    output:
    path "paired-end-demux.qza"

    script:
    """
    qiime tools import \
      --type 'SampleData[PairedEndSequencesWithQuality]' \
      --input-path ${casava_folder} \
      --input-format CasavaOneEightSingleLanePerSampleDirFmt \
      --output-path paired-end-demux.qza
    """
}

process SummarizeDemux {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path demux_qza

    output:
    path 'demux.qzv'

    script:
    """
    qiime demux summarize \
      --i-data ${demux_qza} \
      --o-visualization demux.qzv
    """
}

process Dada2Denoise {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path demux_qza

    output:
    path 'table.qza', emit: table
    path 'rep-seqs.qza', emit: rep_seqs
    path 'denoising-stats.qza', emit: stats

    script:
    """
    qiime dada2 denoise-paired \
      --i-demultiplexed-seqs ${demux_qza} \
      --p-trim-left-f ${params.trim_left_f} \
      --p-trim-left-r ${params.trim_left_r} \
      --p-trunc-len-f ${params.trunc_len_f} \
      --p-trunc-len-r ${params.trunc_len_r} \
      --o-table table.qza \
      --o-representative-sequences rep-seqs.qza \
      --o-denoising-stats denoising-stats.qza
    """
}

process SummarizeFeatureTable {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path table
    path metadata

    output:
    path 'table.qzv'

    script:
    """
    qiime feature-table summarize \
      --i-table ${table} \
      --o-visualization table.qzv \
      --m-sample-metadata-file ${metadata}
    """
}

process TabulateSequences {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path rep_seqs

    output:
    path 'rep-seqs.qzv'

    script:
    """
    qiime feature-table tabulate-seqs \
      --i-data ${rep_seqs} \
      --o-visualization rep-seqs.qzv
    """
}

process ClassifyTaxonomy {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path rep_seqs
    path classifier

    output:
    path 'taxonomy.qza'

    script:
    """
    qiime feature-classifier classify-sklearn \
      --i-classifier ${classifier} \
      --i-reads ${rep_seqs} \
      --o-classification taxonomy.qza
    """
}

process TabulateTaxonomy {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path taxonomy

    output:
    path 'taxonomy.qzv'

    script:
    """
    qiime metadata tabulate \
      --m-input-file ${taxonomy} \
      --o-visualization taxonomy.qzv
    """
}

process TaxaBarPlot {
    container 'qiime2/qiime2:2024.5.0'
    
    input:
    path table
    path taxonomy
    path metadata

    output:
    path 'taxa-bar-plots.qzv'

    script:
    """
    qiime taxa barplot \
      --i-table ${table} \
      --i-taxonomy ${taxonomy} \
      --m-metadata-file ${metadata} \
      --o-visualization taxa-bar-plots.qzv
    """
}

workflow {
    // Import and summarize
    demux = ImportCasavaFastq(params.casava_folder)
    SummarizeDemux(demux)

    // Denoise and get feature table
    dada2_results = Dada2Denoise(demux)
    
    // Summarize feature table
    SummarizeFeatureTable(dada2_results.table, params.metadata)
    
    // Process sequences
    TabulateSequences(dada2_results.rep_seqs)
    
    // Taxonomy classification
    taxonomy = ClassifyTaxonomy(dada2_results.rep_seqs, params.classifier)
    TabulateTaxonomy(taxonomy)
    
    // Create taxa barplot
    TaxaBarPlot(dada2_results.table, taxonomy, params.metadata)
}
