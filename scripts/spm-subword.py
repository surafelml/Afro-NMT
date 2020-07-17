import sentencepiece as spm
import argparse
import os



def spm_train(train_file, spm_lang, vocab_size):
  spm.SentencePieceTrainer.Train('--input={} --model_prefix={} --vocab_size={} '
                                 '--hard_vocab_limit=false --shuffle_input_sentence=true '
                                 '--input_sentence_size=6000000'.format(train_file, spm_lang, vocab_size))

def train(spm_dir, in_file, src, tgt, spm_size):
  if not os.path.exists(spm_dir):
    os.mkdir(spm_dir)

  if src != "":
    spm_src = spm_dir+'/spm.{}'.format(src)
    file_src = in_file+'.{}'.format(src)
    spm_train(file_src, spm_src, spm_size)

  if tgt != "":
    spm_tgt = spm_dir+'/spm.{}'.format(tgt)
    file_tgt = in_file+'.{}'.format(tgt)
    spm_train(file_tgt, spm_tgt, spm_size)


def encode(spm_dir, in_file, lang, sp_file): 
  spm_spp = spm.SentencePieceProcessor()
  spm_prefix = spm_dir+'/spm.{}'.format(lang)

  spm_spp.Load(spm_prefix+".model")

  with open(in_file+'.{}'.format(lang), 'r') as infile, open(sp_file+'.{}'.format(lang), 'w') as outfile:
    for line in infile:
      print(' '.join(spm_spp.EncodeAsPieces(line.strip())), file=outfile)


def decode(spm_dir, in_file, lang, orig_file):
  spm_spp = spm.SentencePieceProcessor()
  spm_prefix = spm_dir+'/spm.{}'.format(lang)
  spm_spp.Load(spm_prefix+".model")

  with open(in_file+'.{}'.format(lang), 'r') as infile, open(orig_file+'.{}'.format(lang), 'w') as outfile:
    for line in infile:
      print(spm_spp.DecodePieces(line.split()), file=outfile) 


def main():
  parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument("--run", choices=['train', 'encode', 'decode'], required=True,
                      help="specify run type.")
  parser.add_argument("--spm_dir", required=True, 
                      help="sp model dir." )
  parser.add_argument("--in_file", required=True, 
                      help="file prefix for training spm, enc. or dec.")
  parser.add_argument("--src", required=False, default="", 
                      help="source file id/postfix.")
  parser.add_argument("--tgt", required=False, default="", 
                      help="target file id/posfix.")
  parser.add_argument("--spm_size", required=False, default=3200, 
                      help="number of segmentation rules.")
  parser.add_argument("--op_file", required=False, default="", 
                      help="file prefix for encoded sp file.")
  #parser.add_argument("--vocab_threshold", required=False, default=0, 
  #                    help="Vocabulary threshold for segmentation.")
  args = parser.parse_args()


  if args.run == "train":
    train(args.spm_dir, args.in_file, args.src, args.tgt, args.spm_size)
  
  elif args.run == "encode":
    if not os.path.exists(args.spm_dir) and args.in_file != "":
      print("requires: ", args.spm_dir, args.in_file)
      return
    else:
      if args.src:
        encode(args.spm_dir, args.in_file, args.src, args.op_file)
      if args.tgt:
        encode(args.spm_dir, args.in_file, args.tgt, args.op_file)

  elif args.run == "decode":
    if not os.path.exists(args.spm_dir) and args.in_file != "":
      print("requires: ", args.spm_dir, args.sp_file)
      return
    else:
      if args.src:
        decode(args.spm_dir, args.in_file, args.src, args.op_file)
      if args.tgt:
        decode(args.spm_dir, args.in_file, args.tgt, args.op_file)


if __name__ == "__main__":
  main()
