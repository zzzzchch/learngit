option compress = yes validvarname = any;
libname account 'D:\share\Datamart\原表\account';
libname csdata 'D:\share\Datamart\原表\csdata';
libname res  'D:\share\Datamart\原表\res';
libname repayFin "D:\share\Datamart\中间表\repayAnalysis";


data _null_;
format dt yymmdd10.;
 dt = today() - 1;
 db=intnx("month",dt,0,"b");  * b为beginning，当月月初;
 nd = dt-db;
lastweekf=intnx('week',dt,-1); * 默认为b，上周日;
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("lastweekf",lastweekf);
run;

data a;
format a b c yymmdd10.;
a=&dt.;
b=&lastweekf.;
c=&db;
d=&nd.;
run;

data Ctl_task_assign;
set csdata.Ctl_task_assign(keep=emp_id OVERDUE_LOAN_ID ASSIGN_TIME ASSIGN_EMP_ID status);  * 保留这些字段;
format 分配日期 yymmdd10.;
分配日期=datepart(ASSIGN_TIME); * assign_time的日期部分;
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;

proc sql;
create table kanr( drop=EMP_ID OVERDUE_LOAN_ID ) as 
select a.*,b.userName,d.contract_no  from Ctl_task_assign as a
left join ca_staff as b on a.emp_id=b.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sort data=kanr;by contract_no ASSIGN_TIME descending status;run; * 排序;

data repayfin.kanr;
set kanr;
format 上一个分配日期 yymmdd10.;
上一个分配日期=lag(分配日期);   * 返回上一个观测值;
/*lag函数：返回上一次lage函数运行时的实参
  dif函数：一阶差分=x-lag(x)*/
by contract_no ASSIGN_TIME descending status;
if first.contract_no then 上一个分配日期="";
/*if contract_no^="" and  上一个分配日期=分配日期 and status="-2";*/
if  contract_no^="" and 上一个分配日期=分配日期 and status="-2" then delete;
*-2为案件流转，不算作真正意义上的分配,解决相隔几分钟时间分配，案件在倒数第二个人手中而不是最后一个人手中的问题.部分时候一天只分配给一个人也会有-2标识，此时一般会是该坐席跟,eg:C151754177299802300001437;
if contract_no="C2017092011154429078509" and 分配日期=mdy(11,12,2018) then delete;
if contract_no="C201512181729511817238" and 分配日期=mdy(11,13,2018) then userName="黄晓妮";
if (contract_no="C2017042416144629688676" or contract_no="C2017112409362549464210") and 分配日期=mdy(12,31,2018) then userName="蒋文";
if (contract_no="C2016102812074247312367" or contract_no="C2017092211131164787543") and 分配日期=mdy(12,31,2018) then userName="黄晓妮";
run;
/*数据清洗*/

*删掉何建伟等人会导致部分逾期90+的一直在坐席手里，实际上不在坐席手里，而是去了何老板那里;
/*思考：为什么不引入下一个分配时间，分配时间——下一个分配时间，不就是客户在坐席停留的时间么*/
data kanr_;
set repayfin.kanr;
if username not in ('何建伟','林淑萍','张玉萍');
if kindex(contract_no,"C");
if ASSIGN_EMP_ID^="CS_SYS";
run;
proc sort data=kanr_;by contract_no descending assign_time;run;
proc delete data=assignment;run;
%macro get_payment;
%do i = -61 %to &nd.;
data _null_;
cut_dt = intnx("day", &db., &i.);
call symput("cut_dt", cut_dt);
run;
/*-2月的月初至昨日*/
data macro;
set kanr_(where=(分配日期<=&cut_dt.));
format cut_date yymmdd10.;
cut_date=&cut_dt.;
run;
proc sort data=macro ;by contract_no descending  assign_time;run;
proc sort data=macro nodupkey;by contract_no;run;
proc append data=macro base=assignment;run;
%end;
%mend;
%get_payment;
proc sql;
create table repayFin.assignment1 as
select a.* from assignment as a;
quit;
proc sort data=repayFin.assignment1;by contract_no cut_date ASSIGN_TIME;run;
data test;
set repayFin.assignment1;
lag_userName=lag(userName);
lag_ASSIGN_EMP_ID=lag(ASSIGN_EMP_ID);
by contract_no cut_date;
if first.contract_no then do;lag_userName=userName;lag_ASSIGN_EMP_ID=ASSIGN_EMP_ID;end;
*考虑第一天和非第一天;
if not first.contract_no then do;
	if ASSIGN_EMP_ID^="CS_SYS" and lag_userName=userName and lag_ASSIGN_EMP_ID=ASSIGN_EMP_ID  then 当天队列=1;else 当天队列=0;
	if ASSIGN_EMP_ID^="CS_SYS" and lag_userName^=userName  then 当天流入=1;else 当天流入=0;
end;
else do;
	if ASSIGN_EMP_ID^="CS_SYS"  then 当天流入=1;else 当天流入=0;end;
run;
data repayfin.test_lr_b;
set test;
run;
*1M2M3
2成都
3催回;

