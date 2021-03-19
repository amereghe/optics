% {}~
% - include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

correctorNames=[ "V2_013A_CEB" ]; % [ "T1_011A_CEB" "T2_015A_CEB" ],[ "U1_023A_CEB" "U2_013A_CEB" ],[ "V1_044A_CEB" "V2_013A_CEB" ],[ "Z1_011A_CEB" "Z2_015A_CEB" ]
for correctorName=correctorNames
    %warning(correctorName);

    RMfileName=sprintf("%s_rm.txt",lower(correctorName));
    xlsFileName = sprintf("%s_RM.xlsx",correctorName);

    [RMtable,iColBrho,iColBP,iColI,iColxhISO,iColyhISO,iColxhNZL,iColyhNZL,iColxhSFH,iColyhSFH,...
        iColxvISO,iColyvISO,iColxvNZL,iColyvNZL,iColxvSFH,iColyvSFH]=readRMtable(RMfileName);
    % get unique values of BP
    sets=unique(RMtable(:,iColBP));

%     % build plot maps
%     myTitle=sprintf("%s - regular planes",strrep(correctorName,"_","\_"));
%     % planeLabels=[ "x" ];
%     % kickLabels=[ "HKICK" ];
%     % locationLabels=[ "ISO" ];
%     % iCols=[ iColxhISO ];
%     % nOrders=[ 1 ];
%     if ( startsWith(upper(correctorName),"V") )
%         planeLabels=[ "x" "x" "x" "y" "y" "y" ];
%         kickLabels=[ "HKICK" "HKICK" "HKICK" "VKICK" "VKICK" "VKICK" ];
%         locationLabels=[ "SFH" "NZL" "ISO" "SFH" "NZL" "ISO" ];
%         iCols=[ iColxhSFH iColxhNZL iColxhISO iColyvSFH iColyvNZL iColyvISO ];
%         nOrders=[ 1 1 1 1 1 1 ];
%     else
%         planeLabels=[ "x" "x" "y" "y" ];
%         kickLabels=[ "HKICK"  "HKICK" "VKICK" "VKICK" ];
%         locationLabels=[ "SFH" "ISO" "SFH" "ISO" ];
%         iCols=[ iColxhSFH iColxhISO iColyvSFH iColyvISO ];
%         nOrders=[ 1 1 1 1 ];
%     end
%     overView3D(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColI,iColBP,"I [A]","BP [mm]");
%     [A,headerA]=performFit(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColI,iColBP,"I [A]","BP [mm]",iColBrho,nOrders);
%     writeXLStable(A,headerA,xlsFileName,planeLabels,kickLabels,locationLabels,1);
%     % [A,planeLabels,kickLabels,locationLabels]=readXLStable(xlsFileName);
%     showFitParams(A,planeLabels,kickLabels,locationLabels,1,3,"BP [mm]","RM [m/A Tm]",myTitle);

    myTitle=sprintf("%s - coupled planes",strrep(correctorName,"_","\_"));
    if ( startsWith(upper(correctorName),"V") )
        planeLabels=[ "x" "x" "x" "y" "y" "y" ];
        kickLabels=[ "VKICK" "VKICK" "VKICK" "HKICK" "HKICK" "HKICK" ];
        locationLabels=[ "SFH" "NZL" "ISO" "SFH" "NZL" "ISO" ];
        iCols=[ iColxvSFH iColxvNZL iColxvISO iColyhSFH iColyhNZL iColyhISO ];
        nOrders=[ 1 2 2 1 2 2 ];
    else
        planeLabels=[ "x" "x" "y" "y" ];
        kickLabels=[ "VKICK"  "VKICK" "HKICK" "HKICK"];
        locationLabels=[ "SFH" "ISO" "SFH" "ISO" ];
        iCols=[ iColxvSFH iColxvISO iColyhSFH iColyhISO ];
        nOrders=[ 1 1 1 1 ];
    end
    overView3D(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColI,iColBP,"I [A]","BP [mm]");
    [A,headerA]=performFit(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColI,iColBP,"I [A]","BP [mm]",iColBrho,nOrders);
    writeXLStable(A,headerA,xlsFileName,planeLabels,kickLabels,locationLabels,0);
    % [A,planeLabels,kickLabels,locationLabels]=readXLStable(xlsFileName);
    showFitParams(A,planeLabels,kickLabels,locationLabels,1,3,"BP [mm]","RM [m/A Tm]",myTitle);

%     myTitle=sprintf("%s - regular planes",strrep(correctorName,"_","\_"));
%     if ( startsWith(upper(correctorName),"V") )
%         planeLabelsFilters=[ "x" "x" "x" "y" "y" "y" ];
%         kickLabelsFilters=[ "HKICK" "HKICK" "HKICK" "VKICK" "VKICK" "VKICK" ];
%         locationLabelsFilters=[ "SFH" "NZL" "ISO" "SFH" "NZL" "ISO" ];
%         iCols=[ iColxhSFH iColxhNZL iColxhISO iColyvSFH iColyvNZL iColyvISO ];
%         nOrders=[ 1 1 1 1 1 1 ];
%     else
%         planeLabelsFilters=[ "x" "x" "y" "y" ];
%         kickLabelsFilters=[ "HKICK"  "HKICK" "VKICK" "VKICK" ];
%         locationLabelsFilters=[ "SFH" "ISO" "SFH" "ISO" ];
%         iCols=[ iColxhSFH iColxhISO iColyvSFH iColyvISO ];
%         nOrders=[ 1 1 1 1 ];
%     end
%     for ii=1:length(planeLabelsFilters)
%         filterNames(ii)=combineLabels(planeLabelsFilters(ii),kickLabelsFilters(ii),locationLabelsFilters(ii));
%     end
%     [A,planeLabels,kickLabels,locationLabels]=readXLStable(xlsFileName);
%     showFitParams(A,planeLabels,kickLabels,locationLabels,1,3,"BP [mm]","RM [m/A Tm]",myTitle,filterNames);

end

function [RMtable,iColBrho,iColBP,iColI,iColxhISO,iColyhISO,iColxhNZL,iColyhNZL,iColxhSFH,iColyhSFH,...
    iColxvISO,iColyvISO,iColxvNZL,iColyvNZL,iColxvSFH,iColyvSFH]=readRMtable(RMfileName)
    fprintf('parsing file %s ...\n',RMfileName);
    RMtable=readmatrix(RMfileName,'ConsecutiveDelimitersRule','join','LeadingDelimitersRule','ignore','TrailingDelimitersRule','ignore');
    iColBrho=1;
    iColBP=2;
    iColI=3;
    iColxhISO=6;  % hor shift, hor kick, ISO
    iColyhISO=7;  % ver shift, hor kick, ISO
    iColxhNZL=8;  % hor shift, hor kick, NZL
    iColyhNZL=9;  % ver shift, hor kick, NZL
    iColxhSFH=10; % hor shift, hor kick, SFH
    iColyhSFH=11; % ver shift, hor kick, SFH
    iColxvISO=12; % hor shift, ver kick, ISO
    iColyvISO=13; % ver shift, ver kick, ISO
    iColxvNZL=14; % hor shift, ver kick, NZL
    iColyvNZL=15; % ver shift, ver kick, NZL
    iColxvSFH=16; % hor shift, ver kick, SFH
    iColyvSFH=17; % ver shift, ver kick, SFH
end

function overView3D(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColx,iColy,labelx,labely)
%   make 3D plots giving an overview of the dependence
    fprintf("data overview...\n");
    currTitle=sprintf("%s - overview",myTitle);
    ff=figure('Name',currTitle,'NumberTitle','off');
    nSets=length(sets);
    nLocs=length(unique(locationLabels)); % a column for every location
    nPlanes=length(unique(planeLabels));    % a row for x and one for y
    cm=colormap(parula(nSets));
    for jPlane=1:nPlanes
        for jLoc=1:nLocs
            iCol=(jPlane-1)*nLocs+jLoc;
            subplot(nPlanes,nLocs,iCol);
            for iSet=1:nSets
                indices=(RMtable(:,iColy)==sets(iSet));
                plot3(RMtable(indices,iColx),RMtable(indices,iColy),RMtable(indices,iCols(iCol)),'Color',cm(iSet,:));
                hold on;
            end
            title(sprintf("%s excursion @%s, %s",planeLabels(iCol),locationLabels(iCol),kickLabels(iCol)));
            grid on;
            xlabel(labelx);
            ylabel(labely);
            zlabel(sprintf("%s [m]",planeLabels(iCol)));
        end
    end
    sgtitle(currTitle);
end

function [A,headerA]=performFit(RMtable,sets,planeLabels,kickLabels,locationLabels,iCols,myTitle,iColx,iColy,labelx,labely,iColBrho,nOrders)
    fprintf("performing fits...\n");
    currTitle=sprintf("%s - Fits",myTitle);
    ff=figure('Name',currTitle,'NumberTitle','off');
    nSets=length(sets);
    nLocs=length(unique(locationLabels)); % all requested locations
    nPlanes=length(unique(planeLabels));  % all requested planes
    A=zeros(nSets,max(nOrders)+4,length(locationLabels)); % write BP,Brho,RM,p(:)'
    headerA=[ labely "Brho [Tm]" "RM [m/A Tm]" ];
    for iOrder=nOrders:-1:1
        headerA=[ headerA sprintf("p_%d [m/A^%d]",iOrder,iOrder) ];
    end
    headerA=[ headerA "p_0 [mm]" ];
    for iSet=1:nSets
        indices=(RMtable(:,iColy)==sets(iSet));
        currBrho=RMtable(indices,iColBrho);
        currBrho=currBrho(1);
        xFit=RMtable(indices,iColx);
        for jPlane=1:nPlanes
            for jLoc=1:nLocs
                iCol=(jPlane-1)*nLocs+jLoc;
                % perform fit
                yFit=RMtable(indices,iCols(iCol));
                p = polyfit(xFit,yFit,nOrders(iCol));
                xs=min(xFit):(max(xFit)-min(xFit))/200:max(xFit);
                ys = polyval(p,xs);
                % plot
                subplot(nPlanes,nLocs,iCol);
                plot(xFit,yFit,'k.',xs,ys,'r-');
                legend('data','fit','Location','best');
                grid on;
                xlabel(labelx);
                ylabel(sprintf("%s [m]",planeLabels(iCol)));
                title(sprintf("%s excursion @%s, %s",planeLabels(iCol),locationLabels(iCol),kickLabels(iCol)));
                % save fitting data
                RM=p(end-1)*currBrho;
                A(iSet,1:4+nOrders(iCol),iCol)=[sets(iSet) currBrho RM p(:)' ];
            end
        end
        drawnow;
        sgtitle(sprintf("%s - %s=%g",myTitle,labely,sets(iSet)));
        pause(0.0);
    end
end

function writeXLStable(A,headerA,fileName,planeLabels,kickLabels,locationLabels,iDelete)
    fprintf("writing fitting parameters to %s ...\n",fileName);
    iDeleteUsr=1;
    if ( exist('iDelete','var') )
        iDeleteUsr=iDelete;
    end
    if ( iDeleteUsr~=0 )
        delete(fileName);
    end
    nSpreadSheets=size(A,3);
    for iSpreadSheet=1:nSpreadSheets
        sheetName=combineLabels(planeLabels(iSpreadSheet),kickLabels(iSpreadSheet),locationLabels(iSpreadSheet));
        writematrix(headerA,fileName,'Sheet',sheetName);
        writematrix(A(:,:,iSpreadSheet),fileName,'Sheet',sheetName,'WriteMode','append');
    end
end

function fLabel=combineLabels(pLabel,kLabel,lLabel)
    fLabel=sprintf("%s_%s_%s",pLabel,kLabel,lLabel);
end
function [pLabel,kLabel,lLabel]=decodeLabel(tLabel)
    tmp=strsplit(tLabel,"_");
    pLabel=string(tmp(1));
    kLabel=string(tmp(2));
    lLabel=string(tmp(3));
end

function [A,planeLabels,kickLabels,locationLabels]=readXLStable(fileName)
    fprintf("reading fitting parameters from file %s ...\n",fileName);
    [~,sheet_name]=xlsfinfo(fileName);
    % reading data
    nSpreadSheets=numel(sheet_name);
    nRowsMax=0;
    nColsMax=0;
    for k=1:nSpreadSheets
        data{k}=xlsread(fileName,sheet_name{k});
        if (size(data{k},1)>nRowsMax)
            nRowsMax=size(data{k},1);
        end
        if (size(data{k},2)>nColsMax)
            nColsMax=size(data{k},2);
        end
    end
    % converting into table
    A=zeros(nRowsMax,nColsMax,nSpreadSheets);
    for k=1:nSpreadSheets
        A(:,:,k)=data{k};
    end
    % getting combinations of plane, kick, position
    planeLabels=strings(1,numel(sheet_name));
    kickLabels=strings(1,numel(sheet_name));
    locationLabels=strings(1,numel(sheet_name));
    for k=1:numel(sheet_name)
        [planeLabels(k),kickLabels(k),locationLabels(k)]=decodeLabel(sheet_name{k});
    end
end

function showFitParams(A,planeLabels,kickLabels,locationLabels,iColx,iColy,labelx,labely,myTitle,filterNames)
    fprintf("showing dependence of RMs with %s...\n",labelx);
    tmpTitle=sprintf("%s - %s vs %s",myTitle,labely,labelx);
    ff=figure('Name',tmpTitle,'NumberTitle','off');
    if ( exist('filterNames','var') )
        nSets=length(filterNames);
        allNames=strings(length(planeLabels),1);
        for ii=1:length(planeLabels)
            allNames(ii)=combineLabels(planeLabels(ii),kickLabels(ii),locationLabels(ii));
        end
    else
        nSets=length(planeLabels);
    end
    [nRows,nCols]=GetNrowsNcols(nSets);
    nRows=2;
    nCols=ceil(nSets/nRows);
    for iPlot=1:nSets
        subplot(nRows,nCols,iPlot);
        if ( exist('filterNames','var') )
            kPlot=-1;
            for jPlot=1:length(planeLabels)
                if ( strcmp(allNames(jPlot),filterNames(iPlot)) )
                    kPlot=jPlot;
                    break
                end
            end
            if ( kPlot == -1 )
                warning("requested %s is not available. Skipping...",filterNames(iPlot));
                continue
            end
        else
            kPlot=iPlot;
        end
        plot(A(:,iColx,kPlot),A(:,iColy,kPlot),'.-');
        grid on;
        xlabel(labelx);
        ylabel(labely);
        title(sprintf("%s - %s - %s",planeLabels(kPlot),kickLabels(kPlot),locationLabels(kPlot)));
    end
    sgtitle(tmpTitle);
end
