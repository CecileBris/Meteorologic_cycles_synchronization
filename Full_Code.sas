
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */
/* **************************** IMPORT : QBO and Meteorological stations DATA **************************** */
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */

libname memoire1 'C:\Users\ceecy\PythonScripts\Memoire\DATA' ; 

/******************** Quasi Biennial Oscillation ************************/
proc import out = memoire1.qbo
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\qbo.csv"
DBMS=CSV; run;

/******************** Meteo Stations ************************/

proc import out = memoire1.SINGAPORE_CHANGI 
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\SINGAPORE_CHANGI.csv"
DMBS=CSV; run;
proc import out = memoire1.PAYA_LEBAR
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\PAYA_LEBAR.csv"
DMBS=CSV; run;
proc import out = memoire1.GAN_ISLAND
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\GAN_ISLAND.csv"
DMBS=CSV; run;
/******* EXPORT CSV for combination of paya_lebar & singapore_changi *******/
PROC EXPORT DATA=Memoire1.Paya_lebar
		    DBMS=csv 
		    OUTFILE="C:\Users\ceecy\PythonScripts\Memoire\DATA\Paya_lebar.csv"  
		    REPLACE;
 		    DELIMITER=",";
run;
PROC EXPORT DATA=Memoire1.Singapore_changi
		    DBMS=csv 
		    OUTFILE="C:\Users\ceecy\PythonScripts\Memoire\DATA\Singapore_chan.csv"  
		    REPLACE;
 		    DELIMITER=",";
run;
/******* IMPORT OF PAYA_LEBAR // SINGAPORE DATASET *******/
/* Since both stations are in Singapore, we consider the data of Paya_Lebar 
for the periods 1954-1981 & 1999-2020 for Temperature and Wind Speed ; 
for the period 1954-1981 for the precipitations // And the data of SIngapore_changi,
for the period 1981-1999 for Temp and Wind Speed ; for the periode 1981-2020 for the PRCP */

proc import out = memoire1.PAYA_LEBAR_SINGA
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\Paya_lebar1.csv"
DMBS=CSV; run;

/******************** Datasets dates in TMP1 ************************/
proc sql outobs=815;
	create table Memoire1.dates as 
	select * from TMP1.dateDP ;
quit; 
DATA Memoire1.date ;
set Memoire1.dates ; 
format dateok date9. ;
dateok = intnx("month",date, 1) ; 
run; 
/**************** Fusion of dates with QBO ****************/

proc sql ;
create table Memoire1.qbo_dates as 
select * from Memoire1.date as X full join Memoire1.Qbo as Y 
on X.var1 = Y.X1; 
quit ;
proc sql;
   create table Memoire1.qbo_clean (drop= X1 YYMM date) as
      select var1, dateok, IIIII, seventy, fifty, fourty, thirty, twenty, fifteen, ten
      from Memoire1.qbo_dates;
quit;

/******************** PAYA_LEBAR_SINGA ************************/
/******************** Suppression of useless variables for our project ************************/
/* We drop LATITUDE LONGITUDE & ELEVATION since we will use the originate tables for mapping the locations of meteo stations */
proc sql;
   create table Memoire1.paya_clean (drop=index LATITUDE LONGITUDE ELEVATION DEWP DEWP_ATTRIBUTES SLP SLP_ATTRIBUTES STP STP_ATTRIBUTES VISIB 
VISIB_ATTRIBUTES MXSPD GUST MAX MIN MAX_ATTRIBUTES MIN_ATTRIBUTES SNDP) as
      select STATION, NAME, VAR1, DATE, TEMP, TEMP_ATTRIBUTES, PRCP, PRCP_ATTRIBUTES, FRSHTT, 
WDSP, WDSP_ATTRIBUTES
      from Memoire1.paya_lebar_singa;
quit;
/******************** Missing values ************************/
data Memoire1.paya_clean1; 
set Memoire1.paya_clean; 
if PRCP=99.99 then PRCP=.;
if WDSP=999.9 then WDSP=.; 
run ; 
/******************** Recoding Day to Month ************************/
/* To PROC EXPAND frrom day to month, we need constant timeseries : this code duplicates precedent value for missing days */
proc expand data = Memoire1.paya_clean1  out= Memoire1.paya_clean2 to=day method=step;
  convert TEMP = TEMP_open;
  convert TEMP_ATTRIBUTES = TEMP_ATT;
  convert PRCP = PRCP_open;
  convert FRSHTT = FRSH;
  convert WDSP = WDSP_open;
  convert WDSP_ATTRIBUTES = WDSP_ATT;
  convert STATION = STAT ;
  id date;
run;
/******** PROC EXPAND ********/
proc expand data=Memoire1.paya_clean2 out=Memoire1.paya_lebar_clean
			from=day to=month;
	convert FRSH ;
	convert TEMP_open TEMP_ATT PRCP_open WDSP_open WDSP_ATT / observed=average;
	id DATE ;
	format date date9.;
run;
proc sql outobs=793;
	create table Memoire1.Lebar_clean as 
	select * from Memoire1.Paya_lebar_clean ;
quit; 
/******************** Fusion : QBO + PAYA_LEBAR ************************/
proc sql ;
create table Memoire1.Synchro_Meteo as 
select * from Memoire1.Qbo_clean as X full join Memoire1.Lebar_clean as Y 
on X.dateok = Y.date;
quit; 
/**************** Suppression of the duplicata for DATES ****************/
proc sql;
   create table Memoire1.Meteo_synchro (drop= DATE) as
      select VAR1, dateok, TEMP_open, TEMP_ATT, PRCP_open, FRSH, 
WDSP_open, WDSP_ATT, IIIII, seventy, fifty, fourty, thirty, twenty, fifteen, ten
      from Memoire1.Synchro_Meteo;
quit;


/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */
/* ************************************* Visualisation of raw data *************************************** */
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */


/******************** QBO_CLEAN ************************/

proc template;
define statgraph sgdesign;
dynamic _DATEOK _FIFTEEN _DATEOK2 _THIRTY _DATEOK3 _FIFTY _DATEOK4 _SEVENTY;
begingraph / designwidth=1049 designheight=716;
   entrytitle halign=center 'Before/after compareason of the months recoding';
   entryfootnote halign=left 'Saisissez votre note de bas de page...';
   layout lattice / rowdatarange=data columndatarange=data rows=4 columns=1 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0 1.0) columnweights=(1.0);
      layout overlay;
         seriesplot x=_DATEOK y=_FIFTEEN / curvelabel='15hPaN Winds' name='series3' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK2 y=_THIRTY / curvelabel='30hPaN Winds' name='series4' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK3 y=_FIFTY / curvelabel='50hPaN Winds' name='series5' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK4 y=_SEVENTY / curvelabel='70hPaN Winds' name='series8' connectorder=xaxis;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.QBO_CLEAN template=sgdesign;
dynamic _DATEOK="DATEOK" _FIFTEEN="FIFTEEN" _DATEOK2="DATEOK" _THIRTY="THIRTY" _DATEOK3="DATEOK" _FIFTY="FIFTY" _DATEOK4="DATEOK" _SEVENTY="SEVENTY";
run;

/******************** PAYA_LEBAR BEFORE MENSUALISATION (paya_clean1) ************************/

proc template;
define statgraph sgdesign;
dynamic _DATE _TEMP _DATE2 _PRCP _DATE6 _WDSP _DATE7 _FRSHTT;
begingraph / designwidth=1049 designheight=716;
   entrytitle halign=center 'Before/after compareason of the months recoding';
   entryfootnote halign=left 'Saisissez votre note de bas de page...';
   layout lattice / rowdatarange=data columndatarange=data rows=4 columns=1 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0 1.0) columnweights=(1.0);
      layout overlay;
         seriesplot x=_DATE y=_TEMP / curvelabel='Paya Lebar TEMPS' name='series' clusterwidth=0.5 connectorder=xaxis grouporder=data;
      endlayout;
      layout overlay;
         seriesplot x=_DATE2 y=_PRCP / curvelabel='Paya Lebar PRCP' name='series2' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATE6 y=_WDSP / curvelabel='Paya Lebar WDSP' name='series6' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATE7 y=_FRSHTT / curvelabel='Paya Lebar FRSHTTT' name='series7' connectorder=xaxis;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.PAYA_CLEAN1 template=sgdesign;
dynamic _DATE="DATE" _TEMP="TEMP" _DATE2="DATE" _PRCP="PRCP" _DATE6="DATE" _WDSP="WDSP" _DATE7="DATE" _FRSHTT="FRSHTT";
run;

/******************** PAYA_LEBAR AFTER MENSUALISATION (lebar_clean) ************************/

proc template;
define statgraph sgdesign;
dynamic _DATE _TEMP_OPEN _DATE2 _PRCP_OPEN _DATE3 _WDSP_OPEN _DATE4 _FRSH;
begingraph / designwidth=1049 designheight=716;
   entrytitle halign=center 'Before/after compareason of the months recoding';
   entryfootnote halign=left 'Saisissez votre note de bas de page...';
   layout lattice / rowdatarange=data columndatarange=data rows=4 columns=1 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0 1.0) columnweights=(1.0);
      layout overlay;
         seriesplot x=_DATE y=_TEMP_OPEN / curvelabel='post-recoding temperatures' name='series' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATE2 y=_PRCP_OPEN / curvelabel='post-recoding precipitations' name='series2' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATE3 y=_WDSP_OPEN / curvelabel='post-recoding winds-speed' name='series6' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATE4 y=_FRSH / curvelabel='post-recoding FRSHTT Index' name='series7' connectorder=xaxis;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.LEBAR_CLEAN template=sgdesign;
dynamic _DATE="DATE" _TEMP_OPEN="'TEMP_OPEN'n" _DATE2="DATE" _PRCP_OPEN="'PRCP_OPEN'n" _DATE3="DATE" _WDSP_OPEN="'WDSP_OPEN'n" _DATE4="DATE" _FRSH="FRSH";
run;

/******************** METEO_SYNCHRO ************************/

proc template;
define statgraph sgdesign;
dynamic _DATEOK _FIFTEEN _DATEOK2 _THIRTY _DATEOK3 _FIFTY _DATEOK4 _SEVENTY _DATEOK5 _TEMP_OPEN _DATEOK6 _PRCP_OPEN _DATEOK7 _WDSP_OPEN _DATEOK8 _FRSH;
begingraph / designwidth=1049 designheight=716;
   entrytitle halign=center 'Before/after compareason of the months recoding';
   entryfootnote halign=left 'Saisissez votre note de bas de page...';
   layout lattice / rowdatarange=data columndatarange=data rows=4 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0 1.0) columnweights=(1.0 1.0);
      layout overlay;
         seriesplot x=_DATEOK y=_FIFTEEN / curvelabel='15hPaN Winds' name='series3' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK5 y=_TEMP_OPEN / curvelabel='post-recoding temperatures' name='series' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK2 y=_THIRTY / curvelabel='30hPaN Winds' name='series4' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK6 y=_PRCP_OPEN / curvelabel='post-recoding precipitations' name='series2' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK3 y=_FIFTY / curvelabel='50hPaN Winds' name='series5' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK7 y=_WDSP_OPEN / curvelabel='post-recoding winds-speed' name='series6' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK4 y=_SEVENTY / curvelabel='70hPaN Winds' name='series8' connectorder=xaxis;
      endlayout;
      layout overlay;
         seriesplot x=_DATEOK8 y=_FRSH / curvelabel='post-recoding FRSHTT Index' name='series7' connectorder=xaxis;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.METEO_SYNCHRO template=sgdesign;
dynamic _DATEOK="DATEOK" _FIFTEEN="FIFTEEN" _DATEOK2="DATEOK" _THIRTY="THIRTY" _DATEOK3="DATEOK" _FIFTY="FIFTY" _DATEOK4="DATEOK" _SEVENTY="SEVENTY" _DATEOK5="DATEOK" _TEMP_OPEN="'TEMP_OPEN'n" _DATEOK6="DATEOK" _PRCP_OPEN="'PRCP_OPEN'n" _DATEOK7="DATEOK" _WDSP_OPEN="'WDSP_OPEN'n" _DATEOK8="DATEOK" _FRSH="FRSH";
run;

/*****! IL Y A UN PB AVEC L'INDICE ; INDIQUER A SAS QUE L'ON VEUT UN NOMBRE ENTIER + REGARDER CE QUE L'INDICE SIGNIFIE SI ON LE MET !*****/

/***** Préparation de la table pour le GRAPH SURFACE - à partir de QBO_CLEAN *****/
 
data Memoire1.QBO_heatmap; set Memoire1.QBO_clean;
dupliq = 7; /*Number of line you need to duplicate*/
do i= 1 to dupliq; 	 
output;
end;
run;

data Memoire1.QBO_heat; set Memoire1.QBO_heatmap;
drop dupliq ;
Run;
/*create a column for pressures and associates it to dateok and WindSpeed values*/
data Memoire1.QBO_he; set Memoire1.QBO_heat;
if i = 1 then do ; Pressure = '10' ;WindSpeed = ten;end;
if i = 2 then do ; Pressure = '15' ;WindSpeed = fifteen;end;
if i = 3 then do ; Pressure = '20' ;WindSpeed = twenty;end;
if i = 4 then do ; Pressure = '30' ;WindSpeed = thirty;end;
if i = 5 then do ; Pressure = '40' ;WindSpeed = fourty;end;
if i = 6 then do ; Pressure = '50' ;WindSpeed = fifty;end;
if i = 7 then do ; Pressure = '70' ;WindSpeed = seventy;end;
drop ten fifteen twenty thirty fourty fifty seventy IIIII ; 
run;
data Memoire1.QBO_heat;
  set Memoire1.QBO_he;
  Pressure_hPaN=input(Pressure,2.); /*transpose a character in numeric*/
  drop Pressure;
run;

/***** HEATMAP CODE *****/

proc template;
define statgraph sgdesign;
dynamic _DATEOK _PRESSURE_HPAN _WINDSPEED;
begingraph / designwidth=1182 designheight=480;
   entrytitle halign=center 'Equatorial Zonal Wind, Monthly Means';
   entryfootnote halign=left 'Saisissez votre note de bas de page...';
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / xaxisopts=( reverse=false display=(TICKS TICKVALUES LINE ) label=('Months') timeopts=( minorticks=OFF tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(0.0 3653.0 7305.0 10958.0 14610.0 18263.0 21915.000000000004))) yaxisopts=( reverse=true linearopts=( tickvaluepriority=TRUE tickvalueformat=BEST6. tickvaluelist=(10.0 20.0 30.0 40.0 50.0 60.0 70.0)));
         contourplotparm x=_DATEOK y=_PRESSURE_HPAN z=_WINDSPEED / name='contour' contourtype=LABELEDLINEGRADIENT colormodel=ThreeColorRamp gridded=false;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.QBO_HEAT template=sgdesign;
dynamic _DATEOK="DATEOK" _PRESSURE_HPAN="'PRESSURE_HPAN'n" _WINDSPEED="WINDSPEED";
run;

/*************** DATA TREATMENT ***************/

data Memoire1.Meteo_sync;
set Memoire1.Meteo_synchro;
rename TEMP_open = TEMP PRCP_open = PRCP WDSP_open = WDSP ;
drop TEMP_ATT WDSP_ATT FRSH ;
if var1>239 & var1<815 ;
/*by time;*/
run;

/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */
/* **************************** Hodrick-prescot filter -> cycle extraction ******************************* */
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */

/***** QBO already in cycle : nothing to extract *****/

/******************************************************/
/*** SIMPLE REGRESSION AND HETEROSKEDASTICITY TESTS ***/
PROC CONTENTS DATA=Memoire1.Meteo_sync;
RUN;
*linear model;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL TEMP = PRCP WDSP fifty twenty ;
RUN;
QUIT;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL PRCP = TEMP WDSP fifty twenty ;
RUN;
QUIT;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL WDSP = TEMP PRCP WDSP fifty ;
RUN;
QUIT;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL twenty = TEMP PRCP WDSP fifty ;
RUN;
QUIT;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL fifty = PRCP WDSP TEMP twenty ;
RUN;
QUIT;

*heteroskedasticity and White;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL TEMP = PRCP WDSP fifty twenty  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL PRCP = TEMP WDSP fifty twenty  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL WDSP = TEMP PRCP WDSP fifty  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL twenty = TEMP PRCP WDSP fifty  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_sync;
	MODEL fifty = PRCP WDSP TEMP twenty /SPEC WHITE;
RUN;

*heteroskedasticity and White;
PROC REG DATA=Memoire1.Meteo_pm;
	MODEL r_temp = r_PRCP r_WDSP r_f50 r_t20  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_pm;
	MODEL r_PRCP = r_TEMP r_WDSP r_f50 r_t20  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_pm;
	MODEL r_WDSP = r_TEMP r_PRCP r_WDSP r_f50 r_t20  /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_pm;
	MODEL r_t20 = r_TEMP r_PRCP r_WDSP r_f50 /SPEC WHITE;
RUN;
PROC REG DATA=Memoire1.Meteo_pm;
	MODEL r_f50 = r_PRCP r_WDSP r_TEMP  r_t20/SPEC WHITE;
RUN;
/******************************************************/


/* ******************* W/ PROC UCM ******************* */

/******************** Temperatures ********************/

proc ucm data=Memoire1.Meteo_sync;
id dateok interval=month; 
irregular plot=smooth; 
level plot=smooth var=0 noest ; 
slope plot=smooth var=6.94e-5; /*Hodrick-Prescott's filter : 6.94e-5 = 1/14400 (14400 reference variance associated to the slope)*/
model TEMP;
forecast outfor=Memoire1.TEMP_Cycle(rename=(S_IRREG = TEMP_smooth S_SLOPE = TEMP_Slope)); /*OUT : Irregular component i.e. residuals & Slope*/
run;
/*To select only the statistics we are interested in*/
proc sql;
   create table Memoire1.TEMP_cyc as
      select dateok, TEMP_smooth, TEMP_Slope
      from Memoire1.TEMP_Cycle;
quit;

/******************** Precipitations ********************/

proc ucm data=Memoire1.Meteo_sync;
id dateok interval=month; 
irregular plot=smooth; 
level plot=smooth  var=0 noest ; 
slope plot=smooth var=6.94e-5;
model PRCP;
forecast outfor=Memoire1.PRCP_Cycle(rename=(S_IRREG = PRCP_smooth S_SLOPE = PRCP_Slope));
run;

proc sql;
   create table Memoire1.PRCP_cyc as
      select dateok, PRCP_smooth, PRCP_Slope
      from Memoire1.PRCP_Cycle;
quit;

/******************** Wind Speed ********************/

proc ucm data=Memoire1.Meteo_sync;
id dateok interval=month; 
irregular plot=smooth; 
level plot=smooth var=0 noest ; 
slope plot=smooth var=6.94e-5;
model WDSP;
forecast outfor=Memoire1.WDSP_Cycle(rename=(S_IRREG = WDSP_smooth S_SLOPE = WDSP_Slope));
run;

proc sql;
   create table Memoire1.WDSP_cyc as
      select dateok, WDSP_smooth, WDSP_Slope
      from Memoire1.WDSP_Cycle;
quit;

/******************** Fifty hPaN QBO ********************/

proc ucm data=Memoire1.Meteo_sync;
id dateok interval=month; 
irregular plot=smooth; 
level plot=smooth var=0 noest ; 
slope plot=smooth var=6.94e-5;
model fifty;
forecast outfor=Memoire1.F50_Cycle(rename=(S_IRREG = F50_smooth)); /*OUT : Irregular component i.e. residuals*/
run;

proc sql;
   create table Memoire1.F50_cyc as
      select dateok, F50_smooth
      from Memoire1.F50_Cycle;
quit;

/******************** Twenty hPaN QBO ********************/

proc ucm data=Memoire1.Meteo_sync;
id dateok interval=month; 
irregular plot=smooth; 
level plot=smooth var=0 noest ; 
slope plot=smooth var=6.94e-5;
model twenty;
forecast outfor=Memoire1.T20_Cycle(rename=(S_IRREG = T20_smooth));
run;

proc sql;
   create table Memoire1.T20_cyc as
      select dateok, T20_smooth
      from Memoire1.T20_Cycle;
quit;

/*** CYCLES MERGE in Cycle DATASET ***/

proc sql ;
create table Memoire1.Cycles_ucm as 
select * from Memoire1.WDSP_cyc as X full join Memoire1.PRCP_cyc as Y 
on X.dateok = Y.dateok;
quit; 

proc sql ;
create table Memoire1.Cycle_ucm as 
select * from Memoire1.TEMP_cyc as X full join Memoire1.Cycles_ucm as Y 
on X.dateok = Y.dateok;
quit; 

/*** CYCLE MERGE in the final DATASET ***/
/*** w/ Fifty and Twenty extracted cycles ***/

data Memoire1.Meteo_ucmcyc ;
set Memoire1.Cycle_ucm ;
merge Memoire1.T20_cyc Memoire1.F50_cyc Memoire1.Cycle_ucm ;
run;
/*** w/ Fifty and Twenty time series -> graphical purpose ***/

proc sql ;
create table Memoire1.Meteo_ucm as 
select * from Memoire1.Cycle_ucm as X full join Memoire1.Meteo_sync as Y 
on X.dateok = Y.dateok;
quit; 


/* ******************* W/ PROC EXPAND ******************* */

/*** Our point is to calculate the PBSPLINE and be able to compare PROC UCM w/ EXPAND ***/

/******************** Temperatures ********************/

proc expand data=Memoire1.Meteo_sync out=Memoire1.T_pbspline
method=spline plots=transformout;
	id dateok;
	convert Temp=T_trend / transformout=(hp_t 14400) ; /* Hodrick-Prescott's filter : 14400 reference variance associated to the slope */
	convert Temp=T_cycle / transformout=(hp_c 14400) ; /* Hodrick-Prescott's filter : 14400 reference variance for monthly time series */
run;
/******************** Precipitations ********************/

proc expand data=Memoire1.Meteo_sync out=Memoire1.P_pbspline
method=spline plots=transformout;
	id dateok;
	convert PRCP=P_trend / transformout=(hp_t 14400) ;
	convert PRCP=P_cycle / transformout=(hp_c 14400) ;
run;
/******************** Wind Speed ********************/

proc expand data=Memoire1.Meteo_sync out=Memoire1.W_pbspline
method=spline plots=transformout;
	id dateok;
	convert WDSP=W_trend / transformout=(hp_t 14400) ;
	convert WDSP=W_cycle / transformout=(hp_c 14400) ;
run;
/******************** Fifty hPaN QBO ********************/

proc expand data=Memoire1.Meteo_sync out=Memoire1.F50_pbspline
method=spline plots=transformout;
	id dateok;
	convert fifty=F50_trend / transformout=(hp_t 219000) ; /* Trend result is biased here */
	convert fifty=F50_cycle / transformout=(hp_c 14400) ;
run;
/******************** Twenty hPaN QBO ********************/

proc expand data=Memoire1.Meteo_sync out=Memoire1.T20_pbspline
method=spline plots=transformout;
	id dateok;
	convert twenty=T20_trend / transformout=(hp_t 219000) ; /* Trend result is biased here */
	convert twenty=T20_cycle / transformout=(hp_c 14400) ; 
run;
/*** Merge of the trends and cycles ***/

data Memoire1.Meteo_pbspline ; 
merge Memoire1.T20_pbspline Memoire1.F50_pbspline Memoire1.P_pbspline Memoire1.T_pbspline Memoire1.W_pbspline; 
drop var1 IIIII thirty seventy fourty fifteen ten FRSH ; 
by dateok ; 
run ;


/*** 
	  Get an AR(2) through the cycles : linear regression in t-1 and t-2 using PROC MODEL. 
	We obtain the Residuals -> QBO Cycles & a White Noise for other Cycles. We did it from 
	QBO series, since they already looked like Cycles and UCM/EXPEND didn't add any 
	information here ; from Temperatures, precipitations and Wind-speeds Cycles, since 
	they were extracted with PROC UCM/EXPAND.                                              ***/

/******************** Temperatures residuals ********************/

proc model data = Memoire1.Temp_cyc ; 
TEMP_smooth = a+b*lag(TEMP_smooth)+c*lag2(TEMP_smooth);
fit TEMP_smooth / outresid out=Memoire1.Res_TEMP(rename=(TEMP_smooth = r_temp)) ; 
run ;
/******************** Precipitations residuals ********************/

proc model data = Memoire1.Prcp_cyc ; 
PRCP_smooth = a+b*lag(PRCP_smooth)+c*lag2(PRCP_smooth);
fit PRCP_smooth / outresid out=Memoire1.Res_PRCP(rename=(PRCP_smooth = r_prcp)) ; 
run ;
/******************** Wind Speed residuals *********************/

proc model data = Memoire1.Wdsp_cyc ; 
WDSP_smooth = a+b*lag(WDSP_smooth)+c*lag2(WDSP_smooth);
fit WDSP_smooth / outresid out=Memoire1.Res_WDSP(rename=(WDSP_smooth = r_wdsp)) ; 
run ;
/******************** Fifty hPaN QBO ********************/

proc model data = Memoire1.Meteo_sync ; 
fifty = a+b*lag(fifty)+c*lag2(fifty);
fit fifty /outresid out = Memoire1.Res_fifty(rename=(fifty=r_f50)); 
run ;
/******************** Twenty hPaN QBO ********************/

proc model data = Memoire1.Meteo_sync ; 
twenty = a+b*lag(twenty)+c*lag2(twenty);
fit twenty /outresid out = Memoire1.Res_twenty(rename=(twenty=r_t20));
run ;
quit ;
/*** Merge of the residuals & white noises ***/

data Memoire1.Meteo_resid ; 
merge Memoire1.Res_fifty Memoire1.Res_twenty Memoire1.Res_PRCP Memoire1.Res_WDSP Memoire1.Res_TEMP(obs=573); 
run ;
data Memoire1.Meteo_pm ;
merge Memoire1.Meteo_sync Memoire1.Meteo_resid  ;
run ;


/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */
/* *************************************** CYCLES SYNCHRONIZATION **************************************** */
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */


/* ******************* W/ HARDING & PAGAN'S METHOD ******************* */

/* CODES A BIVARIAN WITH IML WHICH RETURNS 1 FOR EXPANSION / 0 FOR RECESSION IN CYCLES */
/* CODES A BIVARIAN WITH IML WHICH RETURNS 1 FOR POSITIVES VALUES / 0 FOR NEGATIVES IN CYCLES */
/* CODES A BIVARIAN WITH IML WHICH RETURNS 1 FOR RETURNMENT DATES / 0 ELSE IN CYCLES */

proc iml;
/********* WRITING DATA FROM METEO_SYNCHRO INTO MATRIX  "MSQ" *********/

use Memoire1.Meteo_Sync ; 
read ALL var {"seventy" "fifty" "fourty" "thirty" "twenty" "fifteen" "ten"} into MSQ; /***!!! NEED TO RETRY THIS WITH ALL hPa !!!***/
close; 

print MSQ;

/* ************** POS = 1, NEG = 0 ************** */

allq=j(nrow(msq),ncol(msq),0);/*Matrix of 0 alone : where we want to set the 0,1*/

do t=1 to nrow(msq);
do s=1 to 7;
if msq[t,s]<0 then allq[t,s]=0; 
if msq[t,s]>0 then allq[t,s]=1;end;
end;
print allq;

proc iml;
/********* WRITING DATA FROM METEO_SYNCHRO INTO MATRIX  "MSQ" *********/

use Memoire1.Meteo_Sync ; 
read ALL var {"seventy" "fifty" "fourty" "thirty" "twenty" "fifteen" "ten"} into MSQ; 
close; 

print MSQ;

allq=j(nrow(msq),ncol(msq),0);/*Matrix of 0 alone : where we want to set the 0,1*/

do t=1 to nrow(msq);
do s=1 to 7;
if msq[t,s]<0 then allq[t,s]=0; 
if msq[t,s]>0 then allq[t,s]=1;end;
end;
print allq;

wa=insert(msp,allq,nrow(msp),ncol(msp)+7);
print wa;

/*** Export of WA to add it into RECESSIONS & EXPANSIONS TABLE from BCDATING in R : Exp_Rec_Pos_Neg ***/

/***************************************************/
/*PROC EXPORT DATA=Memoire1.Meteo_sync
		    DBMS=xlsx
		    OUTFILE="C:\Users\ceecy\PythonScripts\Memoire\DATA\Meteo_sync1.xlsx"  
		    REPLACE;
run;
proc timeseries data=Memoire1.Meteo_sync out=Memoire1.Meteo_ts;
var TEMP PRCP WDSP fifty twenty ; 
run;
PROC EXPORT DATA=Memoire1.Meteo_ts
		    DBMS=csv 
		    OUTFILE="C:\Users\ceecy\PythonScripts\Memoire\DATA\Meteo_ts.csv"  
		    REPLACE;
 		    DELIMITER=",";
run;												*/
/***************************************************/

/*** IMPORT OF TABLES ISSUED FROM BCDATING PACKAGE (ON R) ***/

proc import out = memoire1.Exp_Rec_Pos_Neg
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\EXPREC\Exp_Rec_Pos_Neg.xlsx"
DBMS=XLSX; run;

proc import out = memoire1.ER
datafile= "C:\Users\ceecy\PythonScripts\Memoire\Scripts\BC DATING\Exp_Rec.xlsx"
DBMS=XLSX; run;

proc import out = memoire1.RD
datafile= "C:\Users\ceecy\PythonScripts\Memoire\DATA\RETOURNEMENT\Return_Dates.xlsx"
DBMS=XLSX; run;

proc iml;
/********* WRITING DATA FROM EXP_REC_POS_NEG INTO MATRIX  "EP" *********/

use Memoire1.Exp_Rec_Pos_Neg; 
read ALL var {"Phase_TEMP" "Phase_PRCP" "Phase_WDSP" "fifty" "twenty"} into EP; /***!!! NEED TO TRY THIS WITH ALL hPa !!!***/
close; 

print EP;

/********* WRITING DATA FROM ER (Expansions & Recessions) INTO MATRIX  "ER" *********/

use Memoire1.ER; 
read ALL var {"Phase_TEMP" "Phase_PRCP" "Phase_WDSP" "Phase_50" "Phase_20"} into ER; /***!!! NEED TO TRY THIS WITH ALL hPa !!!***/
close; 

print ER;


/* ******************* JACCARD'S METHOD ******************* */

/* ***** For the Expansions case ***** */

Expansions=j(5,5,0); /*sets a matrix of 0, where we want to put the variance covariance Matrix of Expansions*/
do i=1 to ncol(ER);
	do j=1 to ncol(ER);
	M11=ncol(loc(ER[,i]=1 & ER[,j]=1)); /* 1 at the same time on 2 column mini, 5 column maxi */
	M01=ncol(loc(ER[,i]=0 & ER[,j]=1));
	M10=ncol(loc(ER[,i]=1 & ER[,j]=0));
	M00=ncol(loc(ER[,i]=0 & ER[,j]=0)); /* 0 at the same time on 2 column mini, 5 column maxi */
Expansions[i,j]=M11/(M01+M10+M11);
	end;
end;
print Expansions; /* Variance Covariance Matrix for Expansions */

/* ***** For the Expansions & Positives case ***** */

ExPos=j(5,5,0); /*sets a matrix of 0, where we want to put the variance covariance Matrix of Expansions*/
do i=1 to ncol(EP);
	do j=1 to ncol(EP);
	M11=ncol(loc(EP[,i]=1 & EP[,j]=1)); /* 1 at the same time on 2 column mini, 5 column maxi */
	M01=ncol(loc(EP[,i]=0 & EP[,j]=1));
	M10=ncol(loc(EP[,i]=1 & EP[,j]=0));
	M00=ncol(loc(EP[,i]=0 & EP[,j]=0)); /* 0 at the same time on 2 column mini, 5 column maxi */
ExPos[i,j]=M11/(M01+M10+M11);
	end;
end;
print ExPos; /* Variance Covariance Matrix for Expansions and Positive Phases */

/********* WRITING DATA FROM RD (Retournement Dates) INTO MATRIX  "RD" *********/

use Memoire1.RD; 
read ALL var {"Date_Return_TEMP" "Date_Return_PRCP" "Date_Return_WDSP" "Date_Return_50" "Date_Return_20"} into RD; /***!!! NEED TO TRY THIS WITH ALL hPa !!!***/
close; 

print RD;

/* STEP 2: CODE P(Sx=1)=PSx1 ; P(Sy=1)=PSy1 ; P(Sx=0)=PSx0 ; P(Sy=0)=PSy0 ; P(Sx=1,Sy=1)=PSx1Sy1 ;
   with y and x BOTH CYCLES where Ux - Uy = 0 for Strong Perfect Positive Synchro (SPPS)          */

/* STEP 3: CODE P(Sx=1)=PSx1 ; P(Sy=1)=PSy1 ; P(Sx=0)=PSx0 ; P(Sy=0)=PSy0 ; P(Sx=1,Sy=1)=PSx1Sy1 ; 
   where * PSx1 - PSx1Sy1*rho - PSx1*PSy1 = 0 for SPPS 
         * (1-rho)(PSx1*PSy0) = 0 <-> rho = 1 and Ux = Uy = U when SPPS */
/* Note that : E(x) = (matrix value n°1/575 + ... + matrix value n°575/575) */

/*STEP 4: CODE rho : rho = (PSx1Sy1 - (Psx1 * Psy1)) / (sqrt(Psx1 * Psx0) * sqrt(Psy1 * Psy0)) */

rho=j(5,5,0); /*sets a matrix of 0, where we want to put the variance covariance Matrix of Expansions*/

do i=1 to ncol(ER);	
do j=1 to ncol(ER);	
	Sx1Sy1=loc(ER[,i]=1 & ER[,j]=1);	
	Sx1=loc(ER[,i]=1);	
	Sx0=loc(ER[,i]=0);	
	Sy1=loc(ER[,j]=1);	
	Sy0=loc(ER[,j]=0);	
	PSx1Sy1=ncol(Sx1Sy1)/nrow(ER);	
	PSx1=ncol(Sx1)/nrow(ER);	
	PSx0=ncol(Sx0)/nrow(ER);	
	PSy1=ncol(Sy1)/nrow(ER);	
	PSy0=ncol(Sy0)/nrow(ER);
	rho[i,j]=(PSx1Sy1-(Psx1*Psy1))/(sqrt(Psx1*Psx0)*sqrt(Psy1*Psy0));
end;
end;
print rho;

/* STEP 5: CODE ConcI : ConcI = 1 + 2*P*sqrt(Ux(Ux1))*sqrt(Uy(Uy1))+2*Ux*Uy-Ux-Uy */

ConcI=j(5,5,0); /*sets a matrix of 0, where we want to put the variance covariance Matrix of Expansions*/
PSx1=j(1,5,0);
PSy1=j(1,5,0);
PSx0=j(1,5,0);
PSy0=j(1,5,0);
PSx1Sy1=j(1,5,0);
do i=1 to ncol(ER);	
do j=1 to ncol(ER);	
	Sx1Sy1=loc(ER[,i]=1 & ER[,j]=1);	
	Sx1=loc(ER[,i]=1);	
	Sx0=loc(ER[,i]=0);	
	Sy1=loc(ER[,j]=1);	
	Sy0=loc(ER[,j]=0);	
	PSx1Sy1[1,i]=ncol(Sx1Sy1)/nrow(ER);	
	PSx1[1,i]=ncol(Sx1)/nrow(ER);	
	PSx0[1,i]=ncol(Sx0)/nrow(ER);	
	PSy1[1,j]=ncol(Sy1)/nrow(ER);	
	PSy0[1,j]=ncol(Sy0)/nrow(ER);
	ConcI[i,j]=(ER[,i]`*ER[,j]+(1-ER[,i])`*(1-ER[,j]))/nrow(ER);
end;
end;
print ConcI;
print PSx1;
print PSx0;
print PSy1;
print PSy0;
print PSx1Sy1;

proc iml;
M=j(nrow(ER),ncol(ER),0);
print M; 
SM=sum(M[,1]) ;
SN=sum(M[,2]) ;
SV=sum(M[,3]) ;
SW=sum(M[,4]) ;
SG=sum(M[,5]) ;
print SM;
print SN;
print SV;
print SW;
print SG;


/* ******************* CREATION OF TEMPO SERIES with PROC TIMESERIES ******************* */

/****** ******* FOR GLOBAL SYNCHRONIZATION ******* ******/

proc timeseries data=Memoire1.Meteo_pm out=Memoire1.CCMeteo_pm;
var r_t20 r_f50 r_temp r_prcp r_wdsp ; 
run;

/* *** To calculate cross-correlation -> CAUSALITY & LAG : time delay of the synchronization *** */

/* TEMP FIFTY comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCTF(rename=(CCF=CCTF)); /* Calculates the cross-correlation & OUT in CC */
var r_temp; 
crossvar  r_f50; 
crosscorr lag n ccf ccfprob; /*crosscorrelation, lag, nomber of used data, ccf : crossed-correlation, ccfprob : probability of ccf -> pvalue .*/
run; 
/* PRCP FIFTY comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPF(rename=(CCF=CCPF)); 
var r_prcp; 
crossvar  r_f50; 
crosscorr lag n ccf ccfprob;
run; 
/* WDSP FIFTY comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCWF(rename=(CCF=CCWF)); 
var r_wdsp; 
crossvar  r_f50; 
crosscorr lag n ccf ccfprob;
run; 
/* PRCP WDSP comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPW(rename=(CCF=CCPW)); 
var r_prcp; 
crossvar  r_wdsp; 
crosscorr lag n ccf ccfprob; 
run; 
/* TEMP WDSP comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCTW(rename=(CCF=CCTW)); 
var r_temp; 
crossvar  r_wdsp; 
crosscorr lag n ccf ccfprob; 
run; 
/* PRCP TEMP comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPT(rename=(CCF=CCPT)); 
var r_prcp; 
crossvar  r_temp; 
crosscorr lag n ccf ccfprob; 
run; 
/* FIFTY TWENTY comparison */

proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCFT(rename=(CCF=CCFT)); 
var r_f50; 
crossvar  r_t20; 
crosscorr lag n ccf ccfprob;
run; 


/* ********* MERGE OF TIME SERIES & EXPANSION-RECESSIONS ********* */

data Memoire1.BarCode;
merge memoire1.ER Memoire1.Meteo_sync;
by dateok ; 
run;

/*ON GARDE ???????????????????????????????????????????*/

/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */
/* *************************************** Cycles Synchronization **************************************** */
/* §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ */


/*************** CREATION OF TEMPO SERIES with PROC MODEL ***************/
/****** ******* FOR GLOBAL SYNCHRO ******* ******/

proc timeseries data=Memoire1.Meteo_pm out=Memoire1.CCMeteo_pm;
var r_t20 r_f50 r_temp r_prcp r_wdsp ; /*choisir une ou deux altitudes de vents optimales */
run;

/* *** To calculate cross-correlation & put it in CC *** */

/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCTF(rename=(CCF=CCTF)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_temp; 
crossvar  r_f50; /* TEMP FIFTY compareason */
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPF(rename=(CCF=CCPF)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_prcp; 
crossvar  r_f50; /* PRCP FIFTY compareason */
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCWF(rename=(CCF=CCWF)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_wdsp; 
crossvar  r_f50; /* WDSP FIFTY compareason */
crosscorr lag n ccf n ccfprob ;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPW(rename=(CCF=CCPW)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_prcp; 
crossvar  r_wdsp; /* PRCP WDSP compareason */
crosscorr lag n ccf; /*crosscorrélation, lag, nombre de donnée utilisée, ccov : crosscovariance, ccf : corrélation croisée.*/
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCTW(rename=(CCF=CCTW)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_temp; 
crossvar  r_wdsp; /* TEMP WDSP compareason */
crosscorr lag n ccf; 
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCPT(rename=(CCF=CCPT)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_prcp; 
crossvar  r_temp; /* PRCP TEMP compareason */
crosscorr lag n ccf; 
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_pm OUTCROSSCORR=Memoire1.CCFT(rename=(CCF=CCFT)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var r_f50; 
crossvar  r_t20; /* fifty twenty compareason */
crosscorr lag n ccf n ccfprob;
run; 

/*** Merge of the cross-correlations w/Proc Model ***/ /*renommer chaque cross corr avant de pouvoir merge*/
data Memoire1.CC_pm ; 
merge Memoire1.CCFT Memoire1.CCPW Memoire1.CCTW Memoire1.CCPT Memoire1.CCTF Memoire1.CCPF Memoire1.CCWF ; 
by LAG ;
drop _NAME_ _CROSS_ ;
run ;

/*************** CREATION OF TEMPO SERIES with UCM FOR GLOBAL SYNCHRO ***************/
proc timeseries data=Memoire1.Meteo_ucm out=Memoire1.CCMeteo_ucm;
var TEMP_smooth PRCP_smooth WDSP_smooth fifty twenty; /*choisir une ou deux altitudes de vents optimales ?? */
run;
/* *** To calculate cross-correlation & put it in CC *** */

/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCFTucm(rename=(CCF=CCFTucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var fifty; 
crossvar  twenty; /* fifty twenty compareason */
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCPWucm(rename=(CCF=CCPWucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var PRCP_smooth; 
crossvar  WDSP_smooth; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCPTucm(rename=(CCF=CCPTucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var PRCP_smooth; 
crossvar  TEMP_smooth; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCTWucm(rename=(CCF=CCTWucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var TEMP_smooth; 
crossvar WDSP_smooth;
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCTFucm(rename=(CCF=CCTFucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var TEMP_smooth; 
crossvar  fifty; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCWFucm(rename=(CCF=CCWFucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var WDSP_smooth; 
crossvar fifty; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_ucm OUTCROSSCORR=Memoire1.CCPFucm(rename=(CCF=CCPFucm)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var PRCP_smooth; 
crossvar fifty; 
crosscorr lag n ccf;
run; 

/*** Merge of the cross-correlations w/UCM ***/ /*renommer chaque cross corr avant de pouvoir merge*/
data Memoire1.CC_ucm ; 
merge Memoire1.CCFTucm Memoire1.CCPWucm Memoire1.CCTWucm Memoire1.CCPTucm Memoire1.CCTFucm Memoire1.CCPFucm Memoire1.CCWFucm ;
drop _NAME_ _CROSS_ ; 
run ;

/*************** CREATION OF TEMPO SERIES with EXP FOR GLOBAL SYNCHRO ***************/
proc timeseries data=Memoire1.Meteo_pbspline out=Memoire1.CCMeteo_exp;
var P_trend T_trend W_trend F50_trend T20_trend ; 
run;
/* *** To calculate cross-correlation & put it in CC *** */
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCPWexp(rename=(CCF=CCPWexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var P_trend;
crossvar W_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCTWexp(rename=(CCF=CCTWexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var T_trend;
crossvar W_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCPTexp(rename=(CCF=CCPTexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var P_trend;
crossvar T_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCTFexp(rename=(CCF=CCTFexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var T_trend;
crossvar F50_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCPFexp(rename=(CCF=CCPFexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var P_trend;
crossvar F50_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCWFexp(rename=(CCF=CCWFexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var W_trend;
crossvar F50_trend; 
crosscorr lag n ccf;
run; 
/***!!!***/
proc timeseries data=Memoire1.CCMeteo_exp OUTCROSSCORR=Memoire1.CCFTexp(rename=(CCF=CCFTexp)); /* Permet de calculer la cross-correlation et la mettre dans CC */
var F50_trend;
crossvar T20_trend; 
crosscorr lag n ccf;
run; 
/*** Merge of the cross-correlations w/EXP ***/ /*renommer chaque cross corr avant de pouvoir merge*/
data Memoire1.CC_exp ; 
merge Memoire1.CCFTexp Memoire1.CCPWexp Memoire1.CCTWexp Memoire1.CCPTexp Memoire1.CCTFexp Memoire1.CCPFexp Memoire1.CCWFexp ; 
by LAG ;
drop _NAME_ _CROSS_ ;
run ;

/*** Pour faire graphique de comparaison entre proc expand et proc model (sur les variables TEMP, PRCP, WDSP, Fifty & Twenty ***/
data Memoire1.EM_comparaison ; 
merge Memoire1.Meteo_pbspline Memoire1.Meteo_resid ; 
run ;
proc template;
define statgraph Graph3;
dynamic _DATEOK _F50_CYCLE _DATEOK2 _R_F50A _DATEOK3 _T_CYCLE _DATEOK4 _R_TEMP _DATEOK5 _DATEOK6 _R_PRCP2 _P_CYCLE _DATEOK7 _R_WDSP _DATEOK8 _W_CYCLE _DATEOK9 _R_T20A _DATEOK10 _T20_CYCLE;
begingraph / designwidth=945 designheight=674;
   layout lattice / rowdatarange=data columndatarange=data rows=3 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 50hPa'));
         seriesplot x=_DATEOK y=_F50_CYCLE / name='series' legendlabel='PROC EXPAND' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK2 y=_R_F50A / name='series2' legendlabel='PROC MODEL' connectorder=xaxis lineattrs=(color=CX639A21 );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12783.999999999998 14610.0 16437.0 18263.0 20089.0 21914.999999999996))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Precipitations'));
         seriesplot x=_DATEOK5 y=_P_CYCLE / name='series5' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK6 y=_R_PRCP2 / name='series6' legendlabel='r_prcp' connectorder=xaxis lineattrs=(color=CX639A21 );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Temperatures'));
         seriesplot x=_DATEOK3 y=_T_CYCLE / name='series3' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK4 y=_R_TEMP / name='series4' legendlabel='r_temp' connectorder=xaxis lineattrs=(color=CX639A21 );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12783.999999999998 14610.0 16437.0 18263.0 20089.0 21914.999999999996))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds'));
         seriesplot x=_DATEOK7 y=_R_WDSP / name='series7' legendlabel='r_wdsp' connectorder=xaxis lineattrs=(color=CX639A21 );
         seriesplot x=_DATEOK8 y=_W_CYCLE / name='series8' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 20hPa'));
         seriesplot x=_DATEOK9 y=_R_T20A / name='series9' connectorder=xaxis lineattrs=(color=CX639A21 );
         seriesplot x=_DATEOK10 y=_T20_CYCLE / name='series10' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay;
         entry _id='dropsite4' halign=center '(drop a plot here...)' / valign=center;
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series' 'series2' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.EM_COMPARAISON template=Graph3;
dynamic _DATEOK="DATEOK" _F50_CYCLE="'F50_CYCLE'n" _DATEOK2="DATEOK" _R_F50A="'R_F50'n" _DATEOK3="DATEOK" _T_CYCLE="'T_CYCLE'n" _DATEOK4="DATEOK" _R_TEMP="'R_TEMP'n" _DATEOK5="DATEOK" _DATEOK6="DATEOK" _R_PRCP2="'R_PRCP'n" _P_CYCLE="'P_CYCLE'n" _DATEOK7="DATEOK" _R_WDSP="'R_WDSP'n" _DATEOK8="DATEOK" _W_CYCLE="'W_CYCLE'n" _DATEOK9="DATEOK" _R_T20A="'R_T20'n" _DATEOK10="DATEOK" _T20_CYCLE="'T20_CYCLE'n";
run;


/*** Pour faire graphique de comparaison entre proc ucm et proc expand (sur la variable TEMPS) ***/
data Memoire1.HP_comparaison ; 
merge Memoire1.Meteo_pbspline Memoire1.Meteo_ucmcyc ; 
run ;
proc template;
define statgraph sgdesign;
dynamic _DATEOK _F50_SMOOTH _DATEOK2 _F50_CYCLE _DATEOK3 _T20_SMOOTH _DATEOK4 _T20_CYCLE _DATEOK5 _PRCP_SMOOTH _DATEOK6 _P_CYCLE _DATEOK7 _WDSP_SMOOTH _DATEOK8 _W_CYCLE _DATEOK9 _TEMP_SMOOTH _DATEOK10 _T_CYCLE;
begingraph / designwidth=1142 designheight=680;
   entryfootnote halign=left ' ';
   layout lattice / rowdatarange=data columndatarange=data rows=3 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0 1.0 1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 50hPa'));
         seriesplot x=_DATEOK y=_F50_SMOOTH / name='series' legendlabel='PROC UCM' connectorder=xaxis lineattrs=(color=CXFFCB63 );
         seriesplot x=_DATEOK2 y=_F50_CYCLE / name='series2' legendlabel='PROC EXPAND' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Precipitations'));
         seriesplot x=_DATEOK5 y=_PRCP_SMOOTH / name='series5' legendlabel='PRCP_smooth' connectorder=xaxis lineattrs=(color=CXFFCB63 );
         seriesplot x=_DATEOK6 y=_P_CYCLE / name='series6' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 20hPa'));
         seriesplot x=_DATEOK3 y=_T20_SMOOTH / name='series3' legendlabel='T20_smooth' connectorder=xaxis lineattrs=(color=CXFFCB63 );
         seriesplot x=_DATEOK4 y=_T20_CYCLE / name='series4' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind-speeds'));
         seriesplot x=_DATEOK7 y=_WDSP_SMOOTH / name='series7' legendlabel='WDSP_smooth' connectorder=xaxis lineattrs=(color=CXFFCB63 );
         seriesplot x=_DATEOK8 y=_W_CYCLE / name='series8' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Temperatures'));
         seriesplot x=_DATEOK9 y=_TEMP_SMOOTH / name='series9' connectorder=xaxis lineattrs=(color=CXFFCB63 );
         seriesplot x=_DATEOK10 y=_T_CYCLE / name='series10' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay;
         entry _id='dropsite4' halign=center '(drop a plot here...)' / valign=center;
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series' 'series2' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.HP_COMPARAISON template=sgdesign;
dynamic _DATEOK="DATEOK" _F50_SMOOTH="'F50_SMOOTH'n" _DATEOK2="DATEOK" _F50_CYCLE="'F50_CYCLE'n" _DATEOK3="DATEOK" _T20_SMOOTH="'T20_SMOOTH'n" _DATEOK4="DATEOK" _T20_CYCLE="'T20_CYCLE'n" _DATEOK5="DATEOK" _PRCP_SMOOTH="'PRCP_SMOOTH'n" _DATEOK6="DATEOK" _P_CYCLE="'P_CYCLE'n" _DATEOK7="DATEOK" _WDSP_SMOOTH="'WDSP_SMOOTH'n" _DATEOK8="DATEOK" _W_CYCLE="'W_CYCLE'n" _DATEOK9="DATEOK" _TEMP_SMOOTH="'TEMP_SMOOTH'n" _DATEOK10="DATEOK" _T_CYCLE="'T_CYCLE'n";
run;

proc template;
define statgraph sgdesign;
dynamic _DATEOK _F50_TREND _DATEOK2 _F50_CYCLE _DATEOK3 _FIFTY _DATEOK4 _PRCP _DATEOK5 _P_CYCLE _DATEOK6 _P_TREND _DATEOK7 _DATEOK8 _DATEOK9 _DATEOK10 _WDSP _DATEOK11 _W_TREND _DATEOK12 _W_CYCLE _TWENTY _T20_CYCLE _T20_TREND;
begingraph / designwidth=1122 designheight=716;
   entryfootnote halign=left ' ';
   layout lattice / rowdatarange=data columndatarange=data rows=2 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0 1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 20hPa'));
         seriesplot x=_DATEOK7 y=_TWENTY / name='series7' legendlabel='SERIES' datatransparency=0.77 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK8 y=_T20_CYCLE / name='series8' legendlabel='PROC EXPAND CYCLES' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK9 y=_T20_TREND / name='series9' legendlabel='TRENDS' connectorder=xaxis;
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds'));
         seriesplot x=_DATEOK10 y=_WDSP / name='series10' datatransparency=0.74 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK11 y=_W_TREND / name='series11' connectorder=xaxis;
         seriesplot x=_DATEOK12 y=_W_CYCLE / name='series12' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( minorticks=OFF tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 50hPa'));
         seriesplot x=_DATEOK y=_F50_TREND / name='series' connectorder=xaxis;
         seriesplot x=_DATEOK2 y=_F50_CYCLE / name='series2' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK3 y=_FIFTY / name='series3' datatransparency=0.75 connectorder=xaxis lineattrs=(color=CXCE5539 );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Precipitations'));
         seriesplot x=_DATEOK4 y=_PRCP / name='series4' datatransparency=0.66 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK5 y=_P_CYCLE / name='series5' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK6 y=_P_TREND / name='series6' connectorder=xaxis lineattrs=(thickness=1 );
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series7' 'series8' 'series9' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.METEO_PBSPLINE template=sgdesign;
dynamic _DATEOK="DATEOK" _F50_TREND="'F50_TREND'n" _DATEOK2="DATEOK" _F50_CYCLE="'F50_CYCLE'n" _DATEOK3="DATEOK" _FIFTY="FIFTY" _DATEOK4="DATEOK" _PRCP="PRCP" _DATEOK5="DATEOK" _P_CYCLE="'P_CYCLE'n" _DATEOK6="DATEOK" _P_TREND="'P_TREND'n" _DATEOK7="DATEOK" _DATEOK8="DATEOK" _DATEOK9="DATEOK" _DATEOK10="DATEOK" _WDSP="WDSP" _DATEOK11="DATEOK" _W_TREND="'W_TREND'n" _DATEOK12="DATEOK" _W_CYCLE="'W_CYCLE'n" _TWENTY="TWENTY" _T20_CYCLE="'T20_CYCLE'n" _T20_TREND="'T20_TREND'n";
run;
proc template;
define statgraph sgdesign;
dynamic _DATEOK13 _TEMP _DATEOK15 _T_TREND _DATEOK _T_CYCLE;
begingraph / designwidth=1122 designheight=407;
   entryfootnote halign=left ' ';
   layout lattice / rowdatarange=data columndatarange=data rows=1 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Temperatures'));
         seriesplot x=_DATEOK13 y=_TEMP / name='series13' legendlabel='SERIE' datatransparency=0.71 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK15 y=_T_TREND / name='series15' connectorder=xaxis;
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.000000000004 21915.0))) yaxisopts=( label=('Temperatures'));
         seriesplot x=_DATEOK y=_T_CYCLE / name='series' legendlabel='PROC MODEL CYCLE' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series13' 'series' / opaque=true border=true halign=center valign=center displayclipped=true;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.HP_COMPARAISON template=sgdesign;
dynamic _DATEOK13="DATEOK" _TEMP="TEMP" _DATEOK15="DATEOK" _T_TREND="'T_TREND'n" _DATEOK="DATEOK" _T_CYCLE="'T_CYCLE'n";
run;

proc template;
define statgraph sgdesign;
dynamic _DATEOK13 _TEMP _DATEOK15 _T_TREND _DATEOK _T_CYCLE _DATEOK2 _PRCP _DATEOK3 _P_TREND _DATEOK4 _P_CYCLE _DATEOK5 _WDSP _DATEOK6 _W_TREND _DATEOK7 _W_CYCLE;
begingraph / designwidth=1122 designheight=739;
   entryfootnote halign=left ' ';
   layout lattice / rowdatarange=data columndatarange=data rows=2 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0 1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( label=('Precipitations'));
         seriesplot x=_DATEOK2 y=_PRCP / name='series2' datatransparency=0.75 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK3 y=_P_TREND / name='series3' legendlabel='TRENDS' connectorder=xaxis;
         seriesplot x=_DATEOK4 y=_P_CYCLE / name='series4' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( label=('Wind speeds'));
         seriesplot x=_DATEOK5 y=_WDSP / name='series5' datatransparency=0.75 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK6 y=_W_TREND / name='series6' connectorder=xaxis;
         seriesplot x=_DATEOK7 y=_W_CYCLE / name='series7' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Temperatures'));
         seriesplot x=_DATEOK13 y=_TEMP / name='series13' legendlabel='SERIES' datatransparency=0.71 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK15 y=_T_TREND / name='series15' connectorder=xaxis;
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.000000000004 21915.0))) yaxisopts=( label=('Temperatures'));
         seriesplot x=_DATEOK y=_T_CYCLE / name='series' legendlabel='PROC MODEL CYCLES' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series13' 'series' 'series3' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.HP_COMPARAISON template=sgdesign;
dynamic _DATEOK13="DATEOK" _TEMP="TEMP" _DATEOK15="DATEOK" _T_TREND="'T_TREND'n" _DATEOK="DATEOK" _T_CYCLE="'T_CYCLE'n" _DATEOK2="DATEOK" _PRCP="PRCP" _DATEOK3="DATEOK" _P_TREND="'P_TREND'n" _DATEOK4="DATEOK" _P_CYCLE="'P_CYCLE'n" _DATEOK5="DATEOK" _WDSP="WDSP" _DATEOK6="DATEOK" _W_TREND="'W_TREND'n" _DATEOK7="DATEOK" _W_CYCLE="'W_CYCLE'n";
run;
proc template;
define statgraph sgdesign;
dynamic _DATEOK7 _DATEOK8 _DATEOK9 _DATEOK11 _TWENTY _T20_CYCLE _T20_TREND _FIFTY2 _DATEOK10 _F50_TREND2 _DATEOK12 _F50_CYCLE2;
begingraph / designwidth=1122 designheight=418;
   entryfootnote halign=left ' ';
   layout lattice / rowdatarange=data columndatarange=data rows=1 columns=2 rowgutter=10 columngutter=10 rowweights=(1.0) columnweights=(1.0 1.0);
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 50hPa'));
         seriesplot x=_DATEOK11 y=_FIFTY2 / name='series11' datatransparency=0.75 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK10 y=_F50_TREND2 / name='series10' connectorder=xaxis;
         seriesplot x=_DATEOK12 y=_F50_CYCLE2 / name='series12' connectorder=xaxis lineattrs=(color=CX5A518C );
      endlayout;
      layout overlay / xaxisopts=( label=('Months') timeopts=( tickvaluepriority=TRUE tickvalueformat=YEAR4. tickvaluelist=(5479.0 7305.0 9132.0 10958.0 12784.0 14610.0 16437.0 18263.0 20089.0 21915.0))) yaxisopts=( display=(TICKS TICKVALUES LINE LABEL ) label=('Wind speeds at 20hPa'));
         seriesplot x=_DATEOK7 y=_TWENTY / name='series7' legendlabel='SERIES' datatransparency=0.77 connectorder=xaxis lineattrs=(color=CXCE5539 );
         seriesplot x=_DATEOK8 y=_T20_CYCLE / name='series8' legendlabel='PROC EXPAND CYCLES' connectorder=xaxis lineattrs=(color=CX5A518C );
         seriesplot x=_DATEOK9 y=_T20_TREND / name='series9' legendlabel='TRENDS' connectorder=xaxis;
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'series7' 'series8' 'series9' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=MEMOIRE1.METEO_PBSPLINE template=sgdesign;
dynamic _DATEOK7="DATEOK" _DATEOK8="DATEOK" _DATEOK9="DATEOK" _DATEOK11="DATEOK" _TWENTY="TWENTY" _T20_CYCLE="'T20_CYCLE'n" _T20_TREND="'T20_TREND'n" _FIFTY2="FIFTY" _DATEOK10="DATEOK" _F50_TREND2="'F50_TREND'n" _DATEOK12="DATEOK" _F50_CYCLE2="'F50_CYCLE'n";
run;
