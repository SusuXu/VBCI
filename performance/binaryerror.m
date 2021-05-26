function [prio_TPR,prio_FPR,prio_TNR,prio_FNR,prio_PRE,post_TPR,post_FPR,post_TNR,post_FNR,post_PRE] = binaryerror(prio,post,gtruth,prio_thresh,post_thresh)

% Guide
% True Positive (TP) - with groundtruth and positive prediction
% True Negative (TN) - no groundtruth and negative prediction
% False Negative (FN) - with groundtruth and negative prediction
% False Positive (FP) - no groundtruth and positive prediction

% Note
% The ROC Curve provides a TPR, FPR, TNR, and FNR for all thresholds. In
% this function, we are only considering zero as the thresholding value.

% Compute TP, TN, FN, and FP
prio_TP = sum(sum(( (gtruth == 1) & (prio > prio_thresh) )));
prio_TN = sum(sum(( (gtruth == 0) & (prio <= prio_thresh) )));
prio_FN = sum(sum(( (gtruth == 1) & (prio <= prio_thresh) )));
prio_FP = sum(sum(( (gtruth == 0) & (prio > prio_thresh) )));
post_TP = sum(sum(( (gtruth == 1) & (post > post_thresh) )));
post_TN = sum(sum(( (gtruth == 0) & (post <= post_thresh) )));
post_FN = sum(sum(( (gtruth == 1) & (post <= post_thresh) )));
post_FP = sum(sum(( (gtruth == 0) & (post > post_thresh) )));

% Compute TPR (aka. sensitivity or recall)
prio_TPR = prio_TP / (prio_TP + prio_FN);
post_TPR = post_TP / (post_TP + post_FN);

% Compute FPR
prio_FPR = prio_FP / (prio_FP + prio_TN);
post_FPR = post_FP / (post_FP + post_TN);

% Compute TNR (aka. specificity)
prio_TNR = prio_TN / (prio_TN + prio_FP);
post_TNR = post_TN / (post_TN + post_FP);

% Compute FNR (aka. miss rate)
prio_FNR = prio_FN / (prio_FN + prio_TP);
post_FNR = post_FN / (post_FN + post_TP);

% Compute PRE
prio_PRE = prio_TP / (prio_TP + prio_FP);
post_PRE = post_TP / (post_TP + post_FP);

end

