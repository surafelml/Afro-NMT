#!/bin/bash

#
# script: extracts wikimedia articles/dump using WikiExtractor for [lang-id], followed by
# preprocesses (normalize, tokenize, deescapem, and split EOS).
#

[[ $# -eq 0  ]] && { echo "Language id missing "; exit 1; }

LCODE=$1    	# lang-id 'en'
EXPDIR=$PWD 	# ./afro-NMT/experiments


# check env-setup.sh for prerequists
WIKIEX=$EXPDIR/wikiextractor/WikiExtractor.py
MOSES=$EXPDIR/mosesdecoder/scripts
NORM=$MOSES/tokenizer/normalize-punctuation.perl
DESCAPE=$MOSES/tokenizer/deescape-special-chars.perl
TOK=$MOSES/tokenizer/tokenizer.perl
CLEAN=$MOSES/training/clean-corpus-n.perl
SPLIT=$MOSES/ems/support/split-sentences.perl

DATADIR=$EXPDIR/data/mono
mkdir -p $DATADIR/$LCODE
OUTPUT=$DATADIR/$LCODE/mono.$LCODE

WIKI_BIN=${LCODE}wiki-latest-pages-articles.xml.bz2
WIKI_DUMP=http://download.wikimedia.org/${LCODE}wiki/latest/$WIKI_BIN


# Extract wiki and preprocess
if [ ! -f $OUTPUT ]; then

    # download wiki dump
    echo "Extracting wikimedia for language: $LCODE "

    wget -q -c $WIKI_DUMP -P $DATADIR/$LCODE

    python $WIKIEX $DATADIR/$LCODE/$WIKI_BIN --processes 12 -q -o - \
        | sed "/^\s*\$/d" | grep -v "^<doc id=" | grep -v "</doc>\$" \
        | $NORM | $TOK $LCODE -q  | $DESCAPE > $OUTPUT


    # split on EOS marker
    if [[ "$LCODE" = "am" || "$LCODE" = "ti" ]]; then
      # if wiki is in Ge'ez script
      sed 's/\([።.!?]\) /\1\n/g' $OUTPUT >  $OUTPUT.split

    else
      # if wiki is in latin script
      perl $SPLIT -l $LCODE < $OUTPUT -q -b > $OUTPUT.split

    fi

    # deduplicate corpus
    awk '!a[$0]++' $OUTPUT.split > $OUTPUT.uniq

    rm -rf $OUTPUT $OUTPUT.split $DATADIR/$LCODE/$WIKI_BIN
    mv $OUTPUT.uniq $OUTPUT

fi
