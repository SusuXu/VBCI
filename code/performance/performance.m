%% Performance

% TPR - true positive rate
% FPR - false positive rate
% TNR - true negative rate
% FNR - false negative rate
% CEL - cross-entropy loss
% ROC - receiver operating characteristics curve
% DET - detection error trade-off curve

%% Initialize
close all; clear; clc

%% Import
location = './Ridgecrest/';
filename = join([location,'lambda0_sigma0.07047_prunedouble.mat']);
load(filename)                                                          % contains prior and posterior estimates

%% Declare variables

    % Landslide
    PLS = LS;
    QLS = imfilter(final_QLS, fspecial('disk', 3));
    [GTLS, GTLS_R] = readgeoraster('Ridgecrest/LS_groundtruth_ridgecrest_nasa_nodata.tif');	% landslide groundtruth

    % Liquefaction
    PLF = LF;
    QLF = imfilter(final_QLF, fspecial('average', [3 3]));
    [GTLF, GTLF_R] = readgeoraster('Ridgecrest/LF_groundtruth_ridgecrest_nasa_nodata.tif');   % liquefaction groundtruth

%% Compute TPR, FPR, TNR, FNR
    
    prio_thresh = 0;
    post_thresh = 0;
    
    % Landslide
    [PLS_TPR,PLS_FPR,PLS_TNR,PLS_FNR,   ...
     QLS_TPR,QLS_FPR,QLS_TNR,QLS_FNR]   ...
    = binaryerror(PLS,QLS,GTLS,prio_thresh,post_thresh);

    % Liquefaction
    [PLF_TPR,PLF_FPR,PLF_TNR,PLF_FNR,   ...
     QLF_TPR,QLF_FPR,QLF_TNR,QLF_FNR]   ...
    = binaryerror(PLF,QLF,GTLF,prio_thresh,post_thresh);

%% Compute CEL
    
    % Landslide
    [ploss_LS, qloss_LS] = cel(PLS,QLS,GTLS);

    % Liquefaction
    [ploss_LF, qloss_LF] = cel(PLF,QLF,GTLF);
    
%% Generate ROC, DET

    % Landslide
    rocdet_LS = rocdetpr('Landslide',PLS,QLS,GTLS,location);
    
    % Liquefaction
    rocdet_LF = rocdetpr('Liquefaction',PLF,QLF,GTLF,location);

%% Save File
filename=join([location,'performance.mat']);
save(filename);