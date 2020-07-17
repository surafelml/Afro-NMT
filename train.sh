#!/bin/bash


EXPATH=$1 	# ./experiments/am-en
EXPID=$2	# baseline
DEVICES=$3 
EXPDIR=$PWD

export CUDA_VISIBLE_DEVICES=$DEVICES
#echo -e "\nExperiment running on GPU: $DEVICES"

ONMT=$EXPDIR/OpenNMT-tf/opennmt
RUNDIR=$EXPDIR/$EXPATH/$EXPID 	# dir to run exp 
CONFIG=$EXPDIR/config.yml
DATADIR=$EXPATH/data/spdata 	# preprocessed data 
LOG=$RUNDIR/log

MODEL_DEF=$EXPDIR/model_def.py
#MODEL_TYPE='TransformerShareEmbdAll' 

if [ ! -d $RUNDIR/model ]; then
  #python $opennmt/opennmt/bin/main.py train_and_eval --model_type $MODEL_TYPE --model "" \

  #touch $LOG  
  mkdir -p $RUNDIR
  echo -e "\nTRAINING LOG: [ $LOG ]"
  
  # onmt-main --config $CONFIG ... train --with_eval
 echo $CONFIG
  CUDA_VISIBLE_DEVICES=$DEVICES python $ONMT/bin/main.py --model $MODEL_DEF --run_dir $RUNDIR --seed 1234 \
						--data_dir $DATADIR \
						--config $CONFIG \
						--auto_config train --with_eval \
			 			--num_gpus 1 > $LOG 2> $LOG


						#--seed 1234 \

						#--auto_config train --with_eval \
						#--checkpoint_path model_ss_en-am_v1 \

else
  echo -e "\nModel exists: $RUNDIR/model "
fi

# Evaluation
