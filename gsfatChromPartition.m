function [H] = gsfatChromPartition(dataInfo,H,R)
%gsfatChromPartition partitions the chromatin into nodal domains
%   Detailed explanation goes here
%
%   Input
%   dataInfo: 
%   H: 
%   R: 
%
%   Output
%   H: now includes the chrom partitioning
%
%   Scott Ronquist, scotronq@umich.edu. 12/19/18

%% get chr information from hic header
chrInfo = dataInfo.hicHeader.Chromosomes;
numChr = height(chrInfo);
numHicSamps = length(find(ismember(dataInfo.sampleInfo.dataType,'hic')));

%% Chromatin Partitioning
%%% PARAMETERS vvv
hicParam.method='pc1';
hicParam.rnaSeqNorm=[];
hicParam.chrDivide='no';
hicParam.plotFlag=0;
hicParam.fdvSplitMethod='sign';
%%% PARAMETERS ^^^

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
                hicABcomp(hTemp,hicParam.method,rTemp,hicParam.rnaSeqNorm,...
                hicParam.chrDivide,hicParam.plotFlag,hicParam.fdvSplitMethod);
            
        end
    end
end

%% plot each partition
for iChr = 1:numChr
    for iSample = 1:numHicSamps
        fprintf('plotting figure, Sample: (%d/%d), chr:%d...\n',iSample,numHicSamps,iChr)
        
        % get figure properties
        hicCMap = [ones(64,1),[1:-1/63:0]',[1:-1/63:0]'];
        figure('position',[100 100 700 1000])
        
        % plot RNA-seq
        ax1 = subplot(6,1,1);
        rTemp = log2(R.s100kb.tpmMeanTrim{iChr}(:,1)+1);
        bar(rTemp), axis tight
        title('HCEC'), ylabel('log_2 TPM')
        
        % plot ABcomp
        ax2 = subplot(6,1,2);
        tempAB = H.s100kb.ABcomp{iChr}(:,1);
        b = bar(tempAB,'FaceColor','flat','EdgeColor','none');
        b.CData(H.s100kb.groupIdx{iChr}(:,1)==1,:) = repmat([1 0 0],...
            sum(H.s100kb.groupIdx{iChr}(:,1)==1),1);
        b.CData(H.s100kb.groupIdx{iChr}(:,1)==2,:) = repmat([0 1 0],...
            sum(H.s100kb.groupIdx{iChr}(:,1)==2),1);
        axis tight
        ylabel('Fiedler vector')
        
        % plot Hi-C
        ax3 = subplot(6,1,3:6);
        hTemp = H.s100kb.oeTrim{iChr}(:,:,1);
        climMain = [0 prctile(hTemp(:),90)];
        hTemp(hTemp>prctile(hTemp(:),99)) = prctile(hTemp(:),99);
        imagesc(hTemp), axis square
        colormap(ax3,hicCMap); colorbar, caxis(climMain)
        ylabel(sprintf('chr%i Hi-C map',iChr))
        
        % figure format
        set(get(gcf,'children'),'linewidth',2,'fontsize',15)
        linkaxes(get(gcf,'children'),'x')
        
        % save figure
        saveas(gcf,sprintf('chr%s_s%s_t%i.fig',chrInfo.chr{iChr},...
            dataInfo.sampleInfo.sample{iSample},...
            dataInfo.sampleInfo.timePoint(iSample)))
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

%% EXTRA
% fix Chromatin Partitioning sign by correlating with # of genes
%         tempGeneNum = cellfun(@length,R.s100kb.geneTrim{iChr});
%         if mean(tempGeneNum(H.s100kb.groupIdx{iChr}(:,iSample)==1)) >...
%                 mean(tempGeneNum(H.s100kb.groupIdx{iChr}(:,iSample)==2))
%             H.s100kb.ABcomp{iChr}(:,iSample) = -H.s100kb.ABcomp{iChr}(:,iSample);
%             H.s100kb.groupIdx{iChr}(:,iSample) = -H.s100kb.groupIdx{iChr}(:,iSample)+3;
%         end

% % % % % % % % % debug
% % % % % % % % figure, subplot(5,1,1)
% % % % % % % % bar(H.s100kb.ABcomp{iChr}(:,iSample)), axis tight
% % % % % % % % 
% % % % % % % % subplot(5,1,2:5)
% % % % % % % % imagesc(hTemp)
% % % % % % % % linkaxes(get(gcf,'children'),'x')
% % % % % % % % 
% % % % % % % % %
% % % % % % % % figure, histogram(hTemp(:))