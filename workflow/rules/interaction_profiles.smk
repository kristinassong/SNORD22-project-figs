"""
rule flanking_exons:
    # Raw predictions should be used, not the merged file
    input:
        config['sno_interactions']
    output:
        "results/interaction_profiles/{sno}/flanking_exons/{sno}.prop.svg"
    params:
        gtf = 
    conda:
        "../envs/interactions.yaml"
    message:
        "Collapse all {wildcards.sno} binding interactions and plot interaction profiles inside the exons and in the 100 nts upstream and downstream exons."
    script:
        "../scripts/nts_flanking_exons.py"
"""

rule get_fasta:
    input:
        "resources/interactions_bed/{gene}.bed"
    output:
        "results/interaction_profiles/{gene}/motifs/{gene}.fa"
    params:
        genome_fasta = config['genome_fasta'],
        temp_bed = "results/interaction_profiles/{gene}/motifs/{gene}_temp.bed"
    conda:
        "../envs/bedtools.yaml"
    message:
        "Get sequences of {wildcards.gene} binding regions in FASTA format."
    shell:
        "awk '($3-$2) >= 6' {input} > {params.temp_bed} && "
        "bedtools getfasta -s -rna -fi {params.genome_fasta} -bed {params.temp_bed} -fo {output} && "
        "rm {params.temp_bed}"


rule motifs:
    input:
        rules.get_fasta.output
    output:
        "results/interaction_profiles/{gene}/motifs/meme.html"
    params:
        out_dir = "results/interaction_profiles/{gene}/motifs",
        virtualenv = config['virtualenv']
    message:
        "Obtain {wildcards.gene} binding motifs using MEME."
    shell:
        "source {params.virtualenv} && "
        "module load StdEnv/2020 && "
        "module load gcc/9.3.0 && "
        "module load openmpi/4.0.3 && "
        "module load meme/5.5.0 && "
        "meme {input} -rna -mod zoops -oc {params.out_dir} -minw 6 -evt 0.05 -time 14400 -nmotifs 5 -objfun classic -markov_order 0"