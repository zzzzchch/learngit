libname csdata 'D:\share\Datamart\ԭ��\csdata';
libname account 'D:\share\Datamart\ԭ��\account';
libname res "D:\share\Datamart\ԭ��\res";
option compress = yes validvarname = any;
libname repayfin 'D:\share\Datamart\�м��\repayAnalysis';

x 'D:\share\������\���\��ð������估�߻���.xlsx';

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


proc import datafile="D:\share\������\MTD\�����������ñ�.xls"
out=kanr_visit6 dbms=excel replace;
SHEET="���";
scantext=no;
getnames=yes;
run;

%include "D:\share\������\���\���_�߼�.sas";
