function [ploss,qloss] = cel(prio,post,gtruth)

tmp_prio = mat2gray(prio);
tmp_prio(tmp_prio==1) = 1-1e-6;
tmp_prio(tmp_prio==0) = 1e-6;
ploss = -(mean(mean(gtruth.*log(tmp_prio) + (1-gtruth).*log(1-tmp_prio))));

tmp_post = mat2gray(post);
tmp_post(tmp_post==1) = 1-1e-6;
tmp_post(tmp_post==0) = 1e-6;
qloss = -(mean(mean(gtruth.*log(tmp_post) + (1-gtruth).*log(1-tmp_post))));

end

