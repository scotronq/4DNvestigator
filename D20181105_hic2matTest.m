% Goal: load Hi-C data from our server onto alternate laptop 
clear
close all

%% load paths
restoredefaultpath
addpath(genpath('.'))

%% Load Hi-C data
hicLoc = '\\172.17.109.24\internal_4DN\projects\tcf7l2_silence_sw480_and_rpe\hic\processed\hg19\Sample_76099\aligned\inter_30.hic';

%%% PARAMETERS vvv
hicParam.binType = 'BP';
hicParam.binSize = 1E5;
hicParam.norm1d = 'KR';
hicParam.norm3d = 'oe';
hicParam.intraFlag = 1;
hicParam.chr = 1;
%%% PARAMETERS ^^^

H = hic2mat(hicParam.norm3d,hicParam.norm1d,hicLoc,...
    hicParam.chr,hicParam.chr,hicParam.binType,hicParam.binSize,hicParam.intraFlag);

figure, imagesc(log(H))
