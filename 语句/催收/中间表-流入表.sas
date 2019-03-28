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
d=&nd.;
run;

data Ctl_task_assign;
set csdata.Ctl_task_assign(keep=emp_id OVERDUE_LOAN_ID ASSIGN_TIME ASSIGN_EMP_ID status);  * ������Щ�ֶ�;
format �������� yymmdd10.;
��������=datepart(ASSIGN_TIME); * assign_time�����ڲ���;
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

proc sort data=kanr;by contract_no ASSIGN_TIME descending status;run; * ����;

data repayfin.kanr;
set kanr;
format ��һ���������� yymmdd10.;
��һ����������=lag(��������);   * ������һ���۲�ֵ;
/*lag������������һ��lage��������ʱ��ʵ��
  dif������һ�ײ��=x-lag(x)*/
by contract_no ASSIGN_TIME descending status;
if first.contract_no then ��һ����������="";
/*if contract_no^="" and  ��һ����������=�������� and status="-2";*/
if  contract_no^="" and ��һ����������=�������� and status="-2" then delete;
*-2Ϊ������ת�����������������ϵķ���,������������ʱ����䣬�����ڵ����ڶ��������ж��������һ�������е�����.����ʱ��һ��ֻ�����һ����Ҳ����-2��ʶ����ʱһ����Ǹ���ϯ��,eg:C151754177299802300001437;
if contract_no="C2017092011154429078509" and ��������=mdy(11,12,2018) then delete;
if contract_no="C201512181729511817238" and ��������=mdy(11,13,2018) then userName="������";
if (contract_no="C2017042416144629688676" or contract_no="C2017112409362549464210") and ��������=mdy(12,31,2018) then userName="����";
if (contract_no="C2016102812074247312367" or contract_no="C2017092211131164787543") and ��������=mdy(12,31,2018) then userName="������";
run;
/*������ϴ*/

*ɾ���ν�ΰ���˻ᵼ�²�������90+��һֱ����ϯ���ʵ���ϲ�����ϯ�������ȥ�˺��ϰ�����;
/*˼����Ϊʲô��������һ������ʱ�䣬����ʱ�䡪����һ������ʱ�䣬�����ǿͻ�����ϯͣ����ʱ��ô*/
data kanr_;
set repayfin.kanr;
if username not in ('�ν�ΰ','����Ƽ','����Ƽ');
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
/*-2�µ��³�������*/
data macro;
set kanr_(where=(��������<=&cut_dt.));
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
*���ǵ�һ��ͷǵ�һ��;
if not first.contract_no then do;
	if ASSIGN_EMP_ID^="CS_SYS" and lag_userName=userName and lag_ASSIGN_EMP_ID=ASSIGN_EMP_ID  then �������=1;else �������=0;
	if ASSIGN_EMP_ID^="CS_SYS" and lag_userName^=userName  then ��������=1;else ��������=0;
end;
else do;
	if ASSIGN_EMP_ID^="CS_SYS"  then ��������=1;else ��������=0;end;
run;
data repayfin.test_lr_b;
set test;
run;
*1M2M3
2�ɶ�
3�߻�;

