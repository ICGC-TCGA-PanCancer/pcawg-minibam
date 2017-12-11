# pcawg-minibam

The CWL workflow to generate minbiams _only_. For a workflow that runs PCAWG OxoG Filter, PCAWG Annotation, and generates Minibams, see this repository:  https://github.com/ICGC-TCGA-PanCancer/OxoG-Dockstore-Tools

This CWL workflow uses Variantbam to generate minibams. for more information on Variantbam, see: https://github.com/walaj/VariantBam/

The original SeqWare workflow can be found here: https://github.com/ICGC-TCGA-PanCancer/OxoGWrapperWorkflow
The Seqware workflow runs: the OxoG filter, produces mini-bams, and also runs Jonathan Dursi's PCAWG Annotator.

To visualize _this_ workflow, see here: https://view.commonwl.org/workflows/github.com/ICGC-TCGA-PanCancer/pcawg-minibam/blob/master/pcawg_minibam_wf.cwl
