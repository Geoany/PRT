%% prtDataGenMary
% This data generation method can be used to generate a default multiple
% hypothesis (M-ary) data set for classification.  The output data set has
% 3 hypothesis, 2 feature dimensions, and elements from the three classes
% are drawn from one of three Gaussian distributions.
%
% The output of this function is a prtDataSetClass.
%
% <matlab:doc('prtDataGenMary') M-file documentation>
%
% <prtPublishDataGen.html prtDataGen Functions>
%
% <prtPublishGettingStarted.html Getting Started> 
%

ds = prtDataGenMary;
plot(ds);

%%
% See also: 
% <prtPublishDataGenBimodal.html prtDataGenBimodal>
% <prtPublishDataGenCircles.html prtDataGenCircles>
% <prtPublishDataGenIris.html prtDataGenIris>
% <prtPublishDataGenManual.html prtDataGenManual>
% <prtPublishDataGenMary.html prtDataGenMary>
% <prtPublishDataGenNoisySinc.html prtDataGenNoisySinc>
% <prtPublishDataGenOldFaithful.html prtDataGenOldFaithful>
% <prtPublishDataGenPca.html prtDataGenPca>
% <prtPublishDataGenProstate.html prtDataGenProstate>
% <prtPublishDataGenSinc.html prtDataGenSinc>
% <prtPublishDataGenSpiral.html prtDataGenSpiral>
% <prtPublishDataGenSpiral3.html prtDataGenSpiral3>
% <prtPublishDataGenSwissRoll.html prtDataGenSwissRoll>
% <prtPublishDataGenUnimodal.html prtDataGenUnimodal>
% <prtPublishDataGenXor.html prtDataGenXor>
% <prtPublishDataGenBimodal prtDataGenBimodal>
% <prtPublishDataGenCircles prtDataGenCircles>
% <prtPublishDataGenIris prtDataGenIris>
% <prtPublishDataGenManual prtDataGenManual>
% <prtPublishDataGenMary prtDataGenMary>
% <prtPublishDataGenNoisySinc prtDataGenNoisySinc>
% <prtPublishDataGenOldFaithful prtDataGenOldFaithful>
% <prtPublishDataGenPca prtDataGenPca>
% <prtPublishDataGenProstate prtDataGenProstate>
% <prtPublishDataGenSinc prtDataGenSinc>
% <prtPublishDataGenSpiral prtDataGenSpiral>
% <prtPublishDataGenSpiral3 prtDataGenSpiral3>
% <prtPublishDataGenSwissRoll prtDataGenSwissRoll>
% <prtPublishDataGenUnimodal prtDataGenUnimodal>
% <prtPublishDataGenXor prtDataGenXor>