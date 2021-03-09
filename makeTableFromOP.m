% {}~

% % parse CyCo vs Energy - columns in cell array:
% % - 1: Ek [MeV/n];
% % - 2: cycle code;
% % - 3: range [mm];
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\MeVvsCyCo_P.xlsx";
% CyCoData = getMyData(FileName,"Sheet1");
% % remove header
% CyCoData = CyCoData(2:end,:);
% % 
% % parse Brho vs Energy - columns in cell array:
% % - 1: range [mm];
% % - 2: Brho [Tm];
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\EvsBro_P.xlsx";
% BrhoData = getMyData(FileName,"Sheet1");
% % remove header
% BrhoData = BrhoData(2:end,:);
% % 
% % get common ranges
% [commonRanges,iCRa,iCRb]=intersect(cell2mat(CyCoData(:,3)),cell2mat(BrhoData(:,1)));
% CyCoData=CyCoData(iCRa,:);
% BrhoData=BrhoData(iCRb,:);
% % 
% % make a unique table - columns in final cell array:
% % - 1: cycle code;
% % - 2: range [mm];
% % - 3: Ek [MeV/n];
% % - 4: Brho [Tm];
% CyCoData={CyCoData{:,2} ; CyCoData{:,3} ; CyCoData{:,1} ; BrhoData{:,2} }';

% parse CyCo vs Energy - columns in cell array:
% - 1: cycle code;
% - 2: range [mm];
% - 4: Ek [MeV/n];
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.9\INPUT\Protoni.xlsx";
CyCoData = getMyData(FileName,"Protoni");
% remove header
CyCoData = CyCoData(2:end,:);
% DEFINISCO il bro come funzione
mp = 938.255;
An = 1;
Zn = 1;
c = 2.99792458e8;  % velocità della luce
BRO = @(x)(An/Zn)*((mp*sqrt((1 + x/mp).^2 - 1))/c)*10^6;
temp=num2cell(BRO(cell2mat(CyCoData(:,4))));
% make a unique table - columns in final cell array:
% - 1: cycle code;
% - 2: range [mm];
% - 3: Ek [MeV/n];
% - 4: Brho [Tm];
CyCoData={CyCoData{:,1} ; CyCoData{:,2} ; CyCoData{:,4} ; temp{:,1} }';
% extract only first four digits of cyco
buffer = vertcat( CyCoData{:,1} ) ;
CyCoData(:,1) = cellstr(buffer(:,1:4)) ;

% parse file with currents at FT - columns in final cell array:
% - nRows: number of power supplies + a header
% - nColumns: number of cycle codes + 2 (PS name + property)
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\ProtoniSincro_2021-02-13.xlsx";
currents = getMyData(FileName,"Foglio1");
% - get cycle codes to be crunched
% extract only first four digits of cyco
buffer = vertcat( currents{1,3:end} ) ;
currCycodes=cellstr(buffer(:,1:4)) ;
nCyCodes=length(currCycodes);
% - get PS to be crunched
psNames=upper(currents(2:end,1));
nPSs=length(psNames);
% - remove useless data from PS file:
currents=currents(2:end,3:end);

[commonCyCodes,iCCa,iCCb]=intersect(currCycodes,CyCoData(:,1));
if ( iCCa~=nCyCodes )
    warning("not all cycle codes in PS file will be dumped!");
end
CyCoData=CyCoData(iCCb,:);
currents=currents(:,iCCa);
nCyCodes=length(commonCyCodes);

% build table to be exported
% - nRows: number of cycle codes
% - nColumns: number of PSs + 3 (range[mm],Ek[MeV/n],Brho[Tm],)
bigTable=zeros(nCyCodes,nPSs+3);
bigTable(:,1:3)=cell2mat(CyCoData(:,2:4));
bigTable(:,4:end)=cell2mat(currents(1:end,:)');
% * convert currents into fields
bigTableFields=zeros(nCyCodes,nPSs+3);
bigTableFields(:,1:3)=bigTable(:,1:3);
for jj=1:nPSs
    [pQ,unit,name]=LGENname2pQ(psNames{jj});
    pQend=pQ(end);
    for ii=1:nCyCodes
        pQ(end)=pQend-cell2mat(currents(jj,ii));
        [x,err]=newtonMethodPol(pQ);
        bigTableFields(ii,3+jj)=x;
    end
end
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields);
% * convert fields into kicks
bigTableKicks=zeros(nCyCodes,nPSs+3);
bigTableKicks(:,1:3)=bigTableFields(:,1:3);
bigTableKicks(:,4:end)=bigTableFields(:,4:end)./bigTableFields(:,3);
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields,bigTableKicks);

% prepare header
headers=strings(1,nPSs+3);
headers(1)="range_mm";
headers(2)="Ek_MeVN";
headers(3)="Brho_Tm";
for jj=1:nPSs
    [pQ,unit,name]=LGENname2pQ(psNames{jj});
    [kickName,kickUnit]=decodeKickName(name);
    headers(3+jj)=sprintf("%s_%s",string(psNames(jj)),kickName);
end
% prepare header type
headerTypes=strings(1,nPSs+3);
headerTypes(:)="%le";
% export MADX table
FileName="synchro\ProtoniSincro_2021-02-13.tfs";
title="myTable";
exportMADXtable(FileName,title,bigTableKicks,headers,headerTypes);

function myData=getMyData(FileName,sheetName)
    tmpFile=dir(FileName);
    if ( length(tmpFile)>1 )
        error("Path %s is not a single file!",tmpFile);
    end
    fprintf("acquring data from file %s in folder %s...\n",tmpFile(1).name,tmpFile(1).folder);
    if ( exist('sheetName','var') )
        myData=readcell(sprintf("%s\\%s",tmpFile(1).folder,tmpFile(1).name),"Sheet",sheetName);
    else
        myData=readcell(sprintf("%s\\%s",tmpFile(1).folder,tmpFile(1).name));
    end
end

function exportMADXtable(FileName,title,bigTable,headers,headerTypes)
    fprintf("saving data to file %s...\n",FileName);
    T=now;
    fileID = fopen(FileName,'w');
    % - MADX table header
    writeMADXHeaderLine(fileID,"TYPE","TWISS");
    writeMADXHeaderLine(fileID,"TITLE",title);
    writeMADXHeaderLine(fileID,"ORIGIN","MatLab");
    writeMADXHeaderLine(fileID,"DATE",datestr(T,'dd/mm/yy'));
    writeMADXHeaderLine(fileID,"TIME",datestr(T,'hh.mm.ss'));
    % - column names
    fprintf(fileID,"*");
    fprintf(fileID," %-18s",strrep(headers(:),"-","_"));
    fprintf(fileID,"\n");
    % - column types
    fprintf(fileID,"$");
    fprintf(fileID," %-18s",headerTypes);
    fprintf(fileID,"\n");
    % - actual data
    for ii=1:size(bigTable,1)
        fprintf(fileID," %-18.10g",bigTable(ii,:));
        fprintf(fileID,"\n");
    end
    fclose(fileID);
end

function writeMADXHeaderLine(fileID,what,content)
    fprintf(fileID,"@ %-16s %%%02is ""%s""\n",what,strlength(content),content);
end

function [x,err]=newtonMethodPol(pQ,x0,prec,nMax)
    x=0.0;
    if ( exist('x0','var') )
        x=x0;
    end
    if ( ~exist('prec','var') )
        prec=1E-12;
    end
    if ( ~exist('nMax','var') )
        nMax=100;
    end
    %
    pQder=pQ(1:end-1);
    for ii=1:nMax
        xN = x - polyval(pQ,x)/polyval(pQder,x);
        if( x~=0.0 )
            err=xN/x-1;
        else
            err=xN-x;
        end
        % fprintf("%d %.5E %.5E \n",ii,x,err); % debug
        if (abs(err)<prec)
            break;
        else
            x=xN;
        end
    end
end

function [pQ,unit,name]=LGENname2pQ(LGENname)
    % based on files by RBasso
    % pQs as from RampGen2.9
    switch LGENname
        case "P6-006A-LGEN"
            % SYNCRO - Main Dipoles
            % PARAMETRI PER CALCOLARE I[A] of B[T] per CNAO1
            % source: BuildlRampFunctions\CNAO1\ (any .m)
            % apply DeltaI
            DeltaI=-20*3000/2^18;
            a12=-5060.063029855809;
            a11=+45192.23031071493;
            a10=-176643.4664941274;
            a9=+397709.7018636417;
            a8=-571299.0339952082;
            a7=+548163.1319381793;
            a6=-357877.9092657598;
            a5=+159276.2829111949;
            a4=-47900.81904413935;
            a3=+9627.376305268983;
            a2=-1295.960272584674;
            a1=+1915.789792378836;
            a0=-6.412869458784534;
            % a0=a0-DeltaI;
            pQ=[a12 a11 a10 a9 a8 a7 a6 a5 a4 a3 a2 a1 a0];
            unit="T";
            name="B";
        case "P6-007A-LGEN"
            % SYNCRO - Main Quadrupoles
            % I[A] of g[T/m] of QF1-S2
            % source: BuildlRampFunctions\QUADRUPOLI\ (any .m)
            a4=0.681494542;
            a3=-4.13443412;
            a2=+8.25074598;
            a1=+146.434368;
            a0=0.0;
            pQ=[a4 a3 a2 a1 a0];
            unit="T/m";
            name="g";
        case "P6-008A-LGEN"
            % SYNCRO - Main Quadrupoles
            % I[A] of g[T/m] of QF2-S3
            % source: BuildlRampFunctions\QUADRUPOLI\ (any .m)
            a4=0.678396805;
            a3=-4.11687465;
            a2=+8.25508336;
            a1=+146.210499;
            a0=0.0;
            pQ=[a4 a3 a2 a1 a0];
            unit="T/m";
            name="g";
        case "P6-009A-LGEN"
            % SYNCRO - Main Quadrupoles
            % I[A] of g[T/m] of QD-S4
            % source: BuildlRampFunctions\QUADRUPOLI\ (any .m)
            a4=0.678000635;
            a3=-4.11206401;
            a2=+8.24149582;
            a1=+146.469007;
            a0=0.0;
            pQ=[a4 a3 a2 a1 a0];
            unit="T/m";
            name="g";
        case "P6-011A-LGEN"
            % SYNCRO - Resonance Sextupole
            % I[A] of s[T/m2] of S6
            % CPriano's spreadsheet: I[A]=9.4632*s[T/m2];
            a1=9.4632;
            a0=0.0;
            pQ=[a1 a0];
            unit="T/m^2";
            name="s";
        case "P6-013A-LGEN"
            % SYNCRO - Chroma Sextupole
            % I[A] of s[T/m2] of S8 (kick: S1, eg S5-012A)
            % CPriano's spreadsheet: I[A]=9.5142*s[T/m2];
            a1=9.5142;
            a0=0.0;
            pQ=[a1 a0];
            unit="T/m^2";
            name="s";
        case "P6-014A-LGEN"
            % SYNCRO - Chroma Sextupole
            % I[A] of s[T/m2] of S9 (kick: S0, eg S2-019A)
            % CPriano's spreadsheet: I[A]=9.5003*s[T/m2];
            a1=9.5003;
            a0=0.0;
            pQ=[a1 a0];
            unit="T/m^2";
            name="s";
        case { ...
                "P6-101A-LGEN" ...
                "P6-101B-LGEN" ...
                "P6-101C-LGEN" ...
                "P6-101D-LGEN" ...
                "P6-102A-LGEN" ...
                "P6-102B-LGEN" ...
                "P6-102C-LGEN" ...
                "P6-102D-LGEN" ...
                "P6-103A-LGEN" ...
                "P6-103B-LGEN" ...
                "P6-103C-LGEN" ... % spare, used
                "P6-103D-LGEN" ... % spare, used
                "P6-104A-LGEN" ...
                "P6-104B-LGEN" ...
                "P6-104C-LGEN" ... % spare, not used
                "P6-104D-LGEN" ... % spare, not used
                "P6-105A-LGEN" ...
                "P6-105B-LGEN" ... % not used
                "P6-105C-LGEN" ...
                "P6-105D-LGEN" ...
                }
            % SYNCRO - Orbit correctors
            % I[A] of BL[Tm]
            % source: BuildlRampFunctions\CORRETTORI\ (any .m)
            % a1=Imax[A]/Brho_max[TM]/theta_max[rad]
            % where:
            %   - Imax=15.0 A;
            %   - Brho_max=6.35 Tm (i.e. 270mm C-12);
            %   - theta_max: 2 mrad;
            a1=15.0/6.35/2.0E-3;
            a0=0.0;
            pQ=[a1 a0];
            unit="Tm";
            name="k";
        otherwise
            warning("unexpected power supply: %s",LGENname);
            a1=1.0;
            a0=0.0;
            pQ=[a1 a0];
            unit="???";
            name="???";
    end
end

function [currName,currUnit]=decodeKickName(kickName)
    switch upper(kickName)
        case "B"
            currName="K0";
            currUnit="m-1";
        case "G"
            currName="K1";
            currUnit="m-2";
        case "S"
            currName="K2";
            currUnit="m-3";
        case "K"
            currName="kick";
            currUnit="rad";
        otherwise
            warning("unexpected multipole field name: %s",kickName);
            currName="???";
            currUnit="???";
    end
end

function visualCheck(LGENs,psNames,bigTable,bigTableFields,bigTableKicks)
    % visual check
    figure('Name','visual check','NumberTitle','off');
    nSets=length(LGENs);
    % automatically set grid of subplots
    [nRows,nCols]=getNrowsNcols(nSets);
    for iSet=1:nSets
        currLGEN=LGENs(iSet);
        subplot(nRows,nCols,iSet);
        jj=find(strcmp(psNames,currLGEN));
        [pQ,unit,name]=LGENname2pQ(currLGEN);
        if ( exist('bigTableKicks','var') )
            plot(bigTable(:,3+jj),bigTableFields(:,3+jj),'s-');
            ylabel(sprintf("%s [%s]",name,unit));
            yyaxis right;
            plot(bigTable(:,3+jj),bigTableKicks(:,3+jj),'.-');
            [kickName,kickUnit]=decodeKickName(name);
            ylabel(sprintf("%s [%s]",kickName,kickUnit));
            yyaxis left;
            xlabel("I [A]");
            legend('field','kick','Location','best');
        else        
            minField=min(bigTableFields(:,3+jj));
            maxField=max(bigTableFields(:,3+jj));
            tmpFields=minField:(maxField-minField)/200:maxField;
            tmpCurrents=polyval(pQ,tmpFields);
            plot(bigTableFields(:,3+jj),bigTable(:,3+jj),'*',tmpFields,tmpCurrents,'-');
            xlabel(sprintf("%s [%s]",name,unit));
            ylabel("I [A]");
            legend('data','curve','Location','best');
        end
        grid on;
        title(currLGEN);
    end
end

function [nRows,nCols]=getNrowsNcols(nPlots)
    % automatically set grid of subplots
    nSquared=ceil(sqrt(nPlots));
    nCols=nSquared;
    if (nPlots<=nSquared*(nSquared-1))
        nRows=nSquared-1;
    else
        nRows=nSquared;
    end
end