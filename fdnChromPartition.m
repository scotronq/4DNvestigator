function [H,R] = fdnChromPartition(dataInfo,H,R,partParam)
%fdnChromPartition partitions the chromatin into nodal domains
%   Detailed explanation goes here
%
%   Input
%   dataInfo: 
%   H: 
%   R: 
%   partParam: 
%
%   Output
%   H: now includes the chrom partitioning
%
%   Scott Ronquist, scotronq@umich.edu. 12/19/18

%% set parameter defaults
if ~isfield(partParam,'method')||isempty(partParam.method)
    partParam.method = 'fiedler';
end
if ~isfield('partParam','rnaSeqNorm')||isempty(partParam.rnaSeqNorm)
    partParam.rnaSeqNorm = [];
end
if ~isfield('partParam','chrDivide')||isempty(partParam.chrDivide)
    partParam.chrDivide = 'no';
end
if ~isfield('partParam','plotFlag')||isempty(partParam.plotFlag)
    partParam.plotFlag = 0;
end
if ~isfield('partParam','fdvSplitMethod')||isempty(partParam.fdvSplitMethod)
    partParam.fdvSplitMethod = 'sign';
end

%% get chr information from hic header
chrInfo = dataInfo.hicHeader.Chromosomes;
numChr = height(chrInfo);
numHicSamps = length(find(ismember(dataInfo.sampleInfo.dataType,'hic')));

%% Chromatin Partitioning
H.s100kb.ABcomp = cell(numChr,1);
H.s100kb.groupIdx = cell(numChr,1);
for iChr = 1:numChr
    for iSample = 1:numHicSamps
        fprintf('AB comp, Sample: (%d/%d), chr:%d...\n',iSample,numHicSamps,iChr)
        
        if ~isempty(H.s100kb.oeTrim{iChr}(:,:,iSample))
            
            % get Chromatin Partitioning
            hTemp = H.s100kb.oeTrim{iChr}(:,:,iSample);
            hTemp(hTemp>prctile(hTemp(:),99)) = prctile(hTemp(:),99);
            
            rTemp = log2(R.s100kb.tpmMeanTrim{iChr}(:,iSample)+1);
            [H.s100kb.ABcomp{iChr}(:,iSample),H.s100kb.groupIdx{iChr}(:,iSample)] =...
                hicABcomp(hTemp,partParam.method,rTemp,partParam.rnaSeqNorm,...
                partParam.chrDivide,partParam.plotFlag,partParam.fdvSplitMethod);
            
        end
    end
end

%% plot each partition
fn = [dataInfo.path.output,dataInfo.delim,'figures',dataInfo.delim,'chromPart'];
mkdir(fn)
for iChr = 1:numChr
    for iSample = 1:numHicSamps
        fprintf('plotting figure, Sample: (%d/%d), chr:%d...\n',iSample,numHicSamps,iChr)
        
        % skip if doesnt exist
        try
            temp = H.s100kb.ABcomp{iChr}(:,iSample);
        catch
            continue
        end
        
        % get figure properties
        hicCMap = [ones(64,1),[1:-1/63:0]',[1:-1/63:0]'];
        figure('position',[100 100 700 1000])
        
        % plot RNA-seq
        ax1 = subplot(6,1,1);
        rTemp = log2(R.s100kb.tpmMeanTrim{iChr}(:,iSample)+1);
        bar(rTemp), axis tight
        title(sprintf('%s, T:%i, Chr%s',dataInfo.sampleInfo.sample{iSample},...
            dataInfo.sampleInfo.timePoint(iSample),chrInfo.chr{iChr}))
        ylabel('log_2 TPM')
        
        % plot ABcomp
        ax2 = subplot(6,1,2);
        tempAB = H.s100kb.ABcomp{iChr}(:,iSample);
        b = bar(tempAB,'FaceColor','flat','EdgeColor','none');
        b.CData(H.s100kb.groupIdx{iChr}(:,iSample)==1,:) = repmat([1 0 0],...
            sum(H.s100kb.groupIdx{iChr}(:,iSample)==1),1);
        b.CData(H.s100kb.groupIdx{iChr}(:,iSample)==2,:) = repmat([0 1 0],...
            sum(H.s100kb.groupIdx{iChr}(:,iSample)==2),1);
        axis tight
        ylabel(partParam.method)
        
        % plot Hi-C
        ax3 = subplot(6,1,3:6);
        hTemp = H.s100kb.oeTrim{iChr}(:,:,iSample);
        climMain = [0 prctile(hTemp(:),90)];
        hTemp(hTemp>prctile(hTemp(:),99)) = prctile(hTemp(:),99);
        imagesc(hTemp), axis square
        colormap(ax3,hicCMap); %colorbar
        caxis(climMain)
        ylabel(sprintf('chr%i Hi-C map',iChr))
        
        % figure format
        set(get(gcf,'children'),'linewidth',2,'fontsize',15)
        linkaxes(get(gcf,'children'),'x')
        
        % save figure
        saveas(gcf,sprintf('%s%ss%s_t%i_chr%s.fig',fn,...
            dataInfo.delim,dataInfo.sampleInfo.sample{iSample},...
            dataInfo.sampleInfo.timePoint(iSample),...
            chrInfo.chr{iChr}))
        
        close all
    end
end

%% add average A/B to gene table
% create gene AB table
R.abTable = R.TPM(:,1:6);
ab = zeros(height(R.abTable),size(H.s100kb.ABcomp{1},2));

% loop through gene list and find AB for each gene
for iGene = 1:height(R.abTable)
    disp(iGene/height(R.abTable))
    
    % find gene name in trim 100kb bin genenames
    temp = mean(H.s100kb.ABcomp{R.abTable.chr(iGene)}...
        (cellfun(@(x) any(strcmp(x,R.abTable.geneName{iGene})),...
        R.s100kb.geneTrim{R.abTable.chr(iGene)}),:),1);
    
    ab(iGene,:) = temp;
end

R.abTable = [R.abTable,table(ab)];

%% find AB switch region



end
