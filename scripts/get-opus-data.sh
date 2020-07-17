#!/bin/bash

#
# gets parallel data for SRC-TGT pair and CORPUS (e.g. bible, jw300, tanzil, etc)
# from Opus: http://opus.nlpl.eu
#


[ $# -ne 3 ] && { echo "'SRCs/' 'TGTs' 'CORPUs' language ids and Opus corpus name/s missing"; exit 1; }

# pip install opustools-pkg # see env-setup.sh
SRCS=$1     #"sw am ti om so"
TGTS=$2     #"en"
CORPUS=$3   #"Tanzil bible-uedin jw300"
EXPDIR=$PWD # ./afro-NMT/experiments
DATADIR=$EXPDIR/data/opus   #para


for SRC in $SRCS; do
    for TGT in $TGTS; do

         if [ $SRC != $TGT ]; then

            mkdir -p $DATADIR/$CORPUS/$SRC-$TGT  #/$CORPUS
            cd $DATADIR/$CORPUS/$SRC-$TGT   #/$CORPUS

              echo -e "Getting $CORPUS for [$SRC-$TGT] pair ...\n"
              yes | opus_read -d $CORPUS -s $SRC -t $TGT -wm moses -w $CORPUS.$SRC $CORPUS.$TGT
              rm -rf *xml*

              echo "Done downloading $CORPUS "
         fi
    done
done
