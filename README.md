# MRI Processor Project
## Summary
The purpose of this project was to create an automated pipeline for the processing of MRI imaging files.

This pipeline is implemented through the `mri-processor.sh` script, which, once executed, continuously monitors a directory `/Users/radiology/Downloads/Shared/` using the [`fswatch` CLI command](https://emcrisostomo.github.io/fswatch/), using file creation events to trigger processing of the imageds via the [Freesurfer CLI tool suite](https://surfer.nmr.mgh.harvard.edu/).

This project was created over the course of a 10-week internship in the University of Pennsylvania School of Medicine Radiology Department.