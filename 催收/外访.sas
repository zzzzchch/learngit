libname csdata 'D:\share\Datamart\原表\csdata';
libname account 'D:\share\Datamart\原表\account';
libname res "D:\share\Datamart\原表\res";
option compress = yes validvarname = any;
libname repayfin 'D:\share\Datamart\中间表\repayAnalysis';

x 'D:\share\催收类\外访\外访案件分配及催回率.xlsx';

data aa;
format dt yymmdd10.;
 dt = today() - 1;
 if month(dt)=month(dt-2) then 
 db=intnx("month",dt,0,"b");
 else if weekday(dt)=1 then
db=intnx("month",dt-2,0,"b");
else db=intnx("month",dt,0,"b");
dbpe=intnx("month",dt,0,"b")-1;
/*dt=mdy(9,30,2017);*/
/*db=mdy(9,1,2017);*/
 nd = dt-db;
if weekday(dt)=1 then do;weekf=intnx('week',dt,-1)+1;end;
	else do; weekf=intnx('week',dt,0)+1;end;
call symput("dbpe", dbpe);
call symput("nd", nd);
call symput("db",db);
call symput("dt",dt);
call symput("weekf",weekf);
run;


proc import datafile="D:\share\催收类\MTD\米粒报表配置表.xls"
out=kanr_visit6 dbms=excel replace;
SHEET="外访";
scantext=no;
getnames=yes;
run;

%include "D:\share\催收类\外访\外访_逻辑.sas";
