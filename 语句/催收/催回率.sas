
/****�������м��-���հ󶨹�ϵ��****/

option compress = yes validvarname = any;


libname repayfin "D:\share\Datamart\�м��\repayAnalysis";
libname approval "D:\share\Datamart\ԭ��\approval";
libname account 'D:\share\Datamart\ԭ��\account';
libname csdata 'D:\share\Datamart\ԭ��\csdata';
libname res  'D:\share\Datamart\ԭ��\res';
option compress = yes validvarname = any;
libname acco odbc database=account_nf;

x "D:\share\������\�߻���\�߻��ʼ�ʵ��ͳ��.xlsx"; 

proc import datafile="D:\share\������\MTD\�����������ñ�.xls"
out=mmlist_8_3 dbms=excel replace;
SHEET="�߻���";
scantext=no;
getnames=yes;
run;

proc import datafile="D:\share\������\�߻���\3�¿ͻ���ϸM2-M3.xlsx"
out=mmlist_3_1_a dbms=excel replace;
SHEET="sheet1";
scantext=no;
getnames=yes;
run;

%include "C:\Users\TS\learngit\���\����\�߻���-�߼�.sas";
