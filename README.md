# strong_s2s_baseline_parser
#### An Empirical Study of Building a Strong Baseline for Constituency Parsing
* http://www.aclweb.org/anthology/P18-2097
```
@inproceedings{P18-2097,
    title = "An Empirical Study of Building a Strong Baseline for Constituency Parsing",
    author = "Suzuki, Jun  and  Takase, Sho  and  Kamigaito, Hidetaka  and  Morishita, Makoto  and  Nagata, Masaaki",
    booktitle = "Proceedings of the 56th Annual Meeting of the Association for Computational Linguistics (Volume 2: Short Papers)",
    month = "July",
    year = "2018",
    address = "Melbourne, Australia",
    publisher = "Association for Computational Linguistics",
    url = "http://www.aclweb.org/anthology/P18-2097",
    pages = "612--618",
}
```

## Requirement
* chainer
  * see instruction https://chainer.org


## Preparing Dataset
#### Obtain, a modified version of ptbconv-3.0
```bash
git clone https://github.com/kamigaito/ptbconv-3.0.git
cd ptbconv-3.0
./configure
make
```

#### Convert format of Penn Treebank3 *.mrg by ptbconv-3.0
```
# copy ptb3
for i in 00 01 02 03 04 05 06 07 08 09 `seq 10 24` ;do \
    cat /path-to-ptb3/${i}/WSJ_*.MRG > tmp/sec.${i}.mrg ;\
done


# get raw sentences and pos sequences via the ptbconv dependency format
for i in 00 01 02 03 04 05 06 07 08 09 `seq 10 24` ;do \
    cat tmp/sec.${i}.mrg   | ptbconv-3.0/ptbconv -D >  tmp/sec.${i}.dep.txt  ;\
    cat tmp/sec.${i}.dep.txt | perl scripts/get_column.pl 0 3 > tmp/sec.${i}.sent ;\
    cat tmp/sec.${i}.dep.txt | perl scripts/get_column.pl 1 3 > tmp/sec.${i}.pos  ;\
done


# remove function tags and empty symbols, and then conver word->XX format
for i in 00 01 02 03 04 05 06 07 08 09 `seq 10 24` ;do \
    cat tmp/sec.${i}.mrg   | perl scripts/remove_function_none_tag.pl | scripts/strip-start-end-bracket.sh > tmp/sec.${i}.cnt.txt  ;\
    perl scripts/encode.pl tmp/sec.${i}.cnt.txt  tmp/sec.${i}.const  ;\
    cat tmp/sec.${i}.const | scripts/add-start-end-marker.sh > tmp/sec.${i}.se.const ;\
done


# finalize input files (word sequence files)
for i in 02 03 04 05 06 07 08 09 `seq 10 21` ;do \
    cat tmp/sec.${i}.sent ;\
done > data/sec.02-21.sent
cp tmp/sec.22.sent tmp/sec.23.sent data


# finalize output files (words with brackets)
{pfor i in 02 03 04 05 06 07 08 09 `seq 10 21` ;do \
    cat tmp/sec.${i}.se.const ;\
done > data/sec.02-21.se.const
cp tmp/sec.22.se.const data

# make output file with pos info
cat data/sec.02-21.se.const | perl scripts/combine_pos.pl data/sec.02-21.pos2 > data/sec.02-21.wposA.se.const
cat data/sec.22.se.const    | perl scripts/combine_pos.pl data/sec.22.pos2    > data/sec.22.wposA.se.const

# make gold data for evaluation
cat tmp/sec.22.cnt.txt  | perl -pe 'chomp; $_="(TOP ".$_.")\n"' > data/sec.22.gold
cat tmp/sec.23.cnt.txt  | perl -pe 'chomp; $_="(TOP ".$_.")\n"' > data/sec.23.gold

# copy pos files for also evaluation
cp tmp/sec.22.pos tmp/sec.23.pos   data

```

#### Get subword-nmt for obtaining subword information
```bash
git clone https://github.com/rsennrich/subword-nmt
```

#### Make input files
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
#### Get the mlpnlp-nmt code for training/test encoder-decoder model
```bash
git clone https://github.com/mlpnlp/mlpnlp-nmt.git
cd mlpnlp-nmt
git checkout for_parser
```

#### Make vocab files
```bash
cat data/sec.02-21.sent_w_bpe1000_wunk data/sec.22.sent_w_bpe1000_wunk data/sec.23.sent_w_bpe1000_wunk  | perl -pe 's/\|\|\|/ /g' | python /path-to-mlpnlp-nmt/count_freq.py 0 |grep -v "<unk>" > data/all.sent_w_bpe1000.vocab
cat data/sec.02-21.se.const        | python /path-to-mlpnlp-nmt/count_freq.py 0  > data/sec.02-21.se.const.vocab
cat data/sec.02-21.wposA.se.const  | python /path-to-mlpnlp-nmt/count_freq.py 0  > data/sec.02-21.wposA.se.const.vocab

```

#### Obtain evalb to evaluate parser performance
  * https://nlp.cs.nyu.edu/evalb/

#### Run training/evaluation script
```bash
./train_PTB_enc_dec_0508_wbpeU_wXX_wPA_woglove.sh 0 2720
```

#### 10 models
```bash
for SEED in 2720 2721 2722 2723 2724 2725 2726 2727 2728 2729  ;do \
   ./train_PTB_enc_dec_0508_wbpeU_wXX_wPA_woglove.sh 0 ${SEED} ;\
done
```

#### Ensemble (evaluation)
```bash
DIR=models_encdec_mb16_SGD_e300h200L2_gc1_wbpeU_wXX_wPA_wog_wTying_wMergeFWBW_rs ; \
./train_PTB_enc_dec_0508_ENSEMBLE.sh 0 \
 ${DIR}2720/model.setting \
 ${DIR}2720/model.epoch100:${DIR}2721/model.epoch100:${DIR}2722/model.epoch100:${DIR}2723/model.epoch100:${DIR}2724/model.epoch100:${DIR}2725/model.epoch100:${DIR}2726/model.epoch100:${DIR}2727/model.epoch100 \
 ${DIR}2720/ \
 data/sec.22.sent_w_bpe1000_wunk \
 data/sec.23.sent_w_bpe1000_wunk
```
