% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="example_optics.tfs";
geometryFileName="example_geometry.tfs";
rMatrixFileName="example_rmatrix.tfs";

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');
rMatrix = ParseTfsTable(rMatrixFileName,'rMatrix');

% show the optics
myTitle="MEBT - Protons";
ShowOptics(optics,geometry,myTitle,Laccel,Qx,Qy,Chrx,Chry);
ShowRmatrix(rMatrix,geometry,myTitle);
