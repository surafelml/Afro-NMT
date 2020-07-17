#!/bin/bash

#
# For SRC/s - TGT/s pair, pick the pair with lowest num of segmets (base pair/om-en) & split it to Train/Dev/Test & filter uniq
# Loop over all other pairs and pick non-overlapping train set with Dev1 & Test1, and overlapping Dev and Test with Dev1 & Test1
# (Optional) take uniq of Train, Dev, Test sets
#

EXPDIR=$PWD
DATADIR=$EXPDIR/data/opus

MOSES=$EXPDIR/mosesdecoder
CLEAN=$MOSES/scripts/training/clean-corpus-n.perl


OPUS_DOMAINS='bible-uedin Tanzil jw300'
SRCS='am om en so sw ti'
TGT='en'

# used to extract dev-test for other pairs
BASE_SRC='om' 		#pair with smalest segments for selecting dev,test sets | or consider the first lang-id in SRCS as BASE_SRC
BASE_TGT='en'
DEVTEST_SIZE=5000   	# max size for dev & test split, assumes all data is > 50k, else reduce devtest_size


clean_fun(){
    CORPUS=$1
    SRC=$2
    TGT=$3
    RATIO=3 # to accomodate SRC-TGT with diff. scripts

    perl $CLEAN -ratio $RATIO $CORPUS $SRC $TGT $CORPUS.cln 1 500 #250
}



uniq_fun(){
    INPUT=$1

    awk '!a[$0]++' $INPUT > $INPUT.uniq
}


# in each domain, for each pair, split -
for DOMAIN in $OPUS_DOMAINS; do
    for SRC in $SRCS; do


            if [ $SRC != $TGT ]; then # && [ -d $DATA ]; then
              # raw src-tgt file
              ALL=$DATADIR/$DOMAIN/$SRC-$TGT/$DOMAIN
              SPLITDIR=$DATADIR/$DOMAIN/$SRC-$TGT/split


               # split for base pair
              if [ $BASE_SRC-$BASE_TGT = $SRC-$TGT ] && [ ! -d $SPLITDIR ] ; then
                  echo "PROCESSING SPLIT FOR PAIR: [${SRC}-${TGT}] DOMAIN: [$DOMAIN]"

                  mkdir -p $SPLITDIR
                  cd $SPLITDIR
                  cp $ALL.$SRC $ALL.$TGT ./

                  # clean with moses
                  clean_fun $DOMAIN $SRC $TGT
                  rm -rf $DOMAIN.$SRC $DOMAIN.$TGT
                  paste $DOMAIN.cln.$SRC $DOMAIN.cln.$TGT | shuf > $DOMAIN.${SRC}${TGT}
                  rm -rf $DOMAIN.cln.$SRC $DOMAIN.cln.$TGT

                   # ratio for splitting into train-dev-test sets
                   SAMPLES=`wc -l < $DOMAIN.${SRC}${TGT}`
                   echo "TOTAL [$DOMAIN] SAMPLES FOR SPLIT: $SAMPLES"

                   DEVTEST_SIZE=$DEVTEST_SIZE
                   for RATIO in $(seq 1 ${SAMPLES}); do
                       MOD=`echo $SAMPLES/$RATIO | bc`
                      if [[ $MOD -le $DEVTEST_SIZE ]]; then
                          echo "RATIO FOR DEV-TEST-TRAIN SPLIT: $RATIO"
                          break
                       fi
                   done


                   # split
                   awk "NR%$RATIO==1" $DOMAIN.${SRC}${TGT} > $DOMAIN.dev.${SRC}${TGT}
                   awk "NR%$RATIO==2" $DOMAIN.${SRC}${TGT} > $DOMAIN.test.${SRC}${TGT}
                   awk "NR%$RATIO!=1&&NR%$RATIO!=2" $DOMAIN.${SRC}${TGT} > $DOMAIN.train.${SRC}${TGT}
                   rm -rf $DOMAIN.${SRC}${TGT}

                   echo "DEV-TEST-TRAIN SPLIT SAMPLES: "
                   wc -l $DOMAIN.dev.${SRC}${TGT} $DOMAIN.test.${SRC}${TGT} $DOMAIN.train.${SRC}${TGT}


                   cat $DOMAIN.dev.${SRC}${TGT} $DOMAIN.test.${SRC}${TGT} > $DOMAIN.dev-test.${SRC}${TGT}
                   # first use tgt [$2], then src [$1] side to rmv overlap
                   awk -F'\t' 'NR==FNR{c[$2]++;next};c[$2] == 0' $DOMAIN.dev-test.${SRC}${TGT} $DOMAIN.train.${SRC}${TGT} \
                                                                    > $DOMAIN.train.tmp.${SRC}${TGT}
                   awk -F'\t' 'NR==FNR{c[$2]++;next};c[$1] == 0' $DOMAIN.dev-test.${SRC}${TGT} $DOMAIN.train.tmp.${SRC}${TGT} \
                                                                    > $DOMAIN.train.${SRC}${TGT}
                   rm -rf $DOMAIN.train.tmp.${SRC}${TGT} $DOMAIN.dev-test.${SRC}${TGT}

                   echo "TRAIN SET SAMPLES AFTER RMV OVERLAP WITH DEV-TEST: "
                   wc -l $DOMAIN.train.${SRC}${TGT}


                    for SET in dev test train; do
                        wc -l $DOMAIN.${SET}.${SRC}${TGT}
                        # get uniq segments
                        if [ $SET = 'dev' ] || [ $SET = 'test' ]; then
                            uniq_fun $DOMAIN.${SET}.${SRC}${TGT}
                            #rm -rf $DOMAIN.${SET}.${SRC}${TGT}
                            mv $DOMAIN.${SET}.${SRC}${TGT}.uniq $DOMAIN.${SET}.${SRC}${TGT}
                        fi

                        cut -f1 $DOMAIN.${SET}.${SRC}${TGT} > ${SET}.$SRC
                        cut -f2 $DOMAIN.${SET}.${SRC}${TGT} > ${SET}.$TGT
                        rm -rf $DOMAIN.${SET}.${SRC}${TGT}
                    done
                    echo -e "DONE SPLITING FOR [$SRC-$TGT] \n`wc -l ./*`"




               else # if not base pair, split based on base pari dev-test sets

                 BASE_SPLITDIR=$DATADIR/$DOMAIN/$BASE_SRC-$BASE_TGT/split

                 if [ -d $BASE_SPLITDIR ]; then

                   echo -e "PROCESSING SPLIT FOR PAIR: [${SRC}-${TGT}] DOMAIN: [$DOMAIN]
                            USING [$BASE_SRC-$BASE_TGT] - $SET AS OVERLAPING SAMPLES ..."

                   mkdir -p $SPLITDIR
                   cd $SPLITDIR
                   cp $ALL.$SRC $ALL.$TGT ./

                   # clean and merge src-tgt
                   clean_fun $DOMAIN $SRC $TGT
                   rm -rf $DOMAIN.$SRC $DOMAIN.$TGT
                   paste $DOMAIN.cln.$SRC $DOMAIN.cln.$TGT | shuf > $DOMAIN.${SRC}${TGT}
                   rm -rf $DOMAIN.cln.$SRC $DOMAIN.cln.$TGT

                   SAMPLES=`wc -l < $DOMAIN.${SRC}${TGT}`
                   echo "TOTAL [$DOMAIN] SAMPLES FOR SPLIT: $SAMPLES"


                   for SET in dev test; do
                    paste $BASE_SPLITDIR/${SET}.$BASE_SRC $BASE_SPLITDIR/${SET}.${BASE_TGT} \
                                                                > ${SET}.${BASE_SRC}${BASE_TGT}

                    awk -F'\t' 'NR==FNR{c[$2]++;next};c[$2] == 1' ${SET}.${BASE_SRC}${BASE_TGT} $DOMAIN.${SRC}${TGT} \
                                                                > $DOMAIN.${SET}.${SRC}${TGT}

                    cat $DOMAIN.${SET}.${SRC}${TGT} >> $DOMAIN.dev-test.${SRC}${TGT}
                    rm -rf ${SET}.${BASE_SRC}${BASE_TGT}
                   done

                   # first use tgt [$2], then src [$1] side to rmv overlap
                   awk -F'\t' 'NR==FNR{c[$2]++;next};c[$2] == 0' $DOMAIN.dev-test.${SRC}${TGT} $DOMAIN.${SRC}${TGT} \
                                                                    > $DOMAIN.train.tmp.${SRC}${TGT}
                   rm -rf $DOMAIN.${SRC}${TGT}
                   awk -F'\t' 'NR==FNR{c[$2]++;next};c[$1] == 0' $DOMAIN.dev-test.${SRC}${TGT} $DOMAIN.train.tmp.${SRC}${TGT} \
                                                                    > $DOMAIN.train.${SRC}${TGT}
                    rm -rf $DOMAIN.train.tmp.${SRC}${TGT} $DOMAIN.dev-test.${SRC}${TGT}

                    echo "TRAIN SET SAMPLES AFTER RMV OVERLAP WITH DEV-TEST: "
                    wc -l $DOMAIN.train.${SRC}${TGT}



                    for SET in dev test train; do
                        # get uniq segments
                        if [ $SET = 'dev' ] || [ $SET = 'test' ]; then
                            uniq_fun $DOMAIN.${SET}.${SRC}${TGT}
                            mv $DOMAIN.${SET}.${SRC}${TGT}.uniq $DOMAIN.${SET}.${SRC}${TGT}
                        fi

                        cut -f1 $DOMAIN.${SET}.${SRC}${TGT} > ${SET}.$SRC
                        cut -f2 $DOMAIN.${SET}.${SRC}${TGT} > ${SET}.$TGT
                        rm -rf $DOMAIN.${SET}.${SRC}${TGT}
                    done
                    echo -e "DONE SPLITTING FOR [$SRC-$TGT] \n`wc -l ./*`"

                 else
                     echo "GENERATE SPLIT FOR [${BASE_SRC}-$BASE_TGT] TO CONTRINUE..."; exit 1;
                 fi
                fi

           fi
    done
done
