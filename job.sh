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

# NOTE: Start the OUTPUT_DIR path with root:// to copy via XRootD
# NOTE: If the output directory is local, it should be mounted in the docker container.
OUTPUT_DIR=/path/to/output/dir
echo "Output directory:" $OUTPUT_DIR

CMSSW_BASE=/home/cmsusr/CMSSW_5_3_32/src
echo "CMSSW base:" $CMSSW_BASE

if [[ ${FILE} == *"Run2012"* ]]; then
    CONFIG=${CMSSW_BASE}/src/workspace/AOD2NanoAOD/configs/data_cfg.py
else
    CONFIG=${CMSSW_BASE}/src/workspace/AOD2NanoAOD/configs/simulation_cfg.py
fi
echo "CMSSW config:" $CONFIG

echo "Hostname:" `hostname`

echo "How am I?" `id`

echo "Where am I?" `pwd`

echo "What is my system?" `uname -a`

echo "### Start working"

# Make output directory
mkdir -p ${OUTPUT_DIR}/${PROCESS}

# Setup CMSSW
THIS_DIR=$PWD
cd $CMSSW_BASE
source /cvmfs/cms.cern.ch/cmsset_default.sh
eval `scramv1 runtime -sh`
cd $THIS_DIR

# Copy config file
mkdir -p configs/
CONFIG_COPY=configs/cfg_${ID}.py
cp $CONFIG $CONFIG_COPY

# Modify CMSSW config to run only a single file
sed -i -e "s,^files =,files = ['"${FILE}"'] #,g" $CONFIG_COPY
sed -i -e 's,^files.extend,#files.extend,g' $CONFIG_COPY

# Modify CMSSW config to read lumi mask from EOS
sed -i -e 's,data/Cert,'${CMSSW_BASE}'/src/workspace/AOD2NanoAOD/data/Cert,g' $CONFIG_COPY

# Modify config to write output directly to output directory
sed -i -e 's,output.root,'${PROCESS}_${ID}.root',g' $CONFIG_COPY

# Print config
cat $CONFIG_COPY

# Run CMSSW config
cmsRun $CONFIG_COPY

# Copy output file
xrdcp -f ${PROCESS}_${ID}.root ${OUTPUT_DIR}/${PROCESS}/${PROCESS}_${ID}.root
rm ${PROCESS}_${ID}.root

echo "### End of job"
