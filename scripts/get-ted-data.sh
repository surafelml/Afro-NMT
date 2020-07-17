#!/bin/bash

#
# gets parallel data for SRC-TGT pair from ted-talks https://wit3.fbk.eu/
#

[ $# -ne 3 ] && { echo "'SRCs/' 'TGTs' 'CORPUs' language ids and Opus corpus name/s missing"; exit 1; }


SRCS=$1     	# "am om sw so ti"
TGTS=$2     	# "en"
CORPUS=ted
SPLIT="true"  	# if true creates a single file, else split as train/dev/test
EXPDIR=$PWD 	# ./experiments
DATADIR=$EXPDIR/data/ted


# Make sure to download TED_DATA .zip xml files of both SRC & TGT, and TED_DATA_TOOLS to $DATADIR
TED_DATA="https://wit3.fbk.eu/mono.php?release=XML_releases&tinfo=cleanedhtml_ted"
#assume zip xml files of ted talks from wit are downloded
XML=$DATADIR/ted-all-xml
mkdir -p $XML
# Similarly download preprocessing tools
TED_DATA_TOOLS="https://wit3.fbk.eu/tools.php?release=XML_releases"
SCRIPT=$DATADIR/tools_2016-01



for SRC in $SRCS; do
    for TGT in $TGTS; do

      if [ $SRC != $TGT ]; then
        mkdir -p $DATADIR/$SRC-$TGT/$CORPUS
        DSTDIR=$DATADIR/$SRC-$TGT/$CORPUS

        #extract
        cd $XML
        if [ ! -f ted_$SRC-20160408.zip ] && [ ! -f $XML/ted_$TGT-20160408.zip ]; then
            echo "missing xml files"; exit 1;

        else
            unzip ted_$SRC-20160408.zip && mv ted_$SRC-20160408.xml $DSTDIR/ted_$SRC.xml
            unzip ted_$TGT-20160408.zip && mv ted_$TGT-20160408.xml $DSTDIR/ted_$TGT.xml
            # rm -rf ted_$SRC-20160408.zip ted_$TGT-20160408.zip
        fi


        cd $DSTDIR

        # find set of common talks b/n SRC & TGT
        perl $SCRIPT/find-common-talks.pl --xml-file-l1 ted_$SRC.xml --xml-file-l2 ted_$TGT.xml > talkid_$SRC-$TGT.all

        if $SPLIT; then
            # split common talks to train/dev/test sets
            # head -10 talkid_$SRC-$TGT.all > talkid_$SRC-$TGT.test
            # tail -n +11 talkid_$SRC-$TGT.all > talkid_$SRC-$TGT.train
            echo "Optional ..."

        else
           #extract and take all talks for later splitting
           perl $SCRIPT/filter-talks.pl --talkids talkid_$SRC-$TGT.all --xml-file ted_$SRC.xml > ted_$SRC-$TGT.all.$SRC.xml
           perl $SCRIPT/filter-talks.pl --talkids talkid_$SRC-$TGT.all --xml-file ted_$TGT.xml > ted_$SRC-$TGT.all.$TGT.xml

            #extract parallell sentences
            perl $SCRIPT/ted-extract-par.pl \
            --xmlsource ted_$SRC-$TGT.all.$SRC.xml \
            --xmltarget ted_$SRC-$TGT.all.$TGT.xml \
            --outsource ted_$SRC-$TGT.all.$SRC \
            --outtarget ted_$SRC-$TGT.all.$TGT \
            --outdiscarded ted_$SRC-$TGT.all.$TGT.discarded \
            --filter 1.96 \
            #--tags #to keep metadata of talks
            rm -rf ted_$SRC-$TGT.all.$SRC.xml ted_$SRC-$TGT.all.$TGT.xml

            #rebuild sentences | .sent
            perl $SCRIPT/rebuild-sent.pl --file-l1 ted_$SRC-$TGT.all.$SRC --file-l2 ted_$SRC-$TGT.all.$TGT
            #rm -rf ted_$SRC-$TGT.all.$SRC ted_$SRC-$TGT.all.$TGT

            #cleaning
            cat ted_$SRC-$TGT.all.$SRC.sent | perl -pe 's/\([^\)]+\)//g' > ted_$SRC-$TGT.all.clean.$SRC
            cat ted_$SRC-$TGT.all.$TGT.sent | perl -pe 's/\([^\)]+\)//g' > ted_$SRC-$TGT.all.clean.$TGT
            rm -rf ted_$SRC-$TGT.all.$SRC.sent ted_$SRC-$TGT.all.$TGT.sent

            echo -e "\nDone..."
         fi
      fi

    done
done
