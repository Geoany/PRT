% PRTBRVDISCRETEHIERARCHY - PRT BRV Discrete hierarchical model structure
%   Has parameters that specify a dirichlet density
classdef prtBrvDiscreteStickBreakingHierarchy
    properties
        sortingInds
        unsortingInds
    end
    properties
        alphaGammaParams = [1e-6 1e-6];
        counts = [];
        beta = [];
    end
    properties (Hidden = true)
        useGammaPriorOnScale = true;
        useOptimalSorting = true;
    end
    properties (Dependent, SetAccess='private')
        truncationLevel
        expectedValueLogStickLengths
        expectedValueLogOneMinusStickLengths
        expectedValueLogProbabilities
        posteriorMean
        expectedValueAlpha
    end
    
    methods
        function self = prtBrvDiscreteStickBreakingHierarchy(varargin)
            if nargin < 1
                return
            end
            self = defaultParameters(self,varargin{1});
        end
        
        function pis = draw(obj)
             vs = zeros(obj.truncationLevel,2);
             for iV = 1:obj.truncationLevel
                 vs(iV,:) = prtRvUtilDirichletDraw([obj.beta(iV,1),obj.beta(iV,2)]);
             end
             vs = vs(:,1);
             
             pis = zeros(obj.truncationLevel,1);
             for iPi = 1:length(vs)
                 if iPi == 1
                     pis(iPi) = vs(iPi);
                 else
                     pis(iPi) = exp(log(vs(iPi))+sum(log(1-vs(1:(iPi-1)))));
                 end
             end
             
             pis(end) = 1-sum(pis(1:end-1));
             pis(pis<0) = 0; % This happens in the range of eps sometimes.
             
             pis = pis./sum(pis);
        end
        
        function obj = conjugateUpdate(obj,priorObj,counts)
            
            counts = counts(:);
            
            if obj.useOptimalSorting
                [counts, obj.sortingInds] = sort(counts,'descend');
                [dontNeed, obj.unsortingInds] = sort(obj.sortingInds,'ascend'); %#ok<ASGLU>
            else
                obj.sortingInds = (1:obj.truncationLevel)';
                obj.unsortingInds = obj.sortingInds;
            end
            sumIToK = flipud(cumsum(flipud(counts)));
            sumIPlus1ToK = sumIToK-counts;
            
            if obj.useOptimalSorting
                obj.counts = counts(obj.unsortingInds);
                sumIPlus1ToK = sumIPlus1ToK(obj.unsortingInds);
            else
                obj.counts = counts;
            end
            
            % Update stick parameters
            obj.beta(:,1) = obj.counts + priorObj.beta(:,1);
            obj.beta(:,2) = sumIPlus1ToK + priorObj.beta(:,2) + obj.expectedValueAlpha;
            
            % Update alpha Gamma density parameters
            if obj.useGammaPriorOnScale
                obj.alphaGammaParams(1) = priorObj.alphaGammaParams(1) + obj.truncationLevel - 1;
                eLog1MinusVt = obj.expectedValueLogOneMinusStickLengths;
                obj.alphaGammaParams(2) = priorObj.alphaGammaParams(2) - sum(eLog1MinusVt(isfinite(eLog1MinusVt))); % Sometimes there are -infs at the end
            end
        end
        
        function kld = kld(obj, priorObj)
            if obj.useGammaPriorOnScale
                % These beta KLDs are not correct. Really we need to take
                % the expected value of the KLDs over the alpha Gamma
                % density. This is diffucult. Here we use an approximation
                % that may cause a decrease in NFE near convergence.
                betaKlds = zeros(obj.truncationLevel,1);
                for iV = 1:obj.truncationLevel
                    betaKlds(iV) = prtRvUtilDirichletKld(obj.beta(iV,:),priorObj.beta(iV,:));
                end
                
                alphaKld = prtRvUtilGammaKld(obj.alphaGammaParams(1),obj.alphaGammaParams(2),priorObj.alphaGammaParams(1),priorObj.alphaGammaParams(2));
                
                kld = sum(betaKlds) + alphaKld;
            else
                betaKlds = zeros(obj.truncationLevel,1);
                for iV = 1:obj.truncationLevel
                    betaKlds(iV) = prtRvUtilDirichletKld(obj.beta(iV,:),priorObj.beta(iV,:));
                end
                kld = sum(betaKlds);
            end
        end
        
        function [obj, training] = vbOnlineWeightedUpdate(obj, priorObj, x, weights, lambda, D, prevObj) 
            S = size(x,1);
            
            if ~isempty(weights)
                x = bsxfun(@times,x,weights);
            end
            
            localCounts = sum(x,1)';
            
            obj.counts = D/S*localCounts*lambda + (1-lambda)*prevObj.counts + priorObj.counts; % Counts must be updated as a mixture of the prev and the local
            
            if obj.useOptimalSorting
                [~, obj.sortingInds] = sort(obj.counts,'descend'); % We need to sort based on the the updated counts
                [dontNeed, obj.unsortingInds] = sort(obj.sortingInds,'ascend'); %#ok<ASGLU>
            else
                obj.sortingInds = (1:obj.truncationLevel)';
                obj.unsortingInds = obj.sortingInds;
            end
            
            % Update stick parameters
            % To calculate sumIPlus1ToK we sort before we cumsum. Then we
            % unsort the result so that the beta matrix is actually
            % unsorted.
            localCountsSorted = localCounts(obj.sortingInds); % Sort the local counts according to the order of the blended counts
            sumIToK = flipud(cumsum(flipud(localCountsSorted)));
            sumIPlus1ToK = sumIToK-localCountsSorted;
            sumIPlus1ToK = sumIPlus1ToK(obj.unsortingInds);
            
            % We have to sort the previous object the same we that we sort
            % the current object for the purpos of calculating sumIPlus1ToK
            prevCountsSorted = prevObj.counts(obj.sortingInds); % We need to sort the previous counts the same as our current counts are sorted
            prevSumIToK = flipud(cumsum(flipud(prevCountsSorted)));
            prevSumIPlus1ToK = prevSumIToK - prevCountsSorted;
            prevSumIPlus1ToK = prevSumIPlus1ToK(obj.unsortingInds);
            
            % the beta matrix is now totally unsorted but the sorting is
            % done relative to the updated counts
            obj.beta(:,1) = D/S*localCounts*lambda + (1-lambda)*prevObj.counts + priorObj.beta(:,1);
            obj.beta(:,2) = D/S*sumIPlus1ToK*lambda + (1-lambda)*prevSumIPlus1ToK + priorObj.beta(:,2) + obj.expectedValueAlpha;
            
            if obj.useGammaPriorOnScale
                obj.alphaGammaParams(1) = priorObj.alphaGammaParams(1) + obj.truncationLevel - 1;
                eLog1MinusVt = obj.expectedValueLogOneMinusStickLengths;
                obj.alphaGammaParams(2) = priorObj.alphaGammaParams(2) - sum(eLog1MinusVt(isfinite(eLog1MinusVt))); % Sometimes there are -infs at the end
            end

            training = struct([]);
        end
    end
    methods
        function val = get.expectedValueLogStickLengths(obj)
            val = psi(obj.beta(:,1)) - psi(sum(obj.beta,2));
        end
        function val = get.expectedValueLogOneMinusStickLengths(obj)
            val = psi(obj.beta(:,2)) - psi(sum(obj.beta,2));
        end
        function val = get.expectedValueLogProbabilities(obj)
            expectedLogOneMinusStickLengths = obj.expectedValueLogOneMinusStickLengths;
            expectedLogOneMinusStickLengths = expectedLogOneMinusStickLengths(obj.sortingInds);
            
            val = obj.expectedValueLogStickLengths(obj.sortingInds) + cat(1,0,cumsum(expectedLogOneMinusStickLengths(1:end-1)));
            
            val = val(obj.unsortingInds);
            
        end
        function val = get.posteriorMean(obj)
            val = exp(obj.expectedValueLogProbabilities);
        end
        function val = get.truncationLevel(obj)
            val = size(obj.beta,1);
        end
        function val = get.expectedValueAlpha(obj)
            
            alphaParams = obj.alphaGammaParams;
            if length(alphaParams) < 2
                alphaParams = cat(2,1,alphaParams);
            end
            
            val = alphaParams(2)./alphaParams(1);
        end
        
        function self = defaultParameters(self, truncationLevel)
            % Initialize beta
            self.counts = zeros(truncationLevel,1);
            self.beta = ones(truncationLevel,2);
            self.beta(:,2) = self.alphaGammaParams(1)/self.alphaGammaParams(2);
            self.sortingInds = (1:truncationLevel)';
            self.unsortingInds = self.sortingInds;
        end
        function tf = isValid(self)
            tf = ~isempty(self.beta);
        end
    end
end


