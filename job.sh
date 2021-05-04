#!/bin/bash

# Exit on error
set -e

echo "### Begin of job"

ID=$1
echo "ID:" $ID

PROCESS=$2
echo "Process:" $PROCESS

FILE=$3
echo "File:" $FILE

if [[ ${FILE} == *"Run2012"* ]]; then
    CONFIG=configs/data_cfg.py
else
    CONFIG=configs/simulation_cfg.py
fi

echo "CMSSW config:" $CONFIG

OUTPUT_DIR=/path/to/output/dir
echo "Output directory:" $OUTPUT_DIR

echo "Hostname:" `hostname`

echo "How am I?" `id`

echo "Where am I?" `pwd`

echo "What is my system?" `uname -a`

echo "### Start working"

# Make output directory
mkdir -p ${OUTPUT_DIR}/${PROCESS}


# Setup CMSSW
echo "Setup CMSSW"
source /cvmfs/cms.cern.ch/cmsset_default.sh
scramv1 project CMSSW CMSSW_5_3_32 # cmsrel CMSSW_5_3_32
cd CMSSW_5_3_32
eval `scramv1 runtime -sh` # cmsenv

# Clone and build the repo
echo "Clone and build the repository"
mkdir - src/workspace
cd src/workspace
git clone git://github.com/stwunsch/AOD2NanoAODOutreachTool -b dockerjobs AOD2NanoAOD --depth 1
cd AOD2NanoAOD
scram build

# Copy config file
CONFIG_COPY=cfg_${ID}.py
cp $CONFIG $CONFIG_COPY

# Modify CMSSW config to run only a single file
sed -i -e "s,^files =,files = ['"${FILE}"'] #,g" $CONFIG_COPY
sed -i -e 's,^files.extend,#files.extend,g' $CONFIG_COPY

# Modify CMSSW config to read lumi mask from EOS
sed -i -e 's,data/Cert,'${CMSSW_BASE}'/src/workspace/AOD2NanoAOD/data/Cert,g' $CONFIG_COPY

# Modify config to write output directly to output file
sed -i -e 's,output.root,'${PROCESS}_${ID}.root',g' $CONFIG_COPY

# Print config
cat $CONFIG_COPY

# Run CMSSW config
cmsRun $CONFIG_COPY

# Copy output file
# NOTE: If the path is a local path, it just copies the file
cp ${PROCESS}_${ID}.root ${OUTPUT_DIR}/${PROCESS}/${PROCESS}_${ID}.root
rm ${PROCESS}_${ID}.root

echo "### End of job"
