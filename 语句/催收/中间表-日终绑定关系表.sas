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
d=&nd.;;
run;

data Ctl_task_assign;
set csdata.Ctl_task_assign;
format fp_date yymmdd10.;
fp_date=datepart(ASSIGN_TIME);
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;

proc sql;
create table task1 as
	   select a.id,a.assign_time,a.assign_emp_id, status,  fp_date,
			username, contract_no, issues, settlement_status, settlement_date, bqyd_repayment_date, task_assign_id
	      from ctl_task_assign as a
		     left join ca_staff as b on a.emp_id=b.id1
			 left join csdata.ctl_loaninstallment as d on a.overdue_loan_id=d.id
		order by contract_no, assign_time, status desc;
quit;

data task2;
set task1;
format last_fp_date  yymmdd10.;
	last_fp_date=lag(fp_date);
by contract_no  assign_time  descending status;
if first.contract_no then last_fp_date="";
run;

proc sort data=task2;
	by contract_no descending issues descending assign_time; run;

data repayfin.task;
set task2  ;
format remove_date yymmdd10.;
/*if 1>0 then remove_date=today();*/
by contract_no descending issues;
next_fp_date=lag(fp_date);
if first.contract_no and settlement_status^="0000" then remove_date=today();
if first.contract_no and settlement_status="0000"  then remove_date=datepart(settlement_date);
if not first.contract_no and issues=lag(issues) then remove_date=next_fp_date;
if not first.contract_no  and  issues^=lag(issues) and settlement_date^="" then remove_date=datepart(settlement_date);
if not first.contract_no  and  issues^=lag(issues) and settlement_date="" then remove_date=next_fp_date;
/*表格还是业务bug，导致上一期在A手中还没有还完，这一期逾期后分配给了B。原本应该和上一期打包在A手中，所以简单处理*/
if fp_date<=datepart(settlement_date)<=remove_date and settlement_status="0000" then user_repay_code="Y" ; else user_repay_code="N";
run;
/*fp_date至remove_date即为在username手中停留的时间*/
/*repay_code的"Y"表示客户在该username手中还款了该期*/

/*数据清理，接手时即有的清理方式，照搬*/
data task3;
set repayfin.task;
if contract_no^="" and last_fp_date=fp_date and status="-2" then delete;
if contract_no="C2017092011154429078509" and fp_date=mdy(11,12,2018) then delete;
if contract_no="C201512181729511817238" and fp_date=mdy(11,13,2018) then userName="黄晓妮";
if username not in ("何建伟","林淑萍",'张玉萍');
if kindex(contract_no,"C");
if ASSIGN_EMP_ID^="CS_SYS";
if settlement_date^="" and fp_date>settlement_date then delete;
/*还款之后还分配当期的，把它定义为垃圾数据。这个要找催收同事问一下*/
if remove_date="" then delete;
/*小雨点提前结清客户，13条记录。还了钱没有还款时间，难受*/
run;
proc sort data=task3 ;by contract_no descending issues descending assign_time; run;


proc delete data=dail_task;run;

%macro get_payment;
%do
i = -61 %to &nd.;
data _null_;
cut_dt = intnx("day", &db., &i.);
call symput("cut_dt", cut_dt);
run;
/*-2月的月初至昨日*/
data day_cut;
set task3(where=(fp_date<=&cut_dt. and remove_date>=&cut_dt.));
format cut_date yymmdd10.;
cut_date=&cut_dt.;
run;
proc sort data=day_cut ;by contract_no descending issues descending  assign_time descending user_repay_code;run;
proc sort data=day_cut  nodupkey; by contract_no cut_date descending issues;run;
proc append data=day_cut base=dail_task;run;
%end;
%mend;
%get_payment;

data dail_task1;
set dail_task;
put segment_code  $20.;
put segment_name $20.;
delay_level=ceil((cut_date-datepart(bqyd_repayment_date))/30);
delay_days=mod(cut_date-datepart(bqyd_repayment_date),30);
if delay_days=0 or delay_level=0 then delay_level=delay_level+1;
od_days=(delay_level-1)*30+delay_days;
if (delay_level-1)*30+delay_days<=0 then do segment_code="stage1"; segment_name="0-15"; end;
	else if delay_level=1 and 1<=delay_days<=15 then do segment_code="stage2"; segment_name="0-15"; end;
	else if intck('month',datepart(bqyd_repayment_date),cut_Date)=0 and delay_days>=16 then do segment_code="stage3";segment_name="C-M1"; end;
	else if intck('month',datepart(bqyd_repayment_date),cut_Date)=1 and (delay_level-1)*30+delay_days>=16 then do segment_code="stage4";  segment_name="M1-M2";end;
	else if intck('month',datepart(bqyd_repayment_date),cut_Date)=2 then do segment_code="stage5"; segment_name="M2-M3";end;
	else do segment_code="stage6"; segment_name="流出";end;
if cut_date-datepart(settlement_date)=0 then cut_repay_code="Y"; else cut_repay_code="N";
run;
/*由于业务不需要严格区分M1和M2，而是用月份和逾期天数作为案件流转的依据。
所以这里的delay只用30天，仅为方便做判断确认segment，不为判断逾期阶段和逾期*/
/*(delay_level-1)*30+delay_days就是客户实际逾期时间*/

proc sql;
create table repayfin.dail_bd as
select id ,assign_emp_id ,username ,contract_no ,issues ,bqyd_repayment_date ,delay_level ,delay_days ,od_days ,
		segment_code ,segment_name ,user_repay_code ,cut_repay_code ,settlement_date ,assign_time ,status ,
		last_fp_date ,fp_date ,remove_date ,task_assign_id ,cut_date
	from dail_task1;
quit;


*****************************外访 start********************************;
data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
proc sql;
create table ctl_visit_ as
select a.*,b.userName
from csdata.ctl_visit as a 
left join ca_staff as b on a.emp_id=b.id1;
quit;
data ctl_visit;
set ctl_visit_;
format 外访开始时间 yymmdd10.;
format 外访结束时间 yymmdd10.;
外访开始时间=datepart(VISIT_START_TIME);
外访结束时间=datepart(VISIT_END_TIME);
keep contract_no 外访开始时间 username 外访结束时间; 
run;
*****************************外访 end********************************;
****************************************************************************;
*判断是否有外访参与;
proc sql;
create table dail_bdgx1 as 
select a.*,b.外访开始时间,b.外访结束时间,b.username as wf_username from repayfin.dail_bd as a
left join ctl_visit as b on a.contract_no=b.contract_no;
quit;
data dail_bdgx2;
set dail_bdgx1;
if 外访开始时间<=cut_date<=外访结束时间 then 外访中=1;else 外访中=0;
drop 外访开始时间 外访结束时间;
run;
/*这里我想知道，好像visit_task里面的时间跨度比较长，到底是visit表为准，还是visit_task的时间为准呢？*/
proc sort data=dail_bdgx2;by contract_no cut_date descending issues descending 外访中;run;
proc sort data=dail_bdgx2 nodupkey;by contract_no cut_date descending issues ;run;
*****************************外访 end********************************;
****************************************************************************;

/*******************判断客户当天逾期的期数和金额***********************/
proc sql;
create table delay as
select a.contract_no,a.cut_date,a.issues ,count(b.contract_no) as delay_issues ,sum(CURR_RECEIVE_CAPITAL_AMT+CURR_RECEIVE_INTEREST_AMT) as delay_amt
	from dail_bdgx2 as a 
		left join account.repay_plan as b
			on a.contract_no=b.contract_no and curr_period>=issues and cut_date>repay_date
group by a.contract_no,a.cut_date,a.issues;
quit;
proc sort data=dail_bdgx2 nodupkey;by contract_no cut_date descending issues ;run;
proc sort data=delay nodupkey;by contract_no cut_date descending issues ;run;
data repayfin.dail_bdgx;
merge dail_bdgx2(in=a) delay(in=b);
by contract_no cut_date descending issues  ;
run;
/*******************判断客户当天逾期的期数和金额***********************/
/*******************日终绑定关系表********************/



proc sort data=repayfin.dail_cut;by contract_no cut_date assign_time;run;
data testtable;
set repayfin.dail_cut;
lag_username=lag(username);
lag_assign_emp_id=lag(assign_emp_id);
by contract_no cut_date assign_time;
if first.contract_no then do; lag_username=user_name;lag_assign_emp_id=assign_emp_id;end;
if not first.contract_no then do;
	if lag_username=username and lag_assign_emp_id=assign_emp_id
		then 当天队列=1 ; else 当天队列=0;
	if lag_username^=username or lag_assign_emp_id^=assign_emp_id then 当天流入=1;else 当天流入=0;
/*？？？考虑一种特殊情况，客户第二次逾期，由相同的分配人分配给了相同的处理人，系统识别时也是当天流入*/
end;
else do;
	if ASSIGN_EMP_ID^="CS_SYS"  then 当天流入=1;else 当天流入=0;end;
run;

data repayfin.lr;
set testtable;
run;

/*取remove_date的概念，解决到后期分配给何建伟的问题；再用settlement的概念，解决催回的问题*/
/*成都什么问题暂不清楚*/
