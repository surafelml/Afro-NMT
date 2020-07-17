# Low Resource Neural Machine Ttranslation: A Benchmark For Five African Languages

---


This repo provides data and experimental details for the paper [LOW-RESOURCE NEURAL MACHINE TRANSLATION: A BENCHMARK FOR FIVE AFRICAN LANGUAGES
](https://arxiv.org/pdf/2003.14402.pdf).




Updates:
- [July 2020] Data and scripts are available (see ./data, ./scripts directories)
- [March, 2020] Data, scripts, pre-trained models will be available asap.


## Paper Summary / Approaches 
---
<!--Recent advents in Neural Machine Translation (NMT) have shown improvements
in low-resource language (LRL) translation tasks. In this work, we -->
*...benchmark
NMT between English and five African LRL pairs (Swahili, Amharic, Tigrigna,
Oromo, Somali [SATOS]). We collected the available resources on the SATOS
languages to evaluate the current state of NMT for LRLs. Our evaluation, comparing a baseline single language pair __supervised NMT__ model against __semi-supervised__ learning, __transfer-learning__, and __multilingual modeling__, shows significant performance
improvements both in the En → LRL and LRL → En directions.*
<!--In terms of averaged BLEU score, the multilingual approach shows the largest gains, up to +5
points, in six out of ten translation directions. To demonstrate the generalization
capability of each model, we also report results on multi-domain test sets. We
release the standardized experimental data and the test sets for future works addressing the challenges of NMT in under-resourced settings, in particular for the
SATOS languages.-->


Baseline Supervised NMT
- Benchmarks a single language pair NMT models between En and the SATOS languages.


Semi-Supervised NMT
- Utilizes back-translation that leverages monolingual data to improve the supervised models. 


Transfer-Learning NMT
- Utilizes dynamic transfer-learning approach from a parent multilingual model to initialize single language pair child models. 


Multilingual NMT
- Trains a multilingual model ( of 10 directions) aggregating data from all the pairs.


*Additional summaries on each of these approaches can be found in the [paper](https://arxiv.org/pdf/2003.14402.pdf). Further readings on [semi-supervised](https://arxiv.org/abs/1511.06709), [transfer-learning](https://arxiv.org/pdf/1811.01137.pdf), and [multilingual-nmt](https://www.aclweb.org/anthology/Q17-1024.pdf)*




## Data and Experimental Setup 
---

### Requirements

- [NMT Library OpenNMT-tf](https://github.com/OpenNMT/OpenNMT-tf/) 
- [Mosesdecoder](https://github.com/moses-smt/mosesdecoder)
- [SentenciePiece](https://github.com/google/sentencepiece)
- [WikiExtractor](https://github.com/attardi/wikiextractor)
- [Opus Corpus Tools](https://pypi.org/project/opustools-pkg/)


For installing requirements and initial setup, run: `./env-setup.sh`



## Data Preparation

- Monolingual Data (wikipedia articles)

`./scripts/get-monolingual-data.sh [lang-id]` 




- Parallel Data (Opus data of differen corpus)

`./scripts/get-opus-data.sh [src-lang-id] [tgt-lang-id] ['corpus-1 corpus-2 corpus-n']`


- For evaluation (out-of-domain), we use [Ted Talks](https://wit3.fbk.eu/mono.php?release=XML_releases&tinfo=cleanedhtml_ted) data:

`./scripts/get-ted-data.sh [src-lang-id] [tgt-lang-id]`



## Data Preprocessing

<!-- Note: the opus corpus provides a multi-domain data, that requires to apply a strcit filtering of overlapping segments across domains (to avoid potential overlapping between the train/dev/test splits). -->

Before getting the training data, a one time process is to *split* the collected data to the train, Dev, and Test portions: `./get-nonoverlap-split.sh`



__Build Training Data:__

`./scripts/build-training-data.sh ['src-tgt tgt-src src2-tgt tgt-src2'] [flag] [exp-dir]` 


*For instance, to train a bidirectional `am<>en` model with a language flag, build the data as:  
`./scripts/build-training-data.sh 'am-en en-am' flag 'experiments/am-en'`. If training only a single pair `src-tgt` model set `flag=false`. For model training using a specific domain data, update the script.* 



__Preprocess Data:__

`./script/preprocess.sh [exp-dir] `



## Model Training: 

`./train.sh [exp-dir] [exp-id] [gpu/device-id]` 


To train a multilingual model, simply change number of provided pairs in the Build Training Data step, followed by the same training steps as in the baseline. For furtherr details on training a transfer-learning model see [dynamic transfer-learning repo.](https://github.com/surafelml/tl-mnmt)




## Translate and Evaluation

`./translate.sh [exp-dir] [exp-id] [src-tgt tgt-src ...] [flag] [gpu/device-id]`


---


### Reference 
```bibtex
@article{lakew2020low,
  title={Low Resource Neural Machine Translation: A Benchmark for Five African Languages},
  author={Lakew, Surafel M and Negri, Matteo and Turchi, Marco},
  journal={arXiv preprint arXiv:2003.14402},
  year={2020}
}
```



### Note

- The monolingual data provided in this repo includes segments extracted from wikipedia. However, in the paper we also used monolingual data (specifically for Amharic, Oromo, Somali, and Tigrigna languages) from the [HaBiT](https://corpora.fi.muni.cz/habit/index.html) corpus. If you would like to access and include this data please refer [HaBiT](https://corpora.fi.muni.cz/habit/index.html), and make sure to cite their work.


- If you are working on one of the five languages or in general on low-resource languages, and if have a question, discussion, or looking for a collaboration dont hesitate to reach out. 
