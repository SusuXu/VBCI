%% Updating

%% Initialize
close all; clear; clc
tic
%% Import
location = './Italy TN22/';
[Y, Y_R] = readgeoraster(join([location,'DPM2_TN22_CROP.tif']));
[BD, BD_R] = readgeoraster(join([location,'BD_TN22.tif']));
[LS, LS_R] = readgeoraster(join([location,'PLS_TN22.tif']));
[LF, LF_R] = readgeoraster(join([location,'PLF_TN22.tif']));

%% Fix Data Input
BD(BD>0) = 1;
Y(isnan(Y))=0;
BD(isnan(BD))=0;
LS(isnan(LS))=0;
LF(isnan(LF))=0;

%% Convert Landslide Areal Percentages to Probabilities
new_LS = LS;
index = find(LS>0);
for i = index'
    p = [4.035 -3.042 5.237 (-7.592-log(LS(i)))];
    tmp_root = roots(p);
    new_LS(i) = real(tmp_root(imag(tmp_root)==0));
end
disp('Converted Landslide Areal Percentages to Probabilities')
toc

%% Convert Liquefaction Areal Percentages to Probabilities
new_LF = LF;
index = find(LF>0);
for i = index'
    new_LF(i) = (log((sqrt(0.4915./LF(i)) - 1)./42.40))./(-9.165);
end
disp('Converted Liquefaction Areal Percentages to Probabilities')
toc

%% Change into Non-negative Probabilities
new_LF(new_LF<0) = 0;
new_LS(new_LS<0) = 0;
new_LS(isnan(new_LS)) = 0;
new_LF(isnan(new_LF)) = 0;
tmp_LF = new_LF;
tmp_LS = new_LS;

%% Classify Local Model by Pruning
prune_type = 'double';
% sigma = 0;
sigma = median(abs(new_LS((LS>0)&(LF>0)) - new_LF((LS>0)&(LF>0)))); %
LOCAL = pruning(BD,tmp_LS,tmp_LF, sigma, prune_type);
tmp_LS ((LOCAL==5)|(LOCAL==6)) = min(min(new_LS(new_LS>0)));
tmp_LF ((LOCAL==5)|(LOCAL==6)) = min(min(new_LF(new_LF>0)));

%% Set Lambda Term
lambda = 0;

%% Initialize Weight Vector w    
% [w0;weps;w0BD;w0LS;w0LF;wLSBD;wLFBD;wBDy;wLSy;wLFy;weLS;weLF;weBD;waLS;waLF]
w = rand([15,1]);
w([4,5]) = 0;
w([1,3]) = -1.*w([1,3]);
regu_type = 1;  

%% Set Variational hyperparameters
Nq = 10;            % Number of Posterior Probability Iterations

%% Set Weight Updating Parameters
rho = 1e-3;         % Step size
delta = 1e-3;   	% Acceptable tolerance for weight optimization
eps_0 = 0.001;   	% Lower-bound non-negative weight

%% Output
[opt_w, opt_QBD, opt_QLS, opt_QLF, QLS, QLF, QBD, final_loss, best_loss, local] = ...
    SVI(Y,tmp_LS,tmp_LF,w,Nq,rho,delta,eps_0,LOCAL,lambda,regu_type,sigma,prune_type);

%% Convert Probabilities to Areal Percentages
final_QLS = exp(-7.592 + 5.237.*opt_QLS - 3.042*opt_QLS.*opt_QLS + 4.035.*opt_QLS.*opt_QLS.*opt_QLS);
final_QLF = 0.4915./(1+42.40 .* exp(-9.165.*opt_QLF)).^2;

%% Rounddown Very Small Areal Percentages to Zero
final_QLS(final_QLS<=exp(-7.592)) = 0;
final_QLF(final_QLF<=0.4915./(1+42.40).^2) = 0;

%% Remove probabilities in water bodies
final_QLS((LS==0)&(LF==0))=0;
final_QLF((LS==0)&(LF==0))=0;

%% Export GeoTIFF Files
geotiffwrite('QLS.tif', final_QLS, LS_R)
geotiffwrite('QLF.tif', final_QLF, LS_R)
geotiffwrite('QBD.tif', opt_QBD, LS_R)

%% Export All to a File
filename=join([location,'lambda',num2str(lambda), '_sigma',num2str(sigma),'_prune',prune_type,'.mat']);
save(filename);