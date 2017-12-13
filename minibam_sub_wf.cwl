#!/usr/bin/env cwl-runner
cwlVersion: v1.0

doc: |
    This is a subworkflow of the main oxog_varbam_annotat_wf workflow - this is not meant to be
    run as a stand-alone workflow!

requirements:
    - class: SchemaDefRequirement
      types:
          - $import: TumourType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: varbam_util.js }
    - class: SubworkflowFeatureRequirement

class: Workflow
outputs:
    minibam:
        outputSource: sub_run_var_bam/minibam
        type: File
    minibamIndex:
        outputSource: sub_run_var_bam/minibamIndex
        type: File


inputs:
    inputFileDirectory:
        type: Directory
    tumour:
        type: "TumourType.yaml#TumourType"
    indel-padding:
        type: string
    snv-padding:
        type: string
    sv-padding:
        type: string
    input-indel:
        type: File
    input-snv:
        type: File
    input-sv:
        type: File

steps:
    sub_run_var_bam:
        run: Variantbam-for-dockstore/variantbam.cwl
        in:
            input-bam:
                source: [inputFileDirectory, tumour]
                valueFrom: |
                    ${
                        return { "class":"File", "location": self[0].location + "/" + self[1].bamFileName }
                    }
            outfile:
                source: [tumour]
                valueFrom: $("mini-".concat(self.tumourId).concat(".bam"))
            snv-padding: snv-padding
            sv-padding: sv-padding
            indel-padding: indel-padding
            input-snv: input-snv
            input-sv: input-sv
            input-indel: input-indel
        out: [minibam, minibamIndex]
