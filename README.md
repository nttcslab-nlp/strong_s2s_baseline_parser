# strong_s2s_baseline_parser


## Requirement
* chainer
  * see instruction https://chainer.org


## Preparing Dataset
* Obtain, a modified version of ptbconv-3.0
```bash
git clone https://github.com/kamigaito/ptbconv-3.0.git
cd ptbconv-3.0
./configure
make
```

* Convert format of Penn Treebank3 *.mrg by ptbconv-3.0
```
# constituency format
/path-to-ptbconv-3.0/ptbconv -B < [sec.02-21.mrg] | scripts/strip-start-end-bracket.sh > tmp/sec.02-21.cnt.txt
/path-to-ptbconv-3.0/ptbconv -B < [sec.22.mrg] | scripts/strip-start-end-bracket.sh > tmp/sec.22.cnt.txt
/path-to-ptbconv-3.0/ptbconv -B < [sec.23.mrg] | scripts/strip-start-end-bracket.sh > tmp/sec.23.cnt.txt

# dependency format
/path-to-ptbconv-3.0/ptbconv -D < [sec.02-21.mrg] > tmp/sec.02-21.dep.txt
/path-to-ptbconv-3.0/ptbconv -D < [sec.22.mrg] > tmp/sec.22.dep.txt
/path-to-ptbconv-3.0/ptbconv -D < [sec.23.mrg] > tmp/sec.23.dep.txt

# word->XX format
perl scripts/encode.pl tmp/sec.02-21.{cnt,dep}.txt tmp/sec.02-21.{const,align}
perl scripts/encode.pl tmp/sec.22.{cnt,dep}.txt tmp/sec.22.{const,align}

scripts/add-start-end-marker.sh < tmp/sec.02-21.const > data/sec.02-21.se.const
scripts/add-start-end-marker.sh < tmp/sec.22.const    > data/sec.22.se.const

perl scripts/get_column.pl < tmp/sec.02-21.dep.txt 0 3 > tmp/sec.02-21.sent
perl scripts/get_column.pl < tmp/sec.22.dep.txt 0 3    > tmp/sec.22.sent
perl scripts/get_column.pl < tmp/sec.23.dep.txt 0 3    > tmp/sec.23.sent

perl scripts/get_column.pl < tmp/sec.02-21.dep.txt 1 3 > tmp/sec.02-21.pos
perl scripts/get_column.pl < tmp/sec.22.dep.txt 1 3    > tmp/sec.22.pos
perl scripts/get_column.pl < tmp/sec.23.dep.txt 1 3    > tmp/sec.23.pos

cat data/sec.02-21.se.const | perl script/combine_pos.pl data/sec.02-21.pos2 > data/sec.02-21.wposA.se.const
cat data/sec.22.se.const    | perl script/combine_pos.pl data/sec.22.pos2    > data/sec.22.wposA.se.const

```

* Get subword-nmt for obtaining subword information
```bash
git clone https://github.com/rsennrich/subword-nmt
```

* Make input files
```bash
/path-subword-nmt/learn_bpe.py -s 1000 < data/sec.02-21.sent > data/sec.02-21.sent.bpe1000.dict

/path-subword-nmt/apply_bpe.py -c data/sec.02-21.sent.bpe1000.dict < data/sec.02-21.sent > data/sec.02-21.sent.bpe1000
/path-subword-nmt/apply_bpe.py -c data/sec.02-21.sent.bpe1000.dict < data/sec.22.sent    > data/sec.22.sent.bpe1000
/path-subword-nmt/apply_bpe.py -c data/sec.02-21.sent.bpe1000.dict < data/sec.23.sent    > data/sec.23.sent.bpe1000

perl scripts/combine_bpe.pl data/sec.02-21.sent  data/sec.22.sent_bpe1000 > data/sec.02-21.sent_w_bpe1000_wunk
perl scripts/combine_bpe.pl data/sec.22.sent  data/sec.22.sent_bpe1000 > data/sec.22.sent_w_bpe1000_wunk
perl scripts/combine_bpe.pl data/sec.23.sent  data/sec.23.sent_bpe1000 > data/sec.23.sent_w_bpe1000_wunk
```

## Run training/evaluation code
* Get the mlpnlp-nmt code for training/test encoder-decoder model
```bash
git clone https://github.com/mlpnlp/mlpnlp-nmt.git
cd mlpnlp-nmt
git checkout for_parser
```

* Make vocab files
```bash
cat data/sec.02-21.sent_w_bpe1000_wunk data/sec.22.sent_w_bpe1000_wunk data/sec.23.sent_w_bpe1000_wunk  | perl -pe 's/\|\|\|/ /g' | python /path-to-mlpnlp-nmt/count_freq.py 0 |grep -v "<unk>" > data/all.sent_w_bpe1000.vocab
cat data/sec.02-21.se.const        | python /path-to-mlpnlp-nmt/count_freq.py 0  > data/sec.02-21.se.const.vocab
cat data/sec.02-21.wposA.se.const  | python /path-to-mlpnlp-nmt/count_freq.py 0  > data/sec.02-21.wposA.se.const.vocab

```

* Obtain evalb to evaluate parser performance
  * https://nlp.cs.nyu.edu/evalb/

* Run training/evaluation script
```bash
./train_PTB_enc_dec_0508_wbpeU_wXX_wPA_woglove.sh 0 2720
```

 * 10 models
```bash
for SEED in 2720 2721 2722 2723 2724 2725 2726 2727 2728 2729  ;do \
   ./train_PTB_enc_dec_0508_wbpeU_wXX_wPA_woglove.sh 0 ${SEED} ;\
done
```

 * Ensemble (evaluation)
```bash
DIR=models_encdec_mb16_SGD_e300h200L2_gc1_wbpeU_wXX_wPA_wog_wTying_wMergeFWBW_rs ; \
./train_PTB_enc_dec_0508_ENSEMBLE.sh 0 \
 ${DIR}2720/model.setting \
 ${DIR}2720/model.epoch100:${DIR}2721/model.epoch100:${DIR}2722/model.epoch100:${DIR}2723/model.epoch100:${DIR}2724/model.epoch100:${DIR}2725/model.epoch100:${DIR}2726/model.epoch100:${DIR}2727/model.epoch100 \
 ${DIR}2720/ \
 data/sec.22.sent_w_bpe1000_wunk \
 data/sec.23.sent_w_bpe1000_wunk
```
