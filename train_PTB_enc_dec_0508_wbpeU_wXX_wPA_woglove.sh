#!/bin/bash -x

TRAIN_SRC=data/sec.02-21.sent_w_bpe1000_wunk
TRAIN_TRG=data/sec.02-21.se.const:data/sec.02-21.wposA.se.const

DEV_SRC=data/sec.22.sent_w_bpe1000_wunk
DEV_TRG=data/sec.22.se.const:data/sec.22.wposA.se.const
DEV_SRC_ORIG=data/sec.22.sent
DEV_TRG_POS=data/sec.22.pos
DEV_TRG_GOLD=data/sec.22.gold

TEST_SRC=data/sec.23.sent_w_bpe1000_wunk
TEST_SRC_ORIG=data/sec.23.sent
TEST_TRG_POS=data/sec.23.pos
TEST_TRG_GOLD=data/sec.23.gold

VOCAB_SRC=data/all.sent_w_bpe1000.vocab2
VOCAB_TRG=data/sec.02-21.se.const.vocab:data/sec.02-21.wposA.se.const.vocab


SCRIPT_DIR=/path-to-nmpnlp-nmt/
GPU=${1}
SEED=${2}
EP=100
MODEL_DIR=./models_encdec_mb16_SGD_e300h200L2_gc1_wbpeU_wXX_wPA_wog_wTying_wMergeFWBW_rs${SEED}

mkdir -p ${MODEL_DIR}
python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
       --verbose 1 \
       --gpu-enc ${GPU} \
       --gpu-dec ${GPU} \
       --train-test-mode train \
       --embed-dim 300 \
       --hidden-dim 200 \
       --num-rnn-layers 2 \
       --epoch ${EP} \
       --batch-size 16 \
       --output ${MODEL_DIR}/model \
       --out-each 1 \
       --enc-vocab-file ${VOCAB_SRC} \
       --dec-vocab-file ${VOCAB_TRG} \
       --enc-data-file ${TRAIN_SRC} \
       --dec-data-file ${TRAIN_TRG} \
       --enc-devel-data-file ${DEV_SRC} \
       --dec-devel-data-file ${DEV_TRG} \
       --lrate 1.0 \
       --optimizer SGD \
       --gradient-clipping 1.0 \
       --dropout-rate 0.3 \
       --initializer-scale 0.1 \
       --eval-accuracy 1 \
       --use-encoder-bos-eos 0 \
       --merge-encoder-fwbw 0 \
       --attention-mode 1 \
       --use-decoder-inputfeed 1 \
       --lrate-decay-at 50 \
       --lrate-no-decay-to 50 \
       --lrate-decay 0.9 \
       --shuffle-data-mode 1 \
       --output-layer-type 0 \
       --random-seed ${SEED} \
       --merge-encoder-fwbw 1 \
       --dec-emb-tying \
    | tee  ${MODEL_DIR}/train.log


for i in 1 5 ; do
    EXT=`basename ${DEV_SRC}` ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${DEV_SRC} \
           --setting    ${MODEL_DIR}/model.setting \
           --init-model ${MODEL_DIR}/model.epoch${EP} \
           --max-length 300 \
           --beam-size  ${i} \
           --length-normalized \
           --use-bos \
           --without-unk \
           > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} | \
        ./scripts/strip-start-end-marker.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
        && \
    perl ./scripts/decode.pl \
         ${DEV_SRC_ORIG}  ${DEV_TRG_POS} \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const |\
        ./scripts/add-start-end-bracket.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top \
        && \
    ./EVALB/evalb \
        -p ./EVALB/COLLINS.prm ${DEV_TRG_GOLD} \
        ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top
done


for i in 1 5 ; do
    EXT=`basename ${DEV_SRC}`.restrict ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${DEV_SRC} \
           --setting    ${MODEL_DIR}/model.setting \
           --init-model ${MODEL_DIR}/model.epoch${EP} \
           --max-length 300 \
           --beam-size  ${i} \
           --length-normalized \
           --use-bos \
           --without-unk \
           --use-restrict-decoding \
           > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} | \
        ./scripts/strip-start-end-marker.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
        && \
    perl ./scripts/decode.pl \
         ${DEV_SRC_ORIG}  ${DEV_TRG_POS} \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const |\
        ./scripts/add-start-end-bracket.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top \
        && \
    ./EVALB/evalb \
        -p ./EVALB/COLLINS.prm ${DEV_TRG_GOLD} \
        ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top
done




for i in 1 5 ; do
    EXT=`basename ${TEST_SRC}` ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${TEST_SRC} \
           --setting    ${MODEL_DIR}/model.setting \
           --init-model ${MODEL_DIR}/model.epoch${EP} \
           --max-length 300 \
           --beam-size  ${i} \
           --length-normalized \
           --use-bos \
           --without-unk \
           > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} |\
        ./scripts/strip-start-end-marker.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
        && \
    perl ./scripts/decode.pl \
         ${TEST_SRC_ORIG}  ${TEST_TRG_POS} \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const |\
        ./scripts/add-start-end-bracket.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top \
        && \
    ./EVALB/evalb \
        -p ./EVALB/COLLINS.prm ${TEST_TRG_GOLD} \
        ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top
done

for i in 1 5 ; do
    EXT=`basename ${TEST_SRC}`.restrict ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${TEST_SRC} \
           --setting    ${MODEL_DIR}/model.setting \
           --init-model ${MODEL_DIR}/model.epoch${EP} \
           --max-length 300 \
           --beam-size  ${i} \
           --length-normalized \
           --use-bos \
           --without-unk \
           --use-restrict-decoding \
           > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i} |\
        ./scripts/strip-start-end-marker.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
        && \
    perl ./scripts/decode.pl \
         ${TEST_SRC_ORIG}  ${TEST_TRG_POS} \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip \
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const \
        && \
    cat ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const |\
        ./scripts/add-start-end-bracket.sh \
            > ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top \
        && \
    ./EVALB/evalb \
        -p ./EVALB/COLLINS.prm ${TEST_TRG_GOLD} \
        ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.const.top
done
