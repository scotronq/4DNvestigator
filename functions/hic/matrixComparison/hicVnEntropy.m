function [vnEntropy,AInputEigs] = hicVnEntropy(AInput,numEigs,normEigs,preProcess)
%hicVnEntropy computes the Von Neumann graph entropy of the matrix A
%
%   Inputs
%   AInput:     Input matrix for Von Neumann entropy calculation (NxN double; default: N/A)
%   numEigs:    number of eigenvalues to consider for compuation (integer;
%   default:    size(AInput,1)
%   normEigs:   normalize eigenvalues flag ([0,1]; default: 1)
%   preProcess: arguments for preprocessing methods (string; default: 'none')
%
%   Outputs
%   vnEntropy: Von Neumann Entropy of the input matrix (double)
%   AInputEigs: eigenvalues of the input matrix (numEigsx1 double)
%
%   Example
%   A = corr(rand(10));
%   [B] = function(A)
%
%
%   Version 1.1 (5/24/19)
%   Written by: Scott Ronquist
%   Contact:    scotronq@umich.edu
%   Created:    7/29/18
%   
%   Revision History:
%   v1.0 (7/29/18)
%   * sfAnalysis.m created
%   v1.1 (5/24/19)
%   * sfAnalysis.m created

%% Set default parameters
if ~exist('preProcess','var')||isempty(preProcess); preProcess='none'; end
if ~exist('normEigs','var')||isempty(normEigs); normEigs=1; end
if ~exist('numEigs','var')||isempty(numEigs); numEigs=size(AInput,1); end

% initialize output variables
AInputEigs = zeros(numEigs,size(AInput,3));
vnEntropy = zeros(size(AInput,3),1);

% loop through input matrices and calculate VNE
for iA = 1:size(AInput,3)
    
    % preprocess
    switch preProcess
        case 'none'
            A = AInput(:,:,iA);
        case 'laplacian'
            A = hicLaplacianFdv(AInput(:,:,iA));
        case 'corr'
            A = corr(AInput(:,:,iA));
            A(isnan(A))=0;
    end
    
    % eigen decomposition
    tempEigs = eig(A);
    
    % normalize eigenvalues
    if normEigs == 1
        tempEigs = tempEigs./sum(tempEigs);
    end
    
    % take a subset of eigenvalues
    AInputEigs(:,iA) = tempEigs(1:numEigs);
    
    % get non-zero eigs
    tempEigs = AInputEigs(AInputEigs(:,iA)~=0,iA);
    
    % Von Neumann Entropy
    vnEntropy(iA) = real(-sum(tempEigs.*log(tempEigs)));
end

end



