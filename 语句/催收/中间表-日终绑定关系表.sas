option compress = yes validvarname = any;
libname account 'D:\share\Datamart\ԭ��\account';
libname csdata 'D:\share\Datamart\ԭ��\csdata';
libname res  'D:\share\Datamart\ԭ��\res';
libname repayFin "D:\share\Datamart\�м��\repayAnalysis";


data _null_;
format dt yymmdd10.;
 dt = today() - 1;
 db=intnx("month",dt,0,"b");  * bΪbeginning�������³�;
 nd = dt-db;
lastweekf=intnx('week',dt,-1); * Ĭ��Ϊb��������;
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
/*�����ҵ��bug��������һ����A���л�û�л��꣬��һ�����ں�������B��ԭ��Ӧ�ú���һ�ڴ����A���У����Լ򵥴���*/
if fp_date<=datepart(settlement_date)<=remove_date and settlement_status="0000" then user_repay_code="Y" ; else user_repay_code="N";
run;
/*fp_date��remove_date��Ϊ��username����ͣ����ʱ��*/
/*repay_code��"Y"��ʾ�ͻ��ڸ�username���л����˸���*/

/*������������ʱ���е�����ʽ���հ�*/
data task3;
set repayfin.task;
if contract_no^="" and last_fp_date=fp_date and status="-2" then delete;
if contract_no="C2017092011154429078509" and fp_date=mdy(11,12,2018) then delete;
if contract_no="C201512181729511817238" and fp_date=mdy(11,13,2018) then userName="������";
if username not in ("�ν�ΰ","����Ƽ",'����Ƽ');
if kindex(contract_no,"C");
if ASSIGN_EMP_ID^="CS_SYS";
if settlement_date^="" and fp_date>settlement_date then delete;
/*����֮�󻹷��䵱�ڵģ���������Ϊ�������ݡ����Ҫ�Ҵ���ͬ����һ��*/
if remove_date="" then delete;
/*С�����ǰ����ͻ���13����¼������Ǯû�л���ʱ�䣬����*/
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
/*-2�µ��³�������*/
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
	else do segment_code="stage6"; segment_name="����";end;
if cut_date-datepart(settlement_date)=0 then cut_repay_code="Y"; else cut_repay_code="N";
run;
/*����ҵ����Ҫ�ϸ�����M1��M2���������·ݺ�����������Ϊ������ת�����ݡ�
���������delayֻ��30�죬��Ϊ�������ж�ȷ��segment����Ϊ�ж����ڽ׶κ�����*/
/*(delay_level-1)*30+delay_days���ǿͻ�ʵ������ʱ��*/

proc sql;
create table repayfin.dail_bd as
select id ,assign_emp_id ,username ,contract_no ,issues ,bqyd_repayment_date ,delay_level ,delay_days ,od_days ,
		segment_code ,segment_name ,user_repay_code ,cut_repay_code ,settlement_date ,assign_time ,status ,
		last_fp_date ,fp_date ,remove_date ,task_assign_id ,cut_date
	from dail_task1;
quit;


*****************************��� start********************************;
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
format ��ÿ�ʼʱ�� yymmdd10.;
format ��ý���ʱ�� yymmdd10.;
��ÿ�ʼʱ��=datepart(VISIT_START_TIME);
��ý���ʱ��=datepart(VISIT_END_TIME);
keep contract_no ��ÿ�ʼʱ�� username ��ý���ʱ��; 
run;
*****************************��� end********************************;
****************************************************************************;
*�ж��Ƿ�����ò���;
proc sql;
create table dail_bdgx1 as 
select a.*,b.��ÿ�ʼʱ��,b.��ý���ʱ��,b.username as wf_username from repayfin.dail_bd as a
left join ctl_visit as b on a.contract_no=b.contract_no;
quit;
data dail_bdgx2;
set dail_bdgx1;
if ��ÿ�ʼʱ��<=cut_date<=��ý���ʱ�� then �����=1;else �����=0;
drop ��ÿ�ʼʱ�� ��ý���ʱ��;
run;
/*��������֪��������visit_task�����ʱ���ȱȽϳ���������visit��Ϊ׼������visit_task��ʱ��Ϊ׼�أ�*/
proc sort data=dail_bdgx2;by contract_no cut_date descending issues descending �����;run;
proc sort data=dail_bdgx2 nodupkey;by contract_no cut_date descending issues ;run;
*****************************��� end********************************;
****************************************************************************;

/*******************�жϿͻ��������ڵ������ͽ��***********************/
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
/*******************�жϿͻ��������ڵ������ͽ��***********************/
/*******************���հ󶨹�ϵ��********************/



proc sort data=repayfin.dail_cut;by contract_no cut_date assign_time;run;
data testtable;
set repayfin.dail_cut;
lag_username=lag(username);
lag_assign_emp_id=lag(assign_emp_id);
by contract_no cut_date assign_time;
if first.contract_no then do; lag_username=user_name;lag_assign_emp_id=assign_emp_id;end;
if not first.contract_no then do;
	if lag_username=username and lag_assign_emp_id=assign_emp_id
		then �������=1 ; else �������=0;
	if lag_username^=username or lag_assign_emp_id^=assign_emp_id then ��������=1;else ��������=0;
/*����������һ������������ͻ��ڶ������ڣ�����ͬ�ķ����˷��������ͬ�Ĵ����ˣ�ϵͳʶ��ʱҲ�ǵ�������*/
end;
else do;
	if ASSIGN_EMP_ID^="CS_SYS"  then ��������=1;else ��������=0;end;
run;

data repayfin.lr;
set testtable;
run;

/*ȡremove_date�ĸ����������ڷ�����ν�ΰ�����⣻����settlement�ĸ������߻ص�����*/
/*�ɶ�ʲô�����ݲ����*/
