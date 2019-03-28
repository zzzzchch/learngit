*这里以分配日期为准来匹配人头，会存在分配但不打电话就还钱的客户;
*存在当天(第一天！)在建伟账户，建伟给下一个人;
*催收员间的转件在流入指标应该是没问题的,流出就没办法，只能要技术部添加新的标签了，因为目前贴标签是基于已有的变量值，流出当时是没有直接的变量使用;
*确定一下流入的天数(多数就好），然后用来测算流失（30天在流入的时候算分母）;
*test_lr_e的流入概念都是针对ASSIGN_EMP_ID^="CS_SYS"，也就是这个字段只使用具体的业务员，相应的权限账户的ASSIGN_EMP_ID肯定="CS_SYS";
*Ctl_task_assign中的status;
*0：未分配
*1：每日新案件
*2：进行中的任务
*3：任务已完成
*-1：代表这个流程已经关闭
*-2:流程已经关闭，任务已被调整;
*催收系统在逾期第4天的时候会分件到组长手里，第31天会分件到组长(玉萍)手里，中间再有的话可能是初版外包周期结束等其他原因;
*外包时间区间竟然会发生重叠，手动修改上一笔外包的结束日期！;


/****需先跑中间表-流入表****/

option compress = yes validvarname = any;
libname account 'D:\share\Datamart\原表\account';
libname csdata 'D:\share\Datamart\原表\csdata';
libname res  'D:\share\Datamart\原表\res';
libname repayFin "D:\share\Datamart\中间表\repayAnalysis";


x  "D:\share\催收类\MTD\MTD_Collector_Performance.xlsx"; 
x  "D:\share\催收类\MTD\MTD_Collector_Performance-营业部.xlsx"; 


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


proc import datafile="D:\share\催收类\MTD\米粒报表配置表.xls"
out=list dbms=excel replace;
SHEET="电催人员";
scantext=no;
getnames=yes;
run;
data list;
set list;
if 序号="" then delete;
run;
/*名为list的表，去空*/
proc import datafile="D:\share\催收类\MTD\米粒报表配置表.xls"
out=list1 dbms=excel replace;
SHEET="电催营业部";
scantext=no;
getnames=yes;
run;
data list1;
set list1;
if 序号="" then delete;
run;
%include "C:\Users\TS\learngit\语句\催收\MTD-催收日报线下部分.sas";

%include "C:\Users\TS\learngit\语句\催收\MTD-催收日报线下部分+营业部.sas";
