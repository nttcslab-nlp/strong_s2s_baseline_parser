#!/bin/bash -x


DEV_SRC=${5}
DEV_SRC_ORIG=data/sec.22.sent
DEV_TRG_POS=data/sec.22.pos
DEV_TRG_GOLD=data/sec22.gold

TEST_SRC=${6}
TEST_SRC_ORIG=data/sec.23.sent
TEST_TRG_POS=data/sec.23.pos
TEST_TRG_GOLD=data/sec23.gold

SCRIPT_DIR=/path-to-nmpnlp-nmt/
GPU=${1}
SETTING=${2}
MODEL=${4}

for i in  5 ; do
    EXT=`basename ${DEV_SRC}`.ensemble ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${DEV_SRC} \
           --setting    ${SETTING} \
           --init-model ${MODEL} \
           --max-length 300 \
           --beam-size ${i} \
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
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip  \
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

for i in  5 ; do
    EXT=`basename ${DEV_SRC}`.ensemble_restrict ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${DEV_SRC} \
           --setting    ${SETTING} \
           --init-model ${MODEL} \
           --max-length 300 \
           --beam-size ${i} \
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
         ${MODEL_DIR}/result.${EXT}.hyp.norm.beam${i}.strip  \
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



for i in  5 ; do
    EXT=`basename ${TEST_SRC}`.ensemble ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${TEST_SRC} \
           --setting    ${SETTING} \
           --init-model ${MODEL} \
           --max-length 300 \
           --beam-size ${i} \
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



for i in  5 ; do
    EXT=`basename ${TEST_SRC}`.ensemble_restrict ;
    python -u ${SCRIPT_DIR}/LSTMEncDecAttn.py \
           --gpu-enc ${GPU} \
           --gpu-dec ${GPU} \
           --train-test-mode test \
           --enc-data-file ${TEST_SRC} \
           --setting    ${SETTING} \
           --init-model ${MODEL} \
           --max-length 300 \
           --beam-size ${i} \
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
