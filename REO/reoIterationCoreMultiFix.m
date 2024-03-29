function [Tcalc, Dcalc] = reoIterationCoreMultiFix(hLib, Mmap, freqs, Robs, Lobs, Hfixed, Tfixed, Ht1, Ht2, Hc, Tc, NTv, masks, posR, posL, step, diagr, param, plotsInfo, plotFunc)

% Robs, Lobs: npos x nfreqs
% pos*: 1 x npos
% Hmodel, Tmodel: nmasks x nheight_model
% Hbase: 1 x nheight_base
% Tbase: nmasks x nheight_base
% Hc: 1 x nheight_var
% Tc: nmasks x nheight_var
% masks(n).mask

Tcalc = zeros(size(Tc));
Dcalc = zeros(size(Tc));

npos = length(posR);
nreg = length(masks);
nfreqs = length(freqs);
nheights = size(Hc, 2);

nNT = 1;
NT = NTv(:, nNT);

outCntres = zeros(size(NTv, 2));
outCntNT = zeros(size(NTv, 2));
outRes = zeros(size(NTv, 2));

ticID = tic;

resRv = [];
resLv = [];
Tprev = Tc;
%Tinit = Tc;
% relax = param.relax;
relax = 1;
cntres = 0;
cntNT = 0;
resprev = 0;
x = ones(nreg, nheights);
zeroH = false(nreg, nheights);
while true    
    Hcalc = Hc;
    for km = 1:nreg
        Tc(km, :) = x(km, :).*Tc(km, :);
%         if cntNT > param.relaxStart
%             Tc(km, :) = exp(relax*log(Tc(km, :)) + (1-relax)*log(Tprev(km, :)));
%         end
        Tcx = Tc(km, :);
        Tcx(Tcx < param.Tmin(km)) = param.Tmin(km);
        Tc(km, :) = Tcx;
        %Tc(km, zeroH(km, :)) = param.Tmin(km);
        Tc(km, Hfixed(km, :)) = Tfixed(km, Hfixed(km, :));
        Tprev(km, :) = Tc(km, :);
    
        Tcalc(km, :) = Tc(km, :);
        Dcalc(km, :) = l_barometric(Hcalc, Tcalc(km, :), NT(km), param);
    end
    
    Rcalc = zeros(npos, nfreqs);
    Lcalc = zeros(npos, nfreqs);
    R = zeros(npos, nfreqs, nheights, nreg, max(param.harms)+1);
    L = zeros(npos, nfreqs, nheights, nreg, max(param.harms)+1);
    Rcnt = zeros(npos, nfreqs, nheights, nreg, max(param.harms)+1);
    Lcnt = zeros(npos, nfreqs, nheights, nreg, max(param.harms)+1);

    Rns = zeros(nfreqs, nheights);
    Lns = zeros(nfreqs, nheights);

    % profile on
    
    for kf = 1:length(freqs)
        tfR = zeros(Mmap);
        tfL = zeros(Mmap);
        tfwR = zeros(Mmap);
        tfwL = zeros(Mmap);
        thR = zeros(Mmap(1), Mmap(2), nreg);
        thL = zeros(Mmap(1), Mmap(2), nreg);
        tsR = zeros(Mmap(1), Mmap(2), nreg);
        tsL = zeros(Mmap(1), Mmap(2), nreg);
        tic
        for km = 1:nreg
            [depthRight, pFRight, pTauRight, pHLRight, pFLRight, psLRight, ...
             depthLeft, pFLeft, pTauLeft, pHLLeft, pFLLeft, psLLeft] = ...
                     reoCalculate(hLib, Hcalc, Tcalc(km, :), Dcalc(km, :), freqs(kf), param.harms, param.pTauL, masks(km).mask, true);
            tfwRm = pFRight;
            tfRm = pFLRight(:,:,param.dunit);
            tfwLm = pFLeft;
            tfLm = pFLLeft(:,:,param.dunit);

            tfwR = tfwR + tfwRm;
            tfR = tfR + tfRm;
            thR(:,:,km) = pHLRight(:,:,param.dunit);
            tsR(:,:,km) = psLRight(:,:,param.dunit)+1;

            tfwL = tfwL + tfwLm;
            tfL = tfL + tfLm;
            thL(:,:,km) = pHLLeft(:,:,param.dunit);
            tsL(:,:,km) = psLLeft(:,:,param.dunit)+1;
        end
        toc
        tic
        for kp = 1:npos
            vR = gstMapMult(tfR, diagr.H(kf, :), diagr.V(kf, :), step, posR(kp));
            vL = gstMapMult(tfL, diagr.H(kf, :), diagr.V(kf, :), step, posL(kp));
            
            Rcalc(kp, kf) = sum(sum(gstMapMult(tfwR, diagr.H(kf, :), diagr.V(kf, :), step, posR(kp))));
            Lcalc(kp, kf) = sum(sum(gstMapMult(tfwL, diagr.H(kf, :), diagr.V(kf, :), step, posL(kp))));
            
            for km = 1:nreg
                for i = 1:size(vR, 1)
                    for j = 1:size(vR, 2)
                        for kh = 1:nheights
                            if masks(km).mask(i,j)
                                if Ht1(kh) <= thR(i,j,km) && thR(i,j,km) < Ht2(kh) && vR(i,j) ~= 0
                                    R(kp,kf,kh,km,tsR(i,j,km)) = R(kp,kf,kh,km,tsR(i,j,km)) + vR(i,j);
                                    Rns(kf,kh) = Rns(kf,kh) + vR(i,j);
                                    Rcnt(kp, kf, kh, km, tsR(i,j,km)) = Rcnt(kp, kf, kh, km, tsR(i,j,km)) + 1;
                                end
                                if Ht1(kh) <= thL(i,j,km) && thL(i,j,km) < Ht2(kh) && vL(i,j) ~= 0
                                    L(kp,kf,kh,km,tsL(i,j,km)) = L(kp,kf,kh,km,tsL(i,j,km)) + vL(i,j);
                                    Lns(kf,kh) = Lns(kf,kh) + vL(i,j);
                                    Lcnt(kp, kf, kh, km, tsL(i,j,km)) = Lcnt(kp, kf, kh, km, tsL(i,j,km)) + 1;
                                end
                            end
                        end
                    end
                end
            end
        end
        toc
    end
    
    % profile viewer
    
    resR = sqrt(sum(sum((Robs-Rcalc).^2)));
    resRrel = resR/sum(sum(Robs));
    resL = sqrt(sum(sum((Lobs-Lcalc).^2)));
    resLrel = resL/sum(sum(Lobs));
    resRv = [resRv resRrel];
    resLv = [resLv resLrel];
    resS = resRrel + resLrel;
    if abs(resS - resprev)/resS < param.reslim || resS < param.resabslim
        cntres = cntres + 1;
    else
        cntres = 0;
    end
    if cntres >= param.rescntstab || cntNT >= param.rescntmax
        disp(['*CNT=' num2str(nNT) ' cntStable=' num2str(cntres) ' cntNT=' num2str(cntNT) ' res=' num2str(resS) ' t=' srvSecToDisp(toc(ticID))]);
        outCntres(nNT) = cntres;
        outCntNT(nNT) = cntNT;
        outRes(nNT) = resS;
        
        if nNT >= size(NTv, 2)
            break
        end
        nNT = nNT + 1;
        NT = NTv(:, nNT);
        cntres = 0;
        cntNT = 0;
        ticID = tic;
    end
    resprev = resS;
    cntNT = cntNT + 1;
    disp(['  cntStable=' num2str(cntres) ' cntNT=' num2str(cntNT) ' res=' num2str(resS) ' t=' srvSecToDisp(toc(ticID))]);
    if cntNT == 1
        disp(num2str(xsumrem(Rcnt, [2 3 5])))
        disp(num2str(xsumrem(Lcnt, [2 3 5])))
    end
    
    plotsInfo = feval(plotFunc, plotsInfo, Hcalc, Tcalc, Rcalc, Lcalc, Rcnt, Lcnt, resRv, resLv, cntNT, x);
    
    ncols = nreg*nheights;
    
    Mall = zeros(2*nfreqs*npos, ncols);
    Fall = zeros(2*nfreqs*npos, 1);
    Wall = ones(2*nfreqs*npos, 1);

    exclFixed = false(1, ncols);
    for km = 1:nreg
        for kh = 1:nheights
            exclFixed(kh+(km-1)*nheights) = Hfixed(km, kh);
        end
    end
    
    exclFreqs = false(2*npos*nfreqs, 1);
disp('-------------------------------------------------------')
    for mode = 1:2
        V = sum(srvPick(mode == 1, R, L), 5);
        Vo = srvPick(mode == 1, Robs, Lobs);
        Vc = srvPick(mode == 1, Rcalc, Lcalc);
        Vw = srvPick(mode == 1, param.wR, param.wL)*param.wFreq;
        for kp = 1:npos
            for kf = 1:nfreqs
                row = kf+((kp-1)+(mode-1)*nfreqs)*npos;
                for km = 1:nreg
                    for kh = 1:nheights
                        Mall(row, kh+(km-1)*nheights) = V(kp,kf,kh,km);
                    end
                end
                Vnocalc = 0;
                Vnocalcrel = 0;
                thick = sum(Mall(row, :));
                exclSmall = false(1, ncols);
                if thick == 0 || thick < max(Vo(kp, :))*param.part_from_max
                    exclFreqs(row) = true;
                else
                    for kr = 1:nreg
                        exclSmallreg = false(1, nheights);
                        range = (kr-1)*nheights + (1:nheights);
%                         thick = sum(Mall(row, range));
%                         thickrel = Mall(row, range)/thick;
%                         wherethick = find(thickrel > param.thick_lim, 1);
%                         if ~isempty(wherethick)
%                             exclSmallreg(1:wherethick(1)-1) = true;
%                         end
                        exclSmall(range) = exclSmallreg;
                    end
                    exclM = exclSmall | exclFixed;
                    exclF = sum(Mall(row, exclM));
                    thin = Vc(kp, kf) - sum(Mall(row, :));
                    Vnocalc = thin + exclF;
                    Vnocalcrel = Vnocalc/Vc(kp, kf);
                    if Vnocalcrel > param.thin_lim
                        Mall(row, exclM) = 0;
                        Fall(row) = max([0, Vo(kp, kf) - Vnocalc]);
                    else
                        exclFreqs(row) = true;
                    end
                end
                disp(['m=' num2str(mode) ',kp=' num2str(kp), 'kf(f)=' num2str(kf) '(' num2str(freqs(kf)/1e9) ...
                      '), excl=' num2str(exclFreqs(row)) ', ncalc=' num2str(Vnocalc) ', Fall=' num2str(Fall(row)) ', part=' num2str(Vnocalcrel*100) ', exclSmall=' num2str(find(exclSmall))])
                Wall(row) = Vw(kp, kf);
            end
        end
    end
    
    for row = 1:size(Mall)
        if sum(Mall(row,:)) == 0
            v = zeros(1, size(Mall, 2));
        else
            v = Mall(row, :)/sum(Mall(row,:));
        end
        disp([num2str(row, '%02d') ' excl=' num2str(exclFreqs(row)) ': ' num2str(v*100, '%5.1f ') ' F = ' num2str(Fall(row))])
    end
    
    for kh = size(Mall,1):-1:1
        if all(Mall(kh, :) == 0) || Wall(kh) == 0
            Mall(kh, :) = [];
            Fall(kh) = [];
            Wall(kh) = [];
        end
    end
    
    exclZero = false(1, ncols);
    for kc = 1:size(Mall,2)
        if all(Mall(:, kc) == 0)
            exclZero(kc) = true;
        end
    end

    exclAll = exclFixed | exclZero;
    
    sm = sum(sum(Mall))/numel(Mall(Mall > 0));
    
    FT = zeros(nreg*nheights, 1);
    MT = zeros(nreg*nheights, ncols);
    WT = ones(nreg*nheights, 1);
    for km = 1:nreg
        for kh = 1:nheights
            pos = kh+(km-1)*nheights;
%             if kh == 1 
%                 MT(pos, pos) = Tc(km, kh);
%                 FT(pos) = param.Tmin(km);
%             else
%                 if ~exclM(pos)
%                     if exclM(pos-1)
%                         MT(pos, pos) = Tc(km, kh);
%                         FT(pos) = Tfixed(km, kh-1);
%                     else
%                         MT(pos, pos-1:pos) = [Tc(km, kh-1) -Tc(km, kh)];
%                     end
%                 end
%             end
            if kh > 1 && ~exclAll(pos-1) && ~exclAll(pos)
                MT(pos, pos-1:pos) = [Tc(km, kh-1) -Tc(km, kh)];
            end
            WT(pos) = param.wTemp*param.wT(km, kh); 
        end
    end
    for kh = size(MT,1):-1:1
        if all(MT(kh, :) == 0) || WT(kh) == 0
            MT(kh, :) = [];
            FT(kh) = [];
            WT(kh) = [];
        end
    end
    MT = MT*sm*1e-6;
    FT = FT*sm*1e-6;

    Mall = [Mall; MT];
    Fall = [Fall; FT];
    Wall = [Wall; WT];

%     E = zeros(nheights, nheights, nmasks);
%     Z = zeros(nheights, nheights);
%     for km = 1:nmasks
%         E(:, :, km) = diag(Tc(km, :));
%     end
%     
%     DF = zeros(nheights, 1);
%     DW = ones(nheights, 1)*param.wCross;
%     for km = 1:nmasks-1
%         Mall = [Mall; repmat(Z, [1 km-1]) E(:,:,km) -E(:,:,km+1) repmat(Z, [1 nmasks-km-1])];
%         Fall = [Fall; DF];
%         Wall = [Wall; DW];
%     end
    
    Mall(:, exclAll) = [];
    
    xx = lscov(Mall, Fall, Wall);
    xx = min(param.expMax, max(xx, param.expMin));
    xxx = zeros(pos);
    xxx(~exclAll) = xx;
    
    x = ones(nreg, nheights);
    for km = 1:nreg
        for kh = 1:nheights
            pos = kh+(km-1)*nheights;
            if ~exclAll(pos)
                x(km, kh) = xxx(pos);
            end
        end
    end
%     zeroH = false(nreg, nheights);
%     x = ones(nreg, nheights);
%     for km = 1:nreg
%         for kh = 1:nheights
%             pos = kh+(km-1)*nheights;
%             if ~exclAll(pos)
%                 x(km, kh) = xxx(pos);
%             else
%                 zeroH(km, kh) = true;
%             end
%         end
%     end
end

end

%--------------------------------------------------------------------------
function Dcalc = l_barometric(Hcalc, Tcalc, NT, param)

if ~param.barometric
    Dcalc = NT./Tcalc;
else
    NTx = NT*ones(1, length(Tcalc));
    
    idx = find(Tcalc > 3e5);
    if ~isempty(idx)
        H0 = Hcalc(idx(1));
        NTx(idx(1):end) = NT*exp(-(Hcalc(idx(1):end)-H0)/4.5e3./Tcalc(idx(1):end));
    end
    
    Dcalc = NTx./Tcalc;
end

end

%--------------------------------------------------------------------------
function [tfw, tf] = l_give4mask(mask, pF, pFL, ~, ~, param)

tfw = pF;
tfw(~mask) = 0;
tf = pFL(:,:,param.dunit);
tf(~mask) = 0;

end

% %--------------------------------------------------------------------------
% function [use, useFF] = l_checkUse(mask, ps, param)
% 
% p = sum(ps(:, :, 1:param.dunit), 3);
% use = mask & p > 0;
% % useFF = mask & sum(ps, 3) == 0;
% useFF = false(size(mask));
% 
% end
% 
% %--------------------------------------------------------------------------
% function [tfw, tf] = l_give4mask(mask, pF, pFL, psL, pFFF, param)
% 
% [use, useFF] = l_checkUse(mask, psL, param);
% tfw = pF;
% tfw(~use) = 0;
% t = pF;
% t(~useFF) = 0;
% t(useFF) = t(useFF)-pFFF;
% tfw = tfw + t;
% tf = pFL(:,:,param.dunit);
% tf(~use) = 0;
% t = pFL(:,:,param.dunit);
% t(~useFF) = 0;
% t(useFF) = t(useFF)-pFFF;
% tf = tf + t;
% 
% end
