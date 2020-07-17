#!/bin/bash

#
# builds train, dev, test sets for [src-tgt x-y] from multiple domains
#

EXPDIR=$PWD
PAIRS=$1
LANGFLAG=$2
EXPNAME=$3

LANGS='am om en so sw ti'
DOMAINS='bible-uedin jw300 Tanzil' 	# available domains vary based on pair
SPLITS='train dev test'
DATADIR=$EXPDIR/data/para/opus		# contains parallel data split for each pair

MOSES=$PWD/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
TOK=$MOSES/tokenizer/tokenizer.perl
DETOK=$MOSES/tokenizer/detokenizer.perl
DEESC=$MOSES//tokenizer/deescape-special-chars.perl


if [ ! -d $EXPDIR/$EXPNAME ]; then
  mkdir -p $EXPDIR/$EXPNAME/data && cd $EXPDIR/$EXPNAME/data
  echo -e "\nAGGREGATING DATA FOR EXPERIMENT: [$EXPNAME]"

  for SRC in $LANGS; do
    for TGT in $LANGS; do
      if [[ $PAIRS =~ $SRC-$TGT ]] && [[ $SRC != $TGT ]]; then
        echo "PROCESSING PAIR (- norm - deescape - detoknize -): [$SRC-$TGT] ..."

        for DOMAIN in $DOMAINS; do
            if [ $SRC != 'en' ]; then  # domain data parth are set ./LRLANG-en
              DATA=$DATADIR/$DOMAIN/$SRC-$TGT/split
            else
              DATA=$DATADIR/$DOMAIN/$TGT-$SRC/split
            fi

            if [ -d $DATA ]; then 	# checks is a pair exists for a domain

              mkdir -p ./test-sets/$DOMAIN # to save domain and language specific test sets


             for SPLIT in $SPLITS; do
  	      echo "PROCESSING ed AGGREGATING DOMAIN [$DOMAIN] SPLIT [$SPLIT] ..."
              #merge train, dev src & tgt
              if [ -n "LANGFLAG" ]; then  # if tag with lang-flag
		$NORM < $DATA/$SPLIT.$SRC | $DEESC | $DETOK -l $SRC -q | awk -vtgt_tag="<2${TGT}>" '{ print tgt_tag" "$0 }' >> $SPLIT.src
                #cat $DATA/$SPLIT.$SRC | awk -vtgt_tag="<2${TGT}>" '{ print tgt_tag" "$0 }' >> $SPLIT.src #$SRC
              else
                $NORM < $DATA/$SPLIT.$SRC | $DEESC | $DETOK -l $SRC -q >> $SPLIT.src #$SRC
              fi
              $NORM < $DATA/$SPLIT.$TGT | $DEESC | $DETOK -l $SRC -q >> $SPLIT.tgt #$TGT


              # create dev & test sets for domain specific evaluation
              if [ $SPLIT = 'dev' ] || [ $SPLIT = 'test' ]; then
		if [ ! -f ./test-sets/$DOMAIN/$SPLIT.$SRC ]; then
                  $NORM < $DATA/$SPLIT.$SRC | $DEESC | $DETOK -l $SRC -q > ./test-sets/$DOMAIN/$SPLIT.$SRC
                fi

		if [ ! -f ./test-sets/$DOMAIN/$SPLIT.$TGT ]; then
                  $NORM < $DATA/$SPLIT.$TGT | $DEESC | $DETOK -l $SRC -q > ./test-sets/$DOMAIN/$SPLIT.$TGT
		fi
              fi
            done
          fi
        done


        # final check for overlp | i always feel like to do this to avoid after experiment consequences :-) lots of CO_2
        echo "OVERLAP B/N DEV/TEST WITH TRAIN FOR: [$SRC - $TGT]"
        for set in dev test; do
          awk -F'\t' 'NR==FNR{c[$1]++;next};c[$1] == 1' ./train.src ./$SPLIT.src | wc -l
        done

      #else
      #  echo "PAIR [$SRC-$TGT] IS NOT IN [$LANGS] OR $DATADIR/$DOMAIN/$SRC-$TGT DOES EXIST..."; exit 1 ;
      fi

    done
  done
  echo "END: ${EXPDIR}/${EXPNAME}/data"
else
  echo "EXPERIMENT DIR: [$EXPDIR/$EXPNAME] ALREADY EXISTS ..."; exit 1;
fi
