%% Stochastic Variational Inference

%% Function
function [final_w, final_QBD, final_QLS, final_QLF, QLS, QLF, QBD, final_loss, best_loss, LOCAL] = SVI(Y,LS,LF,w,Nq,rho,delta,eps_0,LOCAL,lambda,regu_type,sigma,prune_type)

%%  Initialize
    QBD = 0.001*rand([size(Y,1),size(Y,2)]);
    QLS = LS;
    QLF = LF;
    loss = 1e+5;
    loss_old = 0;
    best_loss = -1e+4;
    final_loss = [];
    grad = zeros(numel(w),1);
    tic
    epoches = 0;

    % Compute the alpha that relates to prior LS and LF estimates
    t_alLS = log(LS ./ (1-LS) );
    t_alLF = log(LF ./ (1-LF) );
    t_alLS(t_alLS<-6) = -6;
    t_alLF(t_alLF<-6) = -6;
    t_alLS(t_alLS>6) = 6;
    t_alLF(t_alLF>6) = 6;
	final_w = w;
    
    % Set a custom stopping function
    myConditionFunc = [];
    if sum(sum(LOCAL>=5))==0
        myConditionFunc = @(x,y)y > 0;
    else
        myConditionFunc = @(x,y)(x > 0) || (y > 0);
    end

%%  Main
while (epoches<30) && myConditionFunc(sum(sum(LOCAL==5)),abs(loss_old-loss)-eps_0)
    
    % Create a sample batch of locations with size 'bsize'
	totalnum = size(Y,2)*size(Y,1);
    bsize = 500;
    bnum = floor(totalnum./bsize);
    iD_sample = randsample(numel(Y),numel(Y));
    iD = reshape(iD_sample(1:bnum*bsize),bsize,[]);
    
    % Reset the loss parameters
    loss_old = loss;
    loss = 0;
    eloss = 0;
    tmp_final_loss = [];
    
	% Set learning rate decay
    if (mod(epoches, 10)==0)&&(epoches>1)
        rho = max(rho*0.1,1e-4);
    end 
    
    % Run for each sample batch with size 'bsize'
    for i = 1:bnum
        
        % Store the ith bacth in a set of variables
        y = Y(iD(:,i));
        qBD = QBD(iD(:,i));
        qLS = QLS(iD(:,i));
        qLF = QLF(iD(:,i));
        local = LOCAL(iD(:,i));
        alLS = t_alLS(iD(:,i));
        alLF = t_alLF(iD(:,i));

            % Iteration
            for nq = 1:Nq
                
                % Apply the nonlinear T function
                q = 1./(1+exp(-Tfxn(y, qBD, qLS, qLF, alLS, alLF, w, local, delta)));
                qBD = q(:,1);
                qLS = q(:,2);
                qLF = q(:,3);
        
                % Apply the pruning 
                qBD(local < 3) = 0;
                qBD(local == 5) = 0;
                qLS(local==0|local==2|local==4) = 0;
                qLF(local==0|local==1|local==3) = 0;

                % Remove very negligible estimates
                qLS(qLS<1e-6) = 0;
                qLF(qLF<1e-6) = 0;

                % Apply the sigma that relates to the difference 
                % between posterior LS and LF estimates
                tqLS = qLS;
                tqLF = qLF;
                if prune_type == "single"
                    qLS(tqLS<tqLF-sigma) = 0;
                    qLF(tqLF<tqLS) = 0;
                else
                    qLS(tqLS<tqLF-sigma) = 0;
                    qLF(tqLF<tqLS-sigma) = 0;
                end

                % Join the posterior estimates of each ith sample batch
                % to the main map with proper location indices
                QBD(iD(:,i)) = qBD;
                QLS(iD(:,i)) = qLS;
                QLF(iD(:,i)) = qLF;
                
            end
        
            % Classify new local model by pruning
            if sum(local>=5)>0
                if prune_type == "single"
                    local((tqLF<tqLS)&(local==5)) = 1;
                    local((tqLF<tqLS)&(local==6)) = 3;
                    local((tqLS<tqLF-sigma)&(local==5)) = 2;
                    local((tqLS<tqLF-sigma)&(local==6)) = 4;
                else 
                    local((tqLF<tqLS-sigma)&(local==5)) = 1;
                    local((tqLF<tqLS-sigma)&(local==6)) = 3;
                    local((tqLS<tqLF-sigma)&(local==5)) = 2;
                    local((tqLS<tqLF-sigma)&(local==6)) = 4;
                end
                LOCAL(iD(:,i)) = local;
            end
        
        
        % Compute the partial derivative
        identity = [local>=0, local>=0, local==3|local==4|local==5, local==1|local==3|local==5|local==6,...
                    local==2|local==4|local==5|local==6, local==3|local==6, local==4|local==6, local==3|local==4|local==6,...
                    local==1|local==3|local==5|local==6, local==2|local==4|local==5|local==6, local==1|local==3|local==5|local==6, ...
                    local==2|local==4|local==5|local==6, local==3|local==4|local==6, local==1|local==3|local==5|local==6, local==2|local==4|local==5|local==6];
        grad_D = parder(y, qBD, qLS, qLF, alLS, alLF, w, local);
        tmp_count = sum(identity);
        grad = ((sum(identity.*grad_D))./tmp_count)';
        grad(tmp_count==0) = 0;

        % Compute the regularization
        if regu_type == 1
            regu_grad = lambda .*100 .* (1./(1 + exp(-0.01.*w)) - 1./(1 + exp(0.01.*w)));
            grad([8,9,10]) = grad([8,9,10]) - regu_grad([8,9,10]);
        else
            regu_grad = lambda .*100 .* (1./(1 + exp(-0.01.*w)) - 1./(1 + exp(0.01.*w)));
            grad([14, 15]) = grad([14, 15]) - regu_grad([14, 15]);
        end

        % Compute the new weight
        wnext = w+rho.*grad;
        wnext([1,3]) = min(wnext([1,3]), (-1e-6).*ones(2,1));
        wnext([14,15]) = max(0, wnext([14,15]));
        wnext(2) = min(max(wnext(2), 1e-3),1);

        % Compute the loss
        tmp_loss = mean(Loss(y, qBD, qLS, qLF, alLS, alLF, wnext, local, delta));
        loss = loss + tmp_loss;
        if mod(i, 20) == 0
            tmp_final_loss = [tmp_final_loss; tmp_loss];
        end
        if mod(i, 100) == 0
            c_loss = mean(Loss(Y(:), QBD(:), QLS(:), QLF(:), t_alLS(:), t_alLF(:), wnext, LOCAL(:), delta));
            if c_loss > best_loss
                final_QLS = QLS;
                final_QLF = QLF;
                final_QBD = QBD;
                final_w = wnext;
                best_loss = c_loss;
            end
        end

        % Assign the new weight
        w = wnext;
        
    end 
    
    % Show progress
    display(["epoch loss is", loss./bnum])
    epoches  = epoches + 1
    final_loss = [final_loss; tmp_final_loss];
    toc

end
end

