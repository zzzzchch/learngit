option compress = yes validvarname = any;
option missing = 0;
libname account odbc datasrc=account_nf;
libname csdata odbc  datasrc=csdata_nf;
libname res odbc  datasrc=res_nf;


data _null_;
format nt yymmdd10.;
 nt = today() ;
call symput("nt",nt);
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
*拨打全记录;
/*可以把七楼的催收人员数据结合起来*/
proc sql;
create table cs_table1 as
select a.id,a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,
       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME
from csdata.Ctl_call_record as a 
left join csdata.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id
/*a.TASK_ASSIGN_ID=b.id是固定的，a表中的TASK_ASSIGN_ID才是b中的id*/
left join ca_staff as c on b.emp_id=c.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sql;
create table cs_table_ta as
select a.*,b.itemName_zh as RESULT from cs_table1 as a
left join res.optionitem(where=(groupCode="CSJL" or groupCode="YCJG")) as b on a.CALL_RESULT_ID=b.itemCode;
quit;

*只针对OUTBOUND、INBOUND的客户，其他的再说吧，虽然确实有一定的量;
data cs_table1_tab;
set cs_table_ta;
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
联系月份=put(联系日期,yymmn6.);
通话时长_秒=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID in ("OUTBOUND","SMS") then 拨打=1;

if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;

if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;

if username not in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬","白璐","陈侃","陈天森",'黄晓妮','黄丽华') then do;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then 拨打=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还",'无法转告','提醒还款') then 拨通=1;else 拨通=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","无力偿还")) then 联系人=0;else 联系人=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;
end;
run;
proc sort data=cs_table1_tab;by 联系日期;run;
data a;
set cs_table1_tab;
if 联系日期=&nt.;
/*if hour(CREATE_TIME)<10;*/
run;
proc import datafile="D:\share\催收类\MTD\米粒报表配置表.xls"
out=list dbms=excel replace;
SHEET="催收人员";
scantext=no;
getnames=yes;
run;
*拨打;
proc sort data=a   out=dail;by contract_no username  descending 拨打;run;
proc sql;
create table person_dail as
select username,sum(拨打) as dail_sum from dail group by username;quit;

*拨通;*排序无用;
proc sort data=a   out=dail;by contract_no username  descending 拨通;run;
proc sql;
create table person_dail_su as
select username,sum(拨通) as dail_susum from dail group by username;quit;

proc sql;
create table cs_all_d as
select a.序号,a.姓名,b.dail_sum,c.dail_susum from list as a
left join person_dail as b  on a.姓名=b.username
left join person_dail_su as c on a.姓名=c.username;
quit;
proc sort data=cs_all_d;by 序号;run;
/*DDE;*/
x  "D:\share\催收当天通话\mili_collection.xlsx"; 
data tt;
 format y hhmm.;
 y=time();
run;
filename DD DDE 'EXCEL|[mili_collection.xlsx]collect_r!r1c6:r1c6';
data _null_;set tt;file DD;put y  ;run;
filename DD DDE 'EXCEL|[mili_collection.xlsx]collect_r!r5c5:r200c6';
data _null_;
set cs_all_d;
file DD;
put dail_sum dail_susum;
run;


data aaa;
set a;
if userName in("杜盼辉");
run;

PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="杜盼辉"; RUN;

data aaa;
set a;
if userName in("洪高悬");
run;

PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="洪高悬"; RUN;

data aaa;
set a;
if userName in("张政嘉");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="张政嘉"; RUN;

data aaa;
set a;
if userName in("蒋文");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="蒋文"; RUN;

data aaa;
set a;
if userName in("吴振杭");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="吴振杭"; RUN;

data aaa;
set a;
if userName in("邱智超");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="邱智超"; RUN;

data aaa;
set a;
if userName in("陈秀芬");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="陈秀芬"; RUN;

data aaa;
set a;
if userName in("白璐");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="白璐"; RUN;

data aaa;
set a;
if userName in("陈侃");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="陈侃"; RUN;

data aaa;
set a;
if userName in("陈天森");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="陈天森"; RUN;

data aaa;
set a;
if userName in("黄晓妮");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="黄晓妮"; RUN;

data aaa;
set a;
if userName in("丁洁");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="丁洁"; RUN;

data aaa;
set a;
if userName in("吴夏姣");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="吴夏姣"; RUN;

data aaa;
set a;
if userName in("易迁英");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="易迁英"; RUN;

data aaa;
set a;
if userName in("袁明明");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="袁明明"; RUN;

data aaa;
set a;
if userName in("高宏");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="高宏"; RUN;

data aaa;
set a;
if userName in("黄丽华");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\催收当天通话\线下明细.xls" DBMS=EXCEL REPLACE;SHEET="黄丽华"; RUN;

