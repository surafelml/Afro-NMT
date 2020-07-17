#!/bin/bash


#
# preprocess, translate ed evalaute domain specific test sets
#

EXPDIR=$PWD	
EXPATH=$1 	# ./experiments/am-en
EXPID=$2	# baseline/semi-supervised/transfer-learning/..
PAIRS=$3	# inference direction/s (am-en en-am) based on model type
LANGFLAG=$4	#
DEVICES=$5 	# -1 for cpu
export CUDA_VISIBLE_DEVICES=$DEVICES


LANGS='am om en so sw ti'
DOMAINS='bible-uedin jw300 Tanzil' 	# available domains vary based on each pair
SPLITS='test'				# 'dev test'

ONMT=$EXPDIR/OpenNMT-tf/opennmt
RUNDIR=$EXPDIR/$EXPATH/$EXPID 		# dir to run exp 
CONFIG=$EXPDIR/config.yml
MODEL_DEF=$EXPDIR/model_def.py

DATADIR=$EXPATH/data
SPMDIR=$DATADIR/spmodel
SPDATA=$DATADIR/spdata
EVALDATA=$DATADIR/test-sets 		# domain specific raw dev/test-sets data 

EVALDIR=$RUNDIR/evaluation
LOG=$EVALDIR/bleu.log
MODEL=$RUNDIR/model			# takes the latest checkpoint 
#CKPT=`head -1 $EXPDIR/model${ITER}/model/checkpoint | grep -o '[0-9][0-9]*'`
#MODEL=$EXPDIR/model/model.ckpt-610000


#SCRIPTS FOR PRE-POST-PROCESSING
MOSES=$EXPDIR/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
TOK=$MOSES/tokenizer/tokenizer.perl
DETOK=$MOSES/tokenizer/detokenizer.perl
DEESC=$MOSES/tokenizer/deescape-special-chars.perl
CLN=$MOSES/training/clean-corpus-n.perl 
MULTIBLUE=$MOSES/generic/multi-bleu.perl
MULTIBLUEDETOK=$MOSES/generic/multi-bleu-detok.perl
SPTED=$EXPDIR/scripts/spm-subword.py


for SRC in $LANGS; do
  for TGT in $LANGS; do	
    if [[ $PAIRS =~ $SRC-$TGT ]] && [[ $SRC != $TGT ]]; then

      for DOMAIN in $DOMAINS; do
        echo -e "\nTRANSLATING: [$SRC > $TGT] FOR DOMAIN [$DOMAIN] ..."
          DATA=$EVALDATA/$DOMAIN

          for SET in $SPLITS; do

	    #INPUT-OUTPUT-REFERENCE
	    RAW_FILE_SRC=$DATA/${SET}.$SRC
	    RAW_FILE_TGT=$DATA/${SET}.$TGT

	    IN_FILE=$EVALDIR/${SET}.${DOMAIN}.${SRC}
	    HYP_FILE=$EVALDIR/${SET}.${DOMAIN}.${SRC}-${TGT}.${TGT}
	    REF_FILE=$EVALDIR/${SET}.${DOMAIN}.${TGT}
	    mkdir -p $EVALDIR


            if [ -n "LANGFLAG" ]; then  # for lang-id based models 
              wc -l $RAW_FILE_SRC
	      $NORM < $RAW_FILE_SRC | $DEESC | $DETOK -l $SRC -q | awk -vtgt_tag="<2${TGT}>" '{ print tgt_tag" "$0 }' > $IN_FILE
              wc -l $IN_FILE
	    else
	      $NORM < $RAW_FILE_SRC | $DEESC | $DETOK -l $SRC -q > $IN_FILE  
	    fi
	    $NORM < $RAW_FILE_TGT | $DEESC | $DETOK -l $TGT -q > $REF_FILE  


	     if [ ! -f $HYP_FILE ] && [ -f $IN_FILE ]; then
               echo -e "\nAPPLYING SP MODEL ON [ $IN_FILE ] ..."
	       mv $IN_FILE ${IN_FILE}.src
               python $SPTED --run "encode" \
                    --spm_dir $SPMDIR \
                    --in_file ${IN_FILE} \
		    --src src \
		    --op_file ${IN_FILE}.sp
	       mv ${IN_FILE}.sp.src ${IN_FILE}
	       rm -rf ${IN_FILE}.src 



		echo "INFERENCE USING MODEL: $MODEL" # & CHECKPOINT: $CKPT"
		python $ONMT/bin/main.py --model $MODEL_DEF \
					--data_dir $SPDATA \
					--checkpoint_path $MODEL \
					--config $CONFIG --auto_config infer \
					--features_file $IN_FILE \
					--predictions_file $HYP_FILE \

		wait $!	

	
		#DECODE & COMPUTE BLEU
		echo "SP DECODING: [ $HYP_FILE ]"		
	        mv $HYP_FILE ${HYP_FILE}.tgt
                python $SPTED --run "decode" \
                    --spm_dir $SPMDIR \
                    --in_file ${HYP_FILE} \
		    --tgt tgt \
		    --op_file ${HYP_FILE}.op
	        mv ${HYP_FILE}.op.tgt ${HYP_FILE}
		rm -rf ${HYP_FILE}.tgt


		# POSTPROCESS FOR DETOKNIZED AND TOKENIZED BLEU
		#$TOK -l $TGT -q < $HYP_FILE > ${HYP_FILE}.tok
		#$TOK -l $SRC -q < $REF_FILE > ${REF_FILE}.tok
		# DETOK BLEU (en only)
		#$DETOK -l $TGT -q -penn < $HYP_FILE > ${HYP_FILE}.detok 
		#$DETOK -l $TGT -q -penn < ${REF_FILE} > ${REF_FILE_TOK}.detok 


		# BLEU 
		BLEU=`$MULTIBLUE ${REF_FILE} < ${HYP_FILE} | cut -f 3 -d ' ' | cut -f 1 -d ','`
		echo "DOMAIN: $DOMAIN | SET:$SET | DIR:$SRC>$TGT | BLEU=$BLEU" | tee -a $LOG

              else
                echo "Translated file exist: [ $HYP_FILE ] "; exit 1
              fi
        done
      done
    fi
  done
done
echo "EVALUATION LOG: [$LOG]"
