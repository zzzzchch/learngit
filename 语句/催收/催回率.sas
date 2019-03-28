
/****需先跑中间表-日终绑定关系表****/

option compress = yes validvarname = any;


libname repayfin "D:\share\Datamart\中间表\repayAnalysis";
libname approval "D:\share\Datamart\原表\approval";
libname account 'D:\share\Datamart\原表\account';
libname csdata 'D:\share\Datamart\原表\csdata';
libname res  'D:\share\Datamart\原表\res';
option compress = yes validvarname = any;
libname acco odbc database=account_nf;

x "D:\share\催收类\催回率\催回率及实收统计.xlsx"; 

proc import datafile="D:\share\催收类\MTD\米粒报表配置表.xls"
out=mmlist_8_3 dbms=excel replace;
SHEET="催回率";
scantext=no;
getnames=yes;
run;

proc import datafile="D:\share\催收类\催回率\3月客户明细M2-M3.xlsx"
out=mmlist_3_1_a dbms=excel replace;
SHEET="sheet1";
scantext=no;
getnames=yes;
run;

%include "C:\Users\TS\learngit\语句\催收\催回率-逻辑.sas";
