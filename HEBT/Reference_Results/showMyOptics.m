% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="..\linet_optics.tfs";
geometryFileName="..\linet_geometry.tfs";
rMatrixFileName="..\linet_rmatrix.tfs";

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');
rMatrix = ParseTfsTable(rMatrixFileName,'rMatrix');

% show the optics
myTitle="Line T (sala 3) - Carbon - 30mm";
ShowOptics(optics,geometry,myTitle,Laccel,Qx,Qy,Chrx,Chry);
ShowRmatrix(rMatrix,geometry,myTitle);
