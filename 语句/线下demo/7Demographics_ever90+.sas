option compress = yes validvarname = any;
option missing = 0;
/*Demographics approval rate*/
/*libname appRaw "D:\WORK\Database\approval";*/
/*account*/


/*活动账户*/
/*data od_ever_90day;*/
/*set accraw.bill_main;*/
/*if overdue_days>=90;*/
/*keep contract_no overdue_days repay_Date curr_period;*/
/*run;*/
data od_ever_90day;
set repayfin.payment;
if cut_date=&work_date.;
if od_days_ever>=90;
if es ^=1;
keep contract_no CURR_PERIOD REPAY_DATE od_days_ever;
rename od_days_ever=overdue_days;
run;

proc sort data=od_ever_90day nodupkey;by contract_no;run;

data Loan;
set DemoFin.use_&work_day.;
where 放款状态="已放款";
/*if 放款月份 not in ("201511","201512","201601","201602","201603","201604");*/
/*where 放款状态="已放款" and CN_MARRIAGE="180-离异";*/
run;
proc sort data=Loan;by contract_no;run;

data ever_90;
merge loan(in=a) od_ever_90day(in=b);
by contract_no;
if b;
/*if kindex(product_code,"U贷通");*/
/*if kindex(营业部,"怀化");*/

run;

%macro demo_0(use_database,i);
%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set &use_database.;
format &var_name. $45.;
if strip(&var_name.)="" then &var_name.="z-Missing";
run;

proc tabulate data=use0 out=demo_res_&n.(drop=_TYPE_ _PAGE_ _TABLE_ );
class  &var_name. /missing;
var count;
table &var_name.
all,count*(N);
run;

data demo_&n.;
set demo_res_&n.;
format variable $45.;
format group $45.;
variable="&var_name.";
if &var_name.="" then group="小计";
else group=&var_name.;
drop  &var_name.;
run;

%if &n.=1 %then %do;
	data demo_res_90;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res_90;
	set demo_res_90 demo_&n.;
	format variable $45.;
	run;
%end;
%end;
%mend;

proc import
  datafile='D:\share\线下demo\input\variable.csv'
  out=var_name
  dbms=csv
  replace;
  datarow=2;
  GUESSINGROWS=500;
  GETNAMES=YES;
run;

%demo_0(use_database=ever_90,i=45);

/*proc export data=demo_res_90*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_ever_90_&work_Day..csv"*/
/*dbms=csv*/
/*replace;*/
/*delimiter=',';*/
/*run;*/

/*链接active ever15+ ever90+*/
data demo_res_active;
set demo_res_active;
id=_N_;
run;

data demo_res_ever15_2;
set demo_res_ever15;
rename count_N=count_N_15;
run;

data demo_res_90_2;
set demo_res_90;
rename count_N=count_N_90;
run;

proc sort data=demo_res_active nodupkey;by variable group;run;
proc sort data=demo_res_ever15_2 nodupkey;by variable group;run;
proc sort data=demo_res_90_2 nodupkey;by variable group;run;

data demo_res_ods;
merge demo_res_active(in=a) demo_res_ever15_2(in=b) demo_res_90_2(in=c);
by variable group;
if a;
run;

proc sort data=demo_res_ods;by id;run;

PROC IMPORT OUT= title
            DATAFILE= "D:\share\线下demo\Monthly Demographics.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="loan_demo$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc sql;
create table demo_res_ods_dde as select a.id,a.name,a.class,b.* from title  as  a  left join demo_res_ods as b on a.name =b.variable and a.class = b.group;quit;
proc sort data = demo_res_ods_dde;by id;run;



proc sql;
create table new_class_loan(where=(id=. or id =0)) as select a.id,b.group,b.variable  from title as a right join demo_res_ods as b on a.name =b.variable and a.class = b.group;quit;

/*proc export data=demo_res_ods*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_ods_&work_Day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/
