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
% FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\ProtoniSincro_2021-02-13.xlsx";
% currents = getMyData(FileName,"Foglio1");
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\HEBT\Protoni\ProtoniSala3\Protoni_Sala3_2021-02-13.xlsx";
currents = getMyData(FileName,"15.02.2021 - 09.32");
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
for jj=1:nPSs
    [pQ,unit,name]=LGENname2pQ(psNames{jj});
    pQend=pQ(end);
    for ii=1:nCyCodes
        pQ(end)=pQend-currents(jj,ii);
        [x,err]=newtonMethodPol(pQ);
        bigTableFields(ii,3+jj)=x;
    end
end
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields);

% SAVE FILE FOR MADX
% prepare header
headers=strings(1,nPSs+3);
headers(1)="range_mm";
headers(2)="Ek_MeVN";
headers(3)="Brho_Tm";
headers(4:end)=psNames+"_A";
% prepare header type
headerTypes=strings(1,nPSs+3);
headerTypes(:)="%le";
% export MADX table
FileName="HEBT\Protoni_Sala3_2021-02-13.tfs";
title="myTable";
exportMADXtable(FileName,title,bigTable,headers,headerTypes);
return % Protoni_Sala3_2021-02-13.xlsx

% * convert fields into kicks
bigTableKicks=zeros(nCyCodes,nPSs+3);
bigTableKicks(:,1:3)=bigTableFields(:,1:3);
bigTableKicks(:,4:end)=bigTableFields(:,4:end)./bigTableFields(:,3);
% visual check
% LGENs=["P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
% LGENs=["P6-006A-LGEN" ];
LGENs=string(psNames)';
visualCheck(LGENs,psNames,bigTable,bigTableFields,bigTableKicks);

% SAVE FILE FOR MADX
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
        
        % ==============================================================
        % synchro
        % ==============================================================
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

        % ==============================================================
        % HEBT
        % ==============================================================
        case  { ...
                 "P7-004A-LGEN"  % H4  H3-003A-SW2
                 "P7-005A-LGEN"  % H5  Spare	SBEND
                 "P7-006A-LGEN"  % H6  H3-009A-MBS
                 "P7-007A-LGEN"  % H7  H3-015A-MBS
                 "P8-010A-LGEN"  % H46 Z1-001A-SWH
                 "P8-003A-LGEN"  % H47 T1-009A-EDF
                 "P11-003A-LGEN" % H48 Z1-009A-EDF
                 "P10-003A-LGEN" % V1  V1-001A-SWV
                 "P10-004A-LGEN" % V2  V1-005A-MBU
                 "P10-005A-LGEN" % V3  V1-028A-MBD
                 "P10-006A-LGEN" % V4  V1-032A-MBD
            }
            % HEBT - Main Dipoles
            % PARAMETRI PER CALCOLARE I[A] of B[T] per CNAO1
            % source: DUMMY curve, taken from synchro for the time being!
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
        case { ...
                "P7-008A-LGEN" 	... % H8   H2-012A-QUE
                "P7-009A-LGEN" 	... % H9   H2-016A-QUE
                "P7-010A-LGEN" 	... % H10  H2-022A-QUE
                "P7-011A-LGEN" 	... % H11  H4-003A-QUE
                "P7-012A-LGEN" 	... % H12  H4-007A-QUE
                "P7-013A-LGEN" 	... % H13  H4-013A-QUE
                "P7-014A-LGEN" 	... % H14  H5-005A-QUE
                "P7-015A-LGEN" 	... % H15  H5-009A-QUE
                "P7-016A-LGEN" 	... % H16  H5-015A-QUE
                "P8-005A-LGEN" 	... % H18  T1-013A-QUE
                "P8-006A-LGEN" 	... % H19  T1-019A-QUE
                "P8-007A-LGEN" 	... % H20  T2-005A-QUE
                "P8-008A-LGEN" 	... % H21  T2-012A-QUE
                "P8-009A-LGEN" 	... % H22  T2-018A-QUE
                "P9-003A-LGEN" 	... % H23  U1-008A-QUE
                "P9-004A-LGEN" 	... % H24  U1-014A-QUE
                "P9-005A-LGEN" 	... % H25  U1-018A-QUE
                "P9-006A-LGEN" 	... % H26  U2-006A-QUE
                "P9-007A-LGEN" 	... % H27  U2-010A-QUE
                "P9-008A-LGEN" 	... % H28  U2-016A-QUE
                "P11-004A-LGEN"	... % H29  Z1-004A-QUE
                "P11-005A-LGEN"	... % H30  Z1-013A-QUE
                "P11-006A-LGEN"	... % H31  Z1-019A-QUE
                "P11-007A-LGEN"	... % H32  Z2-005A-QUE
                "P11-008A-LGEN"	... % H34  Z2-012A-QUE
                "P11-009A-LGEN"	... % H35  Z2-018A-QUE
                "P8-004A-LGEN" 	... % H36  T1-004A-QUE
                "P7-017A-LGEN" 	... % H37  Spare      
                "P10-008A-LGEN"	... % V5   V1-010A-QUE
                "P10-009A-LGEN"	... % V6   V1-014A-QUE
                "P10-010A-LGEN"	... % V7   V1-018A-QUE
                "P10-011A-LGEN"	... % V8   V1-022A-QUE
                "P10-012A-LGEN"	... % V9   V1-037A-QUE
                "P10-013A-LGEN"	... % V10  V1-041A-QUE
                "P10-014A-LGEN"	... % V11  V1-047A-QUE
                "P10-015A-LGEN"	... % V12  V2-006A-QUE
                "P10-016A-LGEN"	... % V13  V2-010A-QUE
                "P10-017A-LGEN"	... % V14  V2-016A-QUE
            }
            % HEBT - Main Quadrupoles
            % PARAMETRI PER CALCOLARE I[A] of g[T/m] per CNAO1
            % source: linear curve
            % gradiente integrato GL(T) = 3.258e-02 * I (A)
            % lq = 0.45 m
            a1=0.45/3.258e-02;
            a0=0.0;
            pQ=[a1 a0];
            unit="T/m";
            name="g";
        case { ...
               "P7-101A-LGEN"  ... % H38-A	H2-H07A-CEB
               "P7-101B-LGEN"  ... % H38-B	H2-V07A-CEB
               "P7-101C-LGEN"  ... % H38-C	H2-H19A-CEB
               "P7-101D-LGEN"  ... % H38-D	H2-V19A-CEB
               "P7-102A-LGEN"  ... % H39-A	H4-H16A-CEB
               "P7-102B-LGEN"  ... % H39-B	H4-V16A-CEB
               "P7-102C-LGEN"  ... % H39-C	H5-H01B-CEB
               "P7-102D-LGEN"  ... % H39-D	H5-V01B-CEB
               "P7-103A-LGEN"  ... % H40-A	H5-H12A-CEB
               "P7-103B-LGEN"  ... % H40-B	H5-V12A-CEB
               "P7-103C-LGEN"  ... % H40-C	T1-H11A-CEB
               "P7-103D-LGEN"  ... % H40-D	T1-V11A-CEB
               "P8-102A-LGEN"  ... % H41-A	T2-H08A-CEB
               "P8-102B-LGEN"  ... % H41-B	T2-V08A-CEB
               "P8-102C-LGEN"  ... % H41-C	T2-H15A-CEB
               "P8-102D-LGEN"  ... % H41-D	T2-V15A-CEB
               "P9-101A-LGEN"  ... % H42-A	U1-H03A-CEB
               "P9-101B-LGEN"  ... % H42-B	U1-V03A-CEB
               "P9-101C-LGEN"  ... % H42-C	U1-H11A-CEB
               "P9-101D-LGEN"  ... % H42-D	U1-V11A-CEB
               "P9-102A-LGEN"  ... % H43-A	U1-H23A-CEB
               "P9-102B-LGEN"  ... % H43-B	U1-V23A-CEB
               "P9-102C-LGEN"  ... % H43-C	U2-H13A-CEB
               "P9-102D-LGEN"  ... % H43-D	U2-V13A-CEB
               "P11-101A-LGEN" ... % H44-A	Z1-H11A-CEB
               "P11-101B-LGEN" ... % H44-B	Z1-V11A-CEB
               "P11-101C-LGEN" ... % H44-C	Z2-H08A-CEB
               "P11-101D-LGEN" ... % H44-D	Z2-V08A-CEB
               "P11-102A-LGEN" ... % H45-A	Z2-H15A-CEB
               "P11-102B-LGEN" ... % H45-B	Z2-V15A-CEB
               "P11-102C-LGEN" ... % 			   
               "P11-102D-LGEN" ... % 			   
               "P10-101A-LGEN" ... % V15-A	V1-H03A-CEB
               "P10-101B-LGEN" ... % V15-B	V1-V03A-CEB
               "P10-101C-LGEN" ... % V15-C	V1-H30A-CEB
               "P10-101D-LGEN" ... % V15-D	V1-V30A-CEB
               "P10-102A-LGEN" ... % V16-A	V1-H44A-CEB
               "P10-102B-LGEN" ... % V16-B	V1-V44A-CEB
               "P10-102C-LGEN" ... % V16-C	V2-H13A-CEB
               "P10-102D-LGEN" ... % V16-D	V2-V13A-CEB
            }
            % HEBT - Orbit correctors
            % I[A] of BL[Tm]
            % source: DUMMY curve, taken from synchro for the time being!
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
        % ==============================================================
        % unknown
        % ==============================================================
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