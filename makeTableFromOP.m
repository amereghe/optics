% {}~
% - include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

% TM, protons
rampFileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Protoni.csv";
MADXFileName="synchro\TM_Protons.tfs";
RampGen2MADX(rampFileName,MADXFileName);

% RFKO, Carbon
rampFileName="synchro\KmachinephotoCarbRFKO.xlsx";
rampSheetName="Foglio1";
MADXFileName="synchro\KmachinephotoCarbRFKO.tfs";
RampGen2MADX(rampFileName,MADXFileName,rampSheetName);
return

% % parse CyCo vs Energy - columns in cell array:
% % - 1: Ek [MeV/n];
% % - 2: cycle code;
% % - 3: range [mm];
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\MeVvsCyCo_P.xlsx";
% CyCoData = GetOPDataFromTables(FileName,"Sheet1");
% % remove header
% CyCoData = CyCoData(2:end,:);
% % 
% % parse Brho vs Energy - columns in cell array:
% % - 1: range [mm];
% % - 2: Brho [Tm];
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\EvsBro_P.xlsx";
% BrhoData = GetOPDataFromTables(FileName,"Sheet1");
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
CyCoData = GetOPDataFromTables(FileName,"Protoni");
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
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\ProtoniSincro_2021-02-13.xlsx";
% currents = GetOPDataFromTables(FileName,"Foglio1");
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala3\Protoni_Sala3_2021-02-13.xlsx";
currents = GetOPDataFromTables(FileName,"15.02.2021 - 09.32");
% - get cycle codes to be crunched
% extract only first four digits of cyco
buffer = vertcat( currents{1,3:end} ) ;
currCycodes=cellstr(buffer(:,1:4)) ;
nCyCodes=length(currCycodes);
% - get PS to be crunched
psNames=upper(currents(2:end,1));
nPSs=length(psNames);
% - remove useless data from PS file and convert to matrix of floats:
% currents=cell2mat(currents(2:end,3:end)); % ProtoniSincro_2021-02-13.xlsx
currents=str2double(currents(2:end,3:end)); % Protoni_Sala3_2021-02-13.xlsx
% - keep only PSs with no NANs (full set of cycodes should be NaN to have 
% PS deleted)
iRows=zeros(size(currents,1),1,'logical');
for ii=1:length(iRows)
    iRows(ii)=length(currents(ii,~isnan(currents(ii,:))))==nCyCodes;
end
nDelete=nPSs-sum(iRows);
if ( nDelete>0 )
    warning("found %d PSs with rows/columns full of NaNs! removing them...",nDelete);
    currents=currents(iRows,:);
    psNames=psNames(iRows);
    nPSs=length(psNames);
end

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
bigTable(:,4:end)=currents(1:end,:)';

% * convert currents into fields
bigTableFields=zeros(nCyCodes,nPSs+3);
bigTableFields(:,1:3)=bigTable(:,1:3);
bigTableFields(:,4:end)=Currents2Fields(psNames,currents);
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields);

% SAVE FILE FOR MADX
FileName="HEBT\Protoni_Sala3_2021-02-13.tfs";
myTitle="myTable";
save2MADXTable(bigTable,psNames,FileName,myTitle,1)
return % Protoni_Sala3_2021-02-13.xlsx

% * convert fields into kicks
bigTableKicks=zeros(nCyCodes,nPSs+3);
bigTableKicks(:,1:3)=bigTableFields(:,1:3);
bigTableKicks(:,4:end)=Fields2Kicks(bigTableFields(:,4:end),bigTableFields(:,3));
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields,bigTableKicks);

% SAVE FILE FOR MADX
FileName="synchro\ProtoniSincro_2021-02-13.tfs";
myTitle="myTable";
save2MADXTable(bigTableKicks,psNames,FileName,myTitle,0)

function visualCheck(LGENs,psNames,bigTable,bigTableFields,bigTableKicks)
    % visual check
    figure('Name','visual check','NumberTitle','off');
    nSets=length(LGENs);
    % automatically set grid of subplots
    [nRows,nCols]=GetNrowsNcols(nSets);
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
            [kickName,kickUnit]=DecodeKickName(name);
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

function save2MADXTable(myTable,psNames,FileName,myTitle,isCurrent)
    % SAVE FILE FOR MADX
    nPSs=length(psNames);
    % prepare header
    headers=strings(1,nPSs+3);
    headers(1)="range_mm";
    headers(2)="Ek_MeVN";
    headers(3)="Brho_Tm";
    if ( isCurrent==1)
        headers(4:end)=psNames+"_A";
    else
        for jj=1:nPSs
            [pQ,unit,name]=LGENname2pQ(psNames{jj});
            [kickName,kickUnit]=DecodeKickName(name);
            headers(3+jj)=sprintf("%s_%s",string(psNames(jj)),kickName);
        end
    end
    % prepare header type
    headerTypes=strings(1,nPSs+3);
    headerTypes(:)="%le";
    % export MADX table
    ExportMADXtable(FileName,myTitle,myTable,headers,headerTypes);
end
