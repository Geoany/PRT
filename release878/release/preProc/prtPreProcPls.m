classdef prtPreProcPls < prtPreProcClass
    % prtPreProcPls   Partial least squares
    %
    %   PCA = prtPreProcPls creates a partial least-squares pre-processing
    %   object.
    %
    %   PCA = prtPreProcPls('nComponents',N) constructs a
    %   prtPreProcPCP object PCA with nComponents set to the value N.
    %
    %   A prtPreProcPls object has the following properites:
    % 
    %    nComponenets    - The number of principle componenets
    %
    %   A prtPreProcPls object also inherits all properties and functions from
    %   the prtAction class
    %
    %   Example:
    %
    %   dataSet = prtDataGenUnimodal;  
    %   pls = prtPreProcPls;           
    %                        
    %   pls = pls.train(dataSet);     
    %   dataSetNew = pls.run(dataSet);
    % 
    %   subplot(2,1,1); plot(dataSet);
    %   title('Original Data');
    %   subplot(2,1,2); plot(dataSetNew);
    %   title('PLS Projected Data');
    %
    %   See Also: prtPreProc,
    %   prtOutlierRemoval,prtPreProcNstdOutlierRemove,
    %   prtOutlierRemovalMissingData,
    %   prtPreProcNstdOutlierRemoveTrainingOnly, prtOutlierRemovalNStd,
    %   prtPreProcPca, prtPreProcPls, prtPreProcHistEq,
    %   prtPreProcZeroMeanColumns, prtPreProcLda, prtPreProcZeroMeanRows,
    %   prtPreProcLogDisc, prtPreProcZmuv, prtPreProcMinMaxRows                    
        
    properties (SetAccess=private)
        name = 'Partial Least Squares' % Partial Least Squares
        nameAbbreviation = 'PLS' % PLS
    end
    
    properties
        nComponents = 2;   % The number of Pls components
    end
    properties (SetAccess=private)
        % General Classifier Properties
        projectionMatrix = [];
        xMeanVector = [];
        yMeanVector = [];
    end
    
    methods
        
          % Allow for string, value pairs
        function Obj = prtPreProcPls(varargin)
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
    end
    
    methods
        function Obj = set.nComponents(Obj,nComp)
            if ~prtUtilIsPositiveScalarInteger(nComp);
                error('prt:prtPreProcPls','nComponents must be a positive scalar integer.');
            end
            Obj.nComponents = nComp;
        end
    end
    
    methods (Hidden = true)
        function featureNames = updateFeatureNames(obj,featureNames) %#ok<MANU>
            for i = 1:length(featureNames)
                featureNames{i} = sprintf('PLS Score %d',i);
            end
        end
    end
    
    methods (Access=protected,Hidden=true)
        
        function Obj = trainAction(Obj,DataSet)
            
            X = DataSet.getObservations;
            if DataSet.nClasses > 2
                Y = DataSet.getTargetsAsBinaryMatrix;
            else
                Y = DataSet.getTargetsAsBinaryMatrix;
                Y = Y(:,2); %0's and 1's for H1
            end
            
            maxComps = min(size(X));
            if Obj.nComponents > maxComps;
                warning('prt:prtPreProcPls','nComponents (%d) > maximum components for the data set (%d); setting nComponents = %d',Obj.nComponents,maxComps,maxComps);
                Obj.nComponents = maxComps;
            end
            
            Obj.xMeanVector = mean(X,1);
            Obj.yMeanVector = mean(Y,1);
            X = bsxfun(@minus, X, Obj.xMeanVector);
            Y = bsxfun(@minus, Y, Obj.yMeanVector);
            
            [~,~, P] = prtUtilSimpls(X,Y,Obj.nComponents);
            
            Obj.projectionMatrix = pinv(P');
            Obj.projectionMatrix = bsxfun(@rdivide,Obj.projectionMatrix,sqrt(sum(Obj.projectionMatrix.^2,1)));
        end
        
        function DataSet = runAction(Obj,DataSet)
            X = DataSet.getObservations;
            X = bsxfun(@minus,X,Obj.xMeanVector);
            DataSet = DataSet.setObservations(X*Obj.projectionMatrix);
        end
    end
end