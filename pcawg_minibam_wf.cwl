#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: |
    This workflow will run OxoG, variantbam, and annotate.
    Run this as `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
    - class: SchemaDefRequirement
      types:
          - $import: PreprocessedFilesType.yaml
          - $import: TumourType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: varbam_util.js }
        # Shouldn't have to *explicitly* include these but there's
        # probably a bug somewhere that makes it necessary
        - { $include: preprocess_util.js }
        - { $include: vcf_merge_util.js }
    - class: SubworkflowFeatureRequirement

inputs:
    inputFileDirectory:
      type: Directory
    refFile:
      type: File
    out_dir:
      type: string
    normalBam:
      type: File
    snv-padding:
      type: string
    sv-padding:
      type: string
    indel-padding:
      type: string
    tumours:
      type:
        type: array
        items: "TumourType.yaml#TumourType"

outputs:
    minibams:
        type: File[]
        outputSource: gather_minibams/minibamsAndIndices
        secondaryFiles: "*.bai"

steps:
    ########################################
    # Preprocessing                        #
    ########################################
    #
    # Execute the preprocessor subworkflow.
    preprocess_vcfs:
      in:
        vcfdir: inputFileDirectory
        ref: refFile
        out_dir: out_dir
        filesToPreprocess:
            source: [ tumours ]
            valueFrom: |
                ${
                    // Put all VCFs into an array.
                    var VCFs = []
                    for (var i in self)
                    {
                        for (var j in self[i].associatedVcfs)
                        {
                            VCFs.push(self[i].associatedVcfs[j])
                        }
                    }
                    return VCFs;
                    //return self[0].associatedVcfs
                }
      run: preprocess_vcf.cwl
      out: [preprocessedFiles]

    get_merged_vcfs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                merged_vcfs: File[]
            expression: |
                $( { merged_vcfs:  inputs.in_record.mergedVcfs } )
        out: [merged_vcfs]

    filter_merged_snv:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_snv_vcf: File
            expression: |
                $({ merged_snv_vcf: filterFileArray("snv",inputs.in_vcfs) })
        out: [merged_snv_vcf]

    filter_merged_indel:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_indel_vcf: File
            expression: |
                $({ merged_indel_vcf: filterFileArray("indel",inputs.in_vcfs) })
        out: [merged_indel_vcf]

    filter_merged_sv:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_sv_vcf: File
            expression: |
                $({ merged_sv_vcf: filterFileArray("sv",inputs.in_vcfs) })
        out: [merged_sv_vcf]

    ########################################
    # Do Variantbam                        #
    ########################################
    # This needs to be run for each tumour, using VCFs that are merged pipelines per tumour.
    run_variant_bam:
        in:
            tumour:
                source: tumours
            indel-padding: indel-padding
            snv-padding: snv-padding
            sv-padding: sv-padding
            input-snv: filter_merged_snv/merged_snv_vcf
            input-sv: filter_merged_sv/merged_sv_vcf
            input-indel: filter_merged_indel/merged_indel_vcf
            inputFileDirectory: inputFileDirectory
        out: [minibam, minibamIndex]
        scatter: [tumour]
        run: minibam_sub_wf.cwl

    # Create minibam for normal BAM. It would be nice to figure out how to get this into
    # the main run_variant_bam step that currently only does tumour BAMs.
    run_variant_bam_normal:
        in:
            indel-padding: indel-padding
            snv-padding: snv-padding
            sv-padding: sv-padding
            input-snv: filter_merged_snv/merged_snv_vcf
            input-sv: filter_merged_sv/merged_sv_vcf
            input-indel: filter_merged_indel/merged_indel_vcf
            inputFileDirectory: inputFileDirectory
            input-bam: normalBam
            outfile:
                source: normalBam
                valueFrom: $("mini-".concat(self.basename))
        run: Variantbam-for-dockstore/variantbam.cwl
        out: [minibam, minibamIndex]
          # secondaryFiles:
          #     - "*.bai"

    # Gather all minibams into a single output array.
    gather_minibams:
        in:
            tumour_minibams: run_variant_bam/minibam
            normal_minibam: run_variant_bam_normal/minibam
            tumour_minibam_indices: run_variant_bam/minibamIndex
            normal_minibam_index: run_variant_bam_normal/minibamIndex
        run:
            class: ExpressionTool
            inputs:
                tumour_minibams: File[]
                tumour_minibam_indices: File[]
                normal_minibam: File
                normal_minibam_index: File
            outputs:
                minibamsAndIndices: File[]
            expression: |
                $( { minibamsAndIndices: inputs.tumour_minibams.concat(inputs.normal_minibam).concat(inputs.normal_minibam_index).concat(inputs.tumour_minibam_indices) } )
        out: [minibamsAndIndices]
          # secondaryFiles:
          #     - "*.bai"
