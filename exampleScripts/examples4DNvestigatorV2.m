%% Description
% This script provides and overview of the methods described in the
% "4DNvestigator: a toolbox for the analysis of timeseries Hi-C and RNA-seq
% data"
%
% Scott Ronquist, scotronq@umich.edu. 4/28/19

%% Set up
clear
close all

%% Select Data set to Load
% load publicly available Hi-C and RNA-seq datasets

datasetSelect = 'myod';
switch datasetSelect
    case 'myod'
        indexFile = 'https://s3.us-east-2.amazonaws.com/4dnvestigator/sampleData/myod/sampleMyodDataIndexTp-48_8_80.xlsx';
    case 'tcf7l2'
        indexFile = 'https://s3.us-east-2.amazonaws.com/4dnvestigator/sampleData/tcf7l2/sampleTcf7l2DataIndexTp0_72.xlsx';
end

%% Load data through the 4DNvestigator functions
[dataInfo] = fdnLoadUserInput(indexFile);
[H] = fdnLoadHic(dataInfo,'single');
[R] = fdnLoadRnaseq(dataInfo,H);

% save data
save([dataInfo.path.output,dataInfo.delim,dataInfo.projName,'Data.mat'],'H','R','dataInfo','-v7.3')

%% Time series differential expression
% run samples through differential expression analysis, with time gene
% expression pattern analysis
gseaFlag = 1;
rnaseqPatternFlag = 1;
[R] = fdnDiffExpGsaa(dataInfo,R,1,1);

%% 4DN Feature Analyzer Example
% select Regions of Interest
% selecting chromosome 11
chrSelect = 11;
goiH = H.s100kb.oeTrim{chrSelect};
goiR = R.s100kb.tpmMeanTrim{chrSelect};
goi = R.s100kb.geneTrim{chrSelect};

% select dimension reduction method and run through 4DN feature analyzer
dimReduc = 'pca';
[features,score] = sfAnalysis(goiH,goiR,goi,[],[],[],dimReduc);

%% Larntz-Perlman Example
% select Regions of Interest
% selecting region surrounding MYOD1 gene location
goi = 'MYOD1';
goiFlank = 30;

% extracting Hi-C ROIs to analyze
goiChr = R.TPM.chr(ismember(R.TPM.geneName,goi),:);
goiLoc = find(cell2mat(cellfun(@sum, cellfun(@(x) contains(x,goi),...
    R.s100kb.geneTrim{R.TPM.chr(ismember(R.TPM.geneName,goi),:)},...
    'UniformOutput',false), 'UniformOutput',false)));
goiLocFlank = max([1, goiLoc-goiFlank]):min([size(H.s100kb.oeTrim{goiChr},1), goiLoc+goiFlank]);
roiH = H.s100kb.oeTrim{goiChr}(goiLocFlank,goiLocFlank,:);

% Calculate the correlation matrices
Hcorr = zeros(size(roiH));
for iSample = 1:size(roiH,3)
    Hcorr(:,:,iSample) = corr(roiH(:,:,iSample));
end

% Perform the Larntz-Perlman procedure on these correlation matrices
alphaParam = .95;
plotFlag = 0;
[H0,P,S] = larntzPerlman(Hcorr,size(Hcorr,1),alphaParam,plotFlag);

% Identify regions in 99th percentile L-P regions
tempXPrctile = 99;
LPRegions = S > prctile(S(:),tempXPrctile);

% Figure
roiHLim = [min(log(roiH(:))) max(log(roiH(:)))];
hicCMap = [ones(64,1),[1:-1/63:0]',[1:-1/63:0]'];
figure('position',[100 500 1310 340])
for iSample = 1:size(roiH,3)
    
    % Plot Hi-C
    ax = subplot(1,size(roiH,3),iSample);
    imagesc(log(roiH(:,:,iSample))), axis square
    colormap(ax, hicCMap), caxis(roiHLim)
    title(sprintf('log_2(Hi-C), sample %i', iSample))
    
    % Add circles around Larntz-Perlman ROIs
    addROICircles(LPRegions)
end
set(get(gcf,'children'),'linewidth',2,'fontsize',15)
linkaxes(get(gcf,'children'))
