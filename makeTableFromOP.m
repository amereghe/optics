% {}~
% - include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

% user settings
beamPart="CARBON"; % select beam particle: proton, carbon
machine="linet"; % select machine: synchro, LineZ/Sala1, LineU/Sala2H, LineV/Sala2V, and LineT/Sala3; LEBT and MEBT to come 
config="TM"; % select configuration: TM, RFKO
source="LGEN"; % source: RampGen or LGEN
doVisualCheck=1; % perform some visual checks: 0=no, otherwise=yes; available only for LGEN source
LGENsCheck=[]; % subset to check, otherwise all - eg [ "P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
filters=["NaN" "0"]; % filter PSs where all CyCo show "NaN" or "0"
currentsOnly=0; % advice: synchro=0, HEBT=1
save2MADXtable=0;

% processing
beamPart=upper(beamPart);
machine=upper(machine);
config=upper(config);
source=upper(source);

% preliminary checks
if ( ~strcmp(config,"TM") & ~strcmp(config,"RFKO") )
    error("unrecognised config: %s - available only TM and RFKO",config);
end
if ( ~strcmp(beamPart,"PROTON") & ~strcmp(beamPart,"CARBON") )
    error("unrecognised beam particle: %s - available only PROTON and CARBON",beamPart);
end
if ( ~strcmp(machine,"SYNCHRO") & ~strcmp(machine,"LINET") & ~strcmp(machine,"SALA3") ...
                                & ~strcmp(machine,"LINEU") & ~strcmp(machine,"SALA2H") ...
                                & ~strcmp(machine,"LINEV") & ~strcmp(machine,"SALA2V") ...
                                & ~strcmp(machine,"LINEZ") & ~strcmp(machine,"SALA1") ...
                                )
    error("unrecognised machine: %s - available only SYNCHRO, LINEZ/SALA1, LINEV/SALA2V, LINEU/SALA2H and LINET/SALA3",machine);
end
if ( ~strcmp(source,"RAMPGEN") & ~strcmp(source,"LGEN") )
    error("unrecognised source: %s - available only RAMPGEN and LGEN",source);
end

% do the job
switch source
    case "RAMPGEN"
        switch machine
            case "SYNCHRO"
                % MADX can already crunch the table contained in the table
                % used by RAMPGEN; hence, this script simply adjustes the
                % format of the table to that used by MADX
                switch beamPart
                    case "PROTON"
                        % protons - RM and RFKO are basically the same, LFalbo
                        rampFileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Protoni.csv"; 
                        RampGen2MADX(rampFileName,"synchro\RampGen\TM_Protons.tfs");
                    case "CARBON"
                        if ( strcmp(config,"RFKO") )
                            rampFileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\KmachinephotoCarbRFKO.xlsx";
                            RampGen2MADX(rampFileName,"synchro\RampGen\KmachinephotoCarbRFKO.tfs","Foglio1");
                        else
                            rampFileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Carbonio.csv"; 
                            RampGen2MADX(rampFileName,"synchro\RampGen\TM_Carbon.tfs");
                        end
                    otherwise
                        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
                end % switch: RAMPGEN, SYNCHRO, beamPart
                return % that's all folks!
            otherwise
                error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
        end % switch: RAMPGEN, machine

    case "LGEN"
        switch machine
            case "SYNCHRO"
                switch beamPart
                    case "PROTON"
                        % BUILD TABLE WITH CyCo, Range, Energy and Brho
                        % - get CyCo (col 1 []), range (col 2 [mm]) and Energy (col 4 [MeV/n]) - columns in cell array
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Protoni.csv";
                        CyCoData = GetOPDataFromTables(FileName);
                        % - build array of values of Brho (as in RampGen)
                        mp = 938.255; An = 1; Zn = 1;
                        % PARSE FILE WITH CURRENTS AT FT - columns in final cell array:
                        % - nRows: number of power supplies + a header
                        % - nColumns: number of cycle codes + 2 (PS name + property)
                        FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\ProtoniSincro_2021-02-13.xlsx";
                        currentData = GetOPDataFromTables(FileNameCurrents,"Foglio1");
                    case "CARBON"
                        if ( strcmp(config,"RFKO") )
                            error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
                        end
                        % BUILD TABLE WITH CyCo, Range, Energy and Brho
                        % - get CyCo (col 1 []), range (col 2 [mm]) and Energy (col 4 [MeV/n]) - columns in cell array
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Carbonio.csv";
                        CyCoData = GetOPDataFromTables(FileName);
                        % - build array of values of Brho (as in RampGen)
                        mp = 931.2225; An = 12; Zn = 6;
                        % PARSE FILE WITH CURRENTS AT FT - columns in final cell array:
                        % - nRows: number of power supplies + a header
                        % - nColumns: number of cycle codes + 2 (PS name + property)
                        FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\CarbonioSincro_2021-02-05.xlsx";
                        currentData = GetOPDataFromTables(FileNameCurrents,"Foglio1");
                    otherwise
                        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
                end % switch: LGEN, SYNCHRO, beamPart
                % continue crunching CyCo data
                CyCoData = CyCoData(2:end,:); % remove header
                c = 2.99792458e8;  % velocità della luce [m/s]
                BRO = @(x)(An/Zn)*((mp*sqrt((1 + x/mp).^2 - 1))/c)*10^6;
                temp=num2cell(BRO(cell2mat(CyCoData(:,4))));
                % - make a unique table: 1=CyCo[], 2=range[mm], 3=Energy[MeV/n], 4=Brho[Tm] - columns in final cell array
                CyCoData={CyCoData{:,1} ; CyCoData{:,2} ; CyCoData{:,4} ; temp{:,1} }';
                buffer = vertcat( CyCoData{:,1} ) ;      % extract only first four digits of cyco
                CyCoData(:,1) = cellstr(buffer(:,1:4)) ; % 
                % MADX fileName
                [filepath,tmpName,ext] = fileparts(FileNameCurrents);
                MADXFileName=sprintf("synchro\\LGEN\\%s.tfs",tmpName);
            case {"LINEZ","SALA1","LINEV","SALA2V","LINEU","SALA2H","LINET","SALA3"}
                switch beamPart
                    case "PROTON"
                        % BUILD TABLEs WITH CyCo, Range, Energy and Brho
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\MeVvsCyCo_P.xlsx";
                        CyCoData = GetOPDataFromTables(FileName,"Sheet1");
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\EvsBro_P.xlsx";
                        BrhoData = GetOPDataFromTables(FileName,"Sheet1");
                        % PARSE FILE WITH CURRENTS AT FT - columns in final cell array:
                        switch machine
                            case {"LINEZ","SALA1"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala1\Protoni_Sala1_2021-02-13.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"15.02.2021 - 09.31");
                            case {"LINEV","SALA2V"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala2V\Protoni_Sala2V_2021-02-13.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"15.02.2021 - 09.32");
                            case {"LINEU","SALA2H"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala2H\Protoni_Sala2H_2021-02-13.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"15.02.2021 - 09.31");
                            case {"LINET","SALA3"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala3\Protoni_Sala3_2021-02-13.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"15.02.2021 - 09.32");
                        end
                    case "CARBON"
                        % BUILD TABLEs WITH CyCo, Range, Energy and Brho
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\MeVvsCyCo_C.xlsx";
                        CyCoData = GetOPDataFromTables(FileName,"Sheet1");
                        FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\EvsBro_C.xlsx";
                        BrhoData = GetOPDataFromTables(FileName,"Sheet1");
                        % PARSE FILE WITH CURRENTS AT FT - columns in final cell array:
                        switch machine
                            case {"LINEZ","SALA1"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Carbonio\lineaZ\fuocopiccolo\Carbonio_Sala1_FromRepoNovembre2020.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"09.11.2020 - 10.11");
                            case {"LINEV","SALA2V"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Carbonio\lineaV\FuocoPiccolo\Carbonio_Sala2V_FromRepo.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"21.08.2019 - 12.11");
                            case {"LINEU","SALA2H"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Carbonio\lineaU\FuocoPiccolo\Carbonio_Sala2H_FromRepo.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"21.08.2019 - 12.04");
                            case {"LINET","SALA3"}
                                FileNameCurrents="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Carbonio\lineaT\fuocopiccolo\Carbonio_Sala3_FromRepoNovembre2020.xlsx";
                                currentData = GetOPDataFromTables(FileNameCurrents,"09.11.2020 - 10.11");
                        end
                    otherwise
                        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
                end % switch: LGEN, LINET/SALA3/LINEU/SALA2H/LINEV/SALA2V/LINEZ/SALA1, beamPart
                % - get CyCo (col 2 []), range (col 3 [mm]) and Energy (col 1 [MeV/n]) - columns in cell array
                CyCoData = CyCoData(2:end,:); % remove header
                % - get Brho (col 2 [Tm]) and Energy (col 1 [MeV/n]) - columns in cell array:
                BrhoData = BrhoData(2:end,:); % remove header
                % - get common ranges
                [commonRanges,iCRa,iCRb]=intersect(cell2mat(CyCoData(:,3)),cell2mat(BrhoData(:,1)));
                CyCoData=CyCoData(iCRa,:);
                BrhoData=BrhoData(iCRb,:);
                % - make a unique table: 1=CyCo[], 2=range[mm], 3=Energy[MeV/n], 4=Brho[Tm] - columns in final cell array
                CyCoData={CyCoData{:,2} ; CyCoData{:,3} ; CyCoData{:,1} ; BrhoData{:,2} }';
                % MADX fileName
                [filepath,tmpName,ext] = fileparts(FileNameCurrents);
                MADXFileName=sprintf("HEBT\\LGEN\\%s.tfs",tmpName);
            otherwise
                error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
        end % switch: LGEN, machine
        
        % get currents and PSs to be crunched
        % - nRows: number of power supplies + a header
        % - nColumns: number of cycle codes + 2 (PS name + property)
        [currents,psNames]=tableCurrents(currentData(2:end,3:end),currentData(2:end,1)); % remove useless data from PS file and convert to matrix of floats
        nPSs=length(psNames);
        
        % - get cycle codes to be crunched
        buffer = vertcat( currentData{1,3:end} ) ; % extract only first four digits of cyco
        currCycodes=cellstr(buffer(:,1:4)) ;       %
        nCyCodes=length(currCycodes);

        for iFilter=1:length(filters)
            switch upper(filters(iFilter))
                case "NAN"
                    % - keep only PSs with no NANs (full set of cycodes should be NaN)
                    fprintf("filtering NaNs from PSs...\n");
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
                case {"ZERO","0","0.0","0."}
                    % - keep only PSs with no 0.0s (full set of cycodes should be 0)
                    fprintf("filtering 0.0s from PSs...\n");
                    % PS deleted)
                    iRows=zeros(size(currents,1),1,'logical');
                    for ii=1:length(iRows)
                        iRows(ii)=length(currents(ii,currents(ii,:)~=0.0))==nCyCodes;
                    end
                    nDelete=nPSs-sum(iRows);
                    if ( nDelete>0 )
                        warning("found %d PSs with rows/columns full of 0s! removing them...",nDelete);
                        currents=currents(iRows,:);
                        psNames=psNames(iRows);
                        nPSs=length(psNames);
                    end
            end
        end
        
        % map the CyCo in both current data and CyCo data
        [commonCyCodes,iCCa,iCCb]=intersect(currCycodes,CyCoData(:,1));
        if ( iCCa~=nCyCodes )
            warning("not all cycle codes in PS file will be dumped!");
        end
        CyCoData=CyCoData(iCCb,:);
        currents=currents(:,iCCa);
        nCyCodes=length(commonCyCodes);

        % build table to be exported
        % - nRows: number of cycle codes
        % - nColumns: number of PSs + 3 (range[mm],Ek[MeV/n],Brho[Tm])
        bigTable=zeros(nCyCodes,nPSs+3);
        bigTable(:,1:3)=cell2mat(CyCoData(:,2:4));
        bigTable(:,4:end)=currents(1:end,:)';
        if ( doVisualCheck ~= 0 )
            if ( isempty(LGENsCheck) )
                LGENsCheck=string(psNames)';
            end
            visualCheck(LGENsCheck,psNames,bigTable);
        end

        if ( currentsOnly ~= 0 )
            if ( save2MADXtable ~= 0 )
                % SAVE FILE FOR MADX
                isCurrent=1;
                save2MADXTable(bigTable,psNames,MADXFileName,isCurrent);
            end
        else
            % convert currents into fields
            bigTableFields=zeros(nCyCodes,nPSs+3);
            bigTableFields(:,1:3)=bigTable(:,1:3);
            bigTableFields(:,4:end)=Currents2Fields(psNames,currents);
            if ( doVisualCheck ~= 0 )
                visualCheck(LGENsCheck,psNames,bigTable,bigTableFields);
            end
            % convert fields into kicks
            bigTableKicks=zeros(nCyCodes,nPSs+3);
            bigTableKicks(:,1:3)=bigTableFields(:,1:3);
            bigTableKicks(:,4:end)=Fields2Kicks(bigTableFields(:,4:end),bigTableFields(:,3));
            if ( doVisualCheck ~= 0 )
                visualCheck(LGENsCheck,psNames,bigTable,bigTableFields,bigTableKicks);
            end
            if ( save2MADXtable ~= 0 )
                % SAVE FILE FOR MADX
                isCurrent=0;
                save2MADXTable(bigTableKicks,psNames,MADXFileName,isCurrent);
            end
        end

    otherwise
        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
end % switch: source

% that's all folks
fprintf("...done.\n");

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
        if ( exist('bigTableFields','var') )
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
        else
            iX=1; % 1=BP[mm], 2=Ek[MeV/n], 3=Brho[Tm]
            labelX="BP [mm]"; % "BP [mm]", "Ek [MeV/n]", "Brho [Tm]"
            plot(bigTable(:,iX),bigTable(:,3+jj),'*');
            xlabel(labelX);
            ylabel("I [A]");
            legend('data','Location','best');
        end
        grid on;
        title(currLGEN);
    end
end

function save2MADXTable(myTable,psNames,MADXFileName,isCurrent)
    myTitle="myTable";
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
    ExportMADXtable(MADXFileName,myTitle,myTable,headers,headerTypes);
end

function [currents,psNames]=tableCurrents(currentData,psNameData)
    nRows=size(currentData,1);
    nCols=size(currentData,2);
    whichRows=false(nRows,1);
    for iRow=1:nRows
        if ( ischar(currentData{iRow,1}) || isstring(currentData{iRow,1}) )
            whichRows(iRow)=1;
        else
            whichRows(iRow)=~ismissing(currentData{iRow,1});
        end
    end
    nEmpty=nRows-sum(whichRows);
    if ( nEmpty>0 )
        warning("found %d PSs with empty rows! removing them...",nEmpty);
    end
    currents=currentData(whichRows,:);
    psNames=upper(psNameData(whichRows,:));
    if ( ischar(currents{1,1}) || isstring(currents{1,1}) )
        currents=str2double(currents);
    else
        currents=cell2mat(currents);
    end
end