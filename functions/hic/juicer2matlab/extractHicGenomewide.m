function [H,chrStart] = extractHicGenomewide(hicPath,refGenome,binSize,binType,norm1d,norm3d)
%extractHicGenomewide extract Hi-C genome-wide, including intra-chr
%
%   Input
%   hicPath:    .hic file path (string)
%   refGenome:  Reference genome (string; eg 'hg19' [default])
%   binSize:    Bin size, or Hi-C resolution (string or double)
%   binType:    Bin type, 'BP' or 'FRAG' (string)
%   norm1d:     Hi-C 3d normalization, 'oe' or 'observed' (string)
%   norm3d:     Hi-C 1d normalization, 'KR' or 'NONE' (string)
%
%   Output
%   H:          Hi-C matrix
%   chrStart:   Chromosome start locations
%
%   Example
%   [H,chrStart] = extractHicGenomewide('E:\MATLAB\srMatlabFunctions\GSFAT\sampleData\hic\aldh_N.hic','hg19');
%
%   Scott Ronquist, 1/22/19

%% check input arguments, set defaults
if ~exist('refGenome','var')||isempty(refGenome); refGenome = 'hg19';end
if ~exist('binSize','var')||isempty(binSize); binSize = 1E6;end
if ~exist('binType','var')||isempty(binType); binType = 'BP';end
if ~exist('norm1d','var')||isempty(norm1d); norm1d = 'KR';end
if ~exist('norm3d','var')||isempty(norm3d); norm3d = 'oe';end

%% get chr sizes to stitch together
chrSizes = readtable(sprintf('%s.chrom.sizes',refGenome),'filetype','text');
chrStart = [1;cumsum(ceil(chrSizes{:,2}./binSize))+1];
H = zeros(chrStart(end)-1,chrStart(end)-1);

%% load Hi-C
for iChr1 = 1:length(chrStart)-1
    for iChr2 = iChr1:length(chrStart)-1
        fprintf('loading 1Mb Hi-C. chr1:%d, chr2:%d...\n',iChr1,iChr2)
        iChr1_ = chrSizes{iChr1,1}{1}(4:end);
        iChr2_ = chrSizes{iChr2,1}{1}(4:end);
        
        if iChr1==iChr2; intraFlag=1;else; intraFlag=0;end
        tempH = hic2mat(norm3d,norm1d,hicPath,...
            iChr1_,iChr2_,binType,binSize,intraFlag);
        tempH(isnan(tempH)) = 0;
        
        H(chrStart(iChr1):chrStart(iChr1)+size(tempH,1)-1,...
            chrStart(iChr2):chrStart(iChr2)+size(tempH,2)-1) = tempH;
    end
end
H(:,:) = max(cat(3,H(:,:),H(:,:)'),[],3);

end

