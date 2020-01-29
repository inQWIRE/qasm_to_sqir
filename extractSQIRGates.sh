#!/bin/bash

coqc -R ../SQIR Top SqirExtraction.v && rm -f .SqirExtraction.aux SqirExtraction.{glob,vo} SqirGates.mli && mv SqirGates.ml lib
