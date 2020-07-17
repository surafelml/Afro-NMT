#!/bin/bash

#
# learn and apply subword segmentation, generate merged vocabulary 
#

EXPNAME=$1	# refers to the type of experiment (baseline, transfer-learning, semi-supervised) 
SPMSIZE=8000 	# 8000 1600 # 32000 for multilingual models
EXPDIR=$PWD
DATADIR=$EXPDIR/$EXPNAME/data
SRC='src'
TGT='tgt'

# see env-setup.sh for requirements 
ONMT=$EXPDIR/OpenNMT-tf/opennmt
GEN_VOCAB=$ONMT/bin/build_vocab.py
SPTED=$EXPDIR/scripts/spm-subword.py
SHARED_VOCAB=true

SPMDIR=$DATADIR/spmodel
SPDATA=$DATADIR/spdata


if [ -d $DATADIR ] && [ ! -d $SPMDIR ]; then
    mkdir $SPMDIR
    echo -e "\nLEARNING SP MODEL ..."

    python $SPTED --run "train" \
            --spm_dir $SPMDIR \
	    --in_file $DATADIR/train \
            --src $SRC --tgt $TGT \
            --spm_size $SPMSIZE
    wait $!
    echo "SP MODEL: [$SPMDIR]"
fi




if [ -d $SPMDIR ] && [ ! -d $SPDATA ]; then
    mkdir -p $SPDATA && cd $SPDATA
    

    for SET in train dev test; do
        echo -e "\nAPPLYING SP MODEL ON [$SET] ..."
        python $SPTED --run "encode" \
                    --spm_dir $SPMDIR \
                    --in_file $DATADIR/${SET} \
		    --src $SRC --tgt $TGT \
		    --op_file $SPDATA/${SET}  
     done 
     echo "SP DATA: [ $SPMDIR ]"


    # generate vocab using opennmt
    if [ -f train.$SRC ] && [ -f train.$TGT ]; then
       echo -e "\nGENERATING VOCABULARY ..."

       if $SHARED_VOCAB; then
         cat train.$SRC train.$TGT > train.${SRC}${TGT}
         python $GEN_VOCAB --save_vocab vocab train.${SRC}${TGT} # generate vocab without size limit
         rm -rf train.${SRC}${TGT}
       else
         python $GEN_VOCAB --size $VOCABSIZE --save_vocab vocab.$SRC train.$SRC
         python $GEN_VOCAB --size $VOCABSIZE --save_vocab vocab.$TGT train.$TGT
       fi
    fi
fi
