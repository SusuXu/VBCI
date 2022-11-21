function [acc] = rocdetpr(title,prio,post,gtruth,location)

% Note
% The ROC and DET curves are generated using thresholds that are dictated
% by the ith quantile because of (1) the difference in magnitude of values of
% prior and posterior estimates and (2) no single value can threshold prior
% and posterior estimates fairly.
acc = [];
ith_percentile = 0:0.01:1;

for l = ith_percentile
    
    % Compute TPR, FPT, TNR, FNR
    prio_thresh = quantile(prio(:),l);
    post_thresh = quantile(post(:),l);
    [prio_TPR,prio_FPR,prio_TNR,prio_FNR,prio_PRE,  ...
	 post_TPR,post_FPR,post_TNR,post_FNR,post_PRE]   ...
     = binaryerror(prio,post,gtruth,prio_thresh,post_thresh);

    % Count the prior estimates above the threshold set
    tmp_prio = prio;
 	tmp_prio(prio<prio_thresh) = 0;
    tmp_p_c = sum(sum(tmp_prio>0));
    
    % Count the posterior estimates above the threshold set
    tmp_post = post;
	tmp_post(post<post_thresh) = 0;
    tmp_q_c = sum(sum(tmp_post>0));
    
    % Append
    tmp_acc = [ tmp_p_c,tmp_q_c,                                ...
                prio_TPR,prio_FPR,prio_TNR,prio_FNR,prio_PRE,	...
                post_TPR,post_FPR,post_TNR,post_FNR,post_PRE];
    acc = [acc;tmp_acc];
    disp(l)
    toc
end

fig1 = figure(1);
plot(acc(:,4), acc(:,3), 'linewidth', 1.5);
hold on
plot(acc(:,9), acc(:,8), 'linewidth', 1.5);
hold off
xlabel('False Positive Rate','FontSize',10);
ylabel('True Positive Rate','FontSize',10);
legend('Prior','Posterior','FontSize',10,'Location','southeast');
round(min(max(acc(:,4)),max(acc(:,9))),2,'significant')
xlim([0 0.5])
ylim([0 1])
grid on
grid minor
saveas(fig1, join([location,title,'_ROC.png']))

fig2 = figure(2);
loglog(acc(:,4), acc(:,6), 'linewidth', 1.5);
hold on
loglog(acc(:,9), acc(:,11), 'linewidth', 1.5);
hold off
xlabel('False Positive Rate','FontSize',10);
ylabel('False Negative Rate','FontSize',10);
legend('Prior','Posterior','FontSize',10,'Location','southwest');
xlim([0 1])
ylim([0 1])
grid on
grid minor
saveas(fig2, join([location,title,'_DET.png']))

fig3 = figure(3);
plot(acc(:,3), acc(:,7), 'linewidth', 1.5);
hold on
plot(acc(:,8), acc(:,12), 'linewidth', 1.5);
hold off
xlabel('Recall','FontSize',10);
ylabel('Precision','FontSize',10);
legend('Prior','Posterior','FontSize',10,'Location','northeast');
xlim([0.15 0.6])
ylim([1e-4 7e-4])
grid on
grid minor
saveas(fig3, join([location,title,'_PR.png']))

end

