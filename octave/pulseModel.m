function [model, getParamESC, OCVfromSOCtemp, simCell] = pulseModel()
    % 📌 Define the ESC Model Parameters
    model.R0 = 0.015;
    model.R1 = 0.020;
    model.C1 = 2000;
    model.R2 = 0.005;
    model.C2 = 5000;
    model.Q = 3600;

    % Open Circuit Voltage (OCV) parameters
    model.OCV0 = [3.0, 0.5, -0.2, 0.1];
    model.OCVrel = [0.1, -0.05, 0.02, 0.01];
    model.SOC = linspace(0, 1, 100);
    
    % Temperature-dependent parameters
    model.temps = [-10, 0, 25, 45];
    model.RCParam = [2000, 2200, 2500, 2700];
    model.QParam = [3600, 3650, 3700, 3750];

    % ✔️ Return function handles
    getParamESC = @getParamESC_func;
    OCVfromSOCtemp = @OCVfromSOCtemp_func;
    simCell = @simCell_func;
    
    % 📌 Internal function: Retrieve ESC model parameters
    function theParam = getParamESC_func(paramName, temp, model)
        temp = min(temp, max(model.temps));
        temp = max(temp, min(model.temps));

        mdlFields = fieldnames(model);
        theField = find(strcmpi(paramName, mdlFields));
        if isempty(theField), error('Bad argument to "paramName"'); end

        fieldData = model.(mdlFields{theField});
        theParam = repmat(fieldData, size(temp));

        if length(fieldData) > 1
            if length(temp) > 1
                theParam = interp1(model.temps, fieldData, temp, 'spline');
            else
                ind = find(model.temps == temp);
                if ~isempty(ind)
                    theParam = fieldData(ind);
                else
                    theParam = interp1(model.temps, fieldData, temp, 'spline');
                end
            end
        end
    end

    % 📌 Internal function: Compute Open Circuit Voltage from SOC
    function ocv = OCVfromSOCtemp_func(soc, temp, model)
        OCV0 = model.OCV0(:);
        OCVrel = model.OCVrel(:);
        SOC = model.SOC(:);
        soccol = soc(:);

        if isscalar(temp)
            Tcol = temp * ones(size(soccol));
        else
            Tcol = temp(:);
        end
        
        ocv = zeros(size(soccol));
        diffSOC = SOC(2) - SOC(1);
        I1 = find(soccol <= SOC(1));
        I2 = find(soccol >= SOC(end));
        I3 = find(soccol > SOC(1) & soccol < SOC(end));

        if ~isempty(I1)
            dvdz = ((OCV0(2) + Tcol .* OCVrel(2)) - (OCV0(1) + Tcol .* OCVrel(1))) / diffSOC;
            ocv(I1) = (soccol(I1) - SOC(1)) .* dvdz + OCV0(1) + Tcol(I1) .* OCVrel(1);
        end

        if ~isempty(I2)
            dvdz = ((OCV0(end) + Tcol .* OCVrel(end)) - (OCV0(end-1) + Tcol .* OCVrel(end-1))) / diffSOC;
            ocv(I2) = (soccol(I2) - SOC(end)) .* dvdz + OCV0(end) + Tcol(I2) .* OCVrel(end);
        end
        
        if ~isempty(I3)
            I4 = (soccol(I3) - SOC(1)) / diffSOC;
            I5 = floor(I4);
            I45 = I4 - I5;
            omI45 = 1 - I45;
            ocv(I3) = OCV0(I5+1) .* omI45 + OCV0(I5+2) .* I45;
            ocv(I3) = ocv(I3) + Tcol(I3) .* (OCVrel(I5+1) .* omI45 + OCVrel(I5+2) .* I45);
        end
        ocv = reshape(ocv, size(soc));
    end

    % 📌 Internal function: Simulate cell voltage response
    function [vk, rck, hk, zk, sik, OCV] = simCell_func(ik, T, deltaT, model, z0, iR0, h0)
        ik = ik(:);
        RCfact = exp(-deltaT ./ abs(getParamESC_func('RCParam', T, model)))';
        Q = getParamESC_func('QParam', T, model);
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
        OCV = OCVfromSOCtemp_func(zk, T, model);
        vk = OCV + M * hk + M0 * sik - rck * RParam' - ik .* R0Param;
    end
end

