#!/bin/bash

# 
# installs required libraries for data collection, preprocessing, model training and evaluation.
# for library specific requiremtns, see README of each repo
# For tensorflow installation and device (cpu/gpu) requirments see https://www.tensorflow.org/install/pip
#

EXPDIR=$PWD

# libraries
WIKI_EXT=https://github.com/attardi/wikiextractor.git
OPUS_PKG=opustools-pkg
MOSES=https://github.com/moses-smt/mosesdecoder.git
SENT_PIECE=sentencepiece
OPENNMT=https://github.com/OpenNMT/OpenNMT-tf.git


# Data
if [ ! -d $EXPDIR/wikiextractor ]; then
  echo "Cloning wikiextractor ..."
  git clone $WIKI_EXT
fi

echo "Installing OPUS packages ..."
pip install $OPUS_PKG


# Data processing
if [ ! -d $EXPDIR/$MOSES ]; 
  echo "Cloning Mosesdecoder ..."
  git clone $MOSES
fi

echo "Installing SentencePiece ..."
pip install $SENT_PIECE


# NMT Library: OPENNMT https://github.com/OpenNMT/OpenNMT-tf
if [ ! -d $EXPDIR/OpenNMT-tf ]
  echo "Cloning OpenNMT lastest version ..."
  git clone $OPENNMT
  cd $OPENNMT/
  pip install -e ./ 
fi

echo "-END-"
