function [vk, rck, hk, zk, sik, OCV] = simCell(ik, T, deltaT, model, z0, iR0, h0)
    ik = ik(:);
    RCfact = exp(-deltaT ./ abs(getParamESC('RCParam', T, model)))';
    Q = getParamESC('QParam', T, model);
    etaParam = 0.995;
    G = 0.01;
    M = 0.1;
    M0 = 0.01;
    RParam = 0.005;
    R0Param = 0.01;

    etaik = ik;
    etaik(ik < 0) = etaParam * ik(ik < 0);

    zk = z0 - cumsum([0; etaik(1:end-1)]) * deltaT / (Q * 3600);
    rck = zeros(length(RCfact), length(etaik));
    rck(:,1) = iR0;
    hk = zeros(length(ik), 1);
    hk(1) = h0;
    sik = 0 * hk;
    fac = exp(-abs(G * etaik * deltaT / (3600 * Q)));

    for k = 2:length(ik)
        rck(:,k) = diag(RCfact) * rck(:,k-1) + (1 - RCfact) * etaik(k-1);
        hk(k) = fac(k-1) * hk(k-1) - (1 - fac(k-1)) * sign(ik(k-1));
        sik(k) = sign(ik(k));
        if abs(ik(k)) < Q / 100, sik(k) = sik(k-1); end
    end
    rck = rck';

    OCV = OCVfromSOCtemp(zk, T, model);
    vk = OCV + M * hk + M0 * sik - rck * RParam' - ik .* R0Param;
end
