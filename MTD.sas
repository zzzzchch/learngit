*�����Է�������Ϊ׼��ƥ����ͷ������ڷ��䵫����绰�ͻ�Ǯ�Ŀͻ�;
*���ڵ���(��һ�죡)�ڽ�ΰ�˻�����ΰ����һ����;
*����Ա���ת��������ָ��Ӧ����û�����,������û�취��ֻ��Ҫ����������µı�ǩ�ˣ���ΪĿǰ����ǩ�ǻ������еı���ֵ��������ʱ��û��ֱ�ӵı���ʹ��;
*ȷ��һ�����������(�����ͺã���Ȼ������������ʧ��30���������ʱ�����ĸ��;
*test_lr_e�������������ASSIGN_EMP_ID^="CS_SYS"��Ҳ��������ֶ�ֻʹ�þ����ҵ��Ա����Ӧ��Ȩ���˻���ASSIGN_EMP_ID�϶�="CS_SYS";
*Ctl_task_assign�е�status;
*0��δ����
*1��ÿ���°���
*2�������е�����
*3�����������
*-1��������������Ѿ��ر�
*-2:�����Ѿ��رգ������ѱ�����;
*����ϵͳ�����ڵ�4���ʱ���ּ����鳤�����31���ּ����鳤(��Ƽ)����м����еĻ������ǳ���������ڽ���������ԭ��;
*���ʱ�����侹Ȼ�ᷢ���ص����ֶ��޸���һ������Ľ������ڣ�;


/****�������м��-�����****/

option compress = yes validvarname = any;
libname account 'D:\share\Datamart\ԭ��\account';
libname csdata 'D:\share\Datamart\ԭ��\csdata';
libname res  'D:\share\Datamart\ԭ��\res';
libname repayFin "D:\share\Datamart\�м��\repayAnalysis";


x  "D:\share\������\MTD\MTD_Collector_Performance.xlsx"; 
x  "D:\share\������\MTD\MTD_Collector_Performance-Ӫҵ��.xlsx"; 


data _null_;
format dt yymmdd10.;
 dt = today() - 1;
 if month(dt)=month(dt-2) then
 db=intnx("month",dt,0,"b");     
 else if weekday(dt)=1 then
db=intnx("month",dt-2,0,"b");
else db=intnx("month",dt,0,"b");   
/*dt=mdy(9,30,2017);*/
/*db=mdy(9,1,2017);*/
 nd = dt-db;
weekf=intnx('week',dt,0);
call symput("nd", nd);
call symput("db",db);
if weekday(dt)=1 then
call symput("dt",dt-2);
else call symput("dt",dt);
call symput("weekf",weekf);
run;


proc import datafile="D:\share\������\MTD\�����������ñ�.xls"
out=list dbms=excel replace;
SHEET="�����Ա";
scantext=no;
getnames=yes;
run;
data list;
set list;
if ���="" then delete;
run;
/*��Ϊlist�ı�ȥ��*/
proc import datafile="D:\share\������\MTD\�����������ñ�.xls"
out=list1 dbms=excel replace;
SHEET="���Ӫҵ��";
scantext=no;
getnames=yes;
run;
data list1;
set list1;
if ���="" then delete;
run;
%include "C:\Users\TS\learngit\���\����\MTD-�����ձ����²���.sas";

%include "C:\Users\TS\learngit\���\����\MTD-�����ձ����²���+Ӫҵ��.sas";
