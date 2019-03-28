option compress = yes validvarname = any;
option missing = 0;
/*Demographics approval rate*/
/*libname appRaw "D:\WORK\Database\approval";*/
/*account*/

/*活动账户*/


/*data od_ever_15day;*/
/*set accraw.bill_main;*/
/*if overdue_days>=15;*/
/*keep contract_no overdue_days repay_Date curr_period;*/
/*run;*/
data od_ever_15day;
set repayfin.payment;
if cut_date=&work_date.;
if od_days_ever>=15;
if es^=1;
keep contract_no CURR_PERIOD REPAY_DATE od_days_ever;
rename od_days_ever=overdue_days;
run;

proc sort data=od_ever_15day nodupkey;by contract_no;run;

data Loan;
set DemoFin.use_&work_day.;
where 放款状态="已放款";
/*if 放款月份 not in ("201511","201512","201601","201602","201603","201604");*/
/*where 放款状态="已放款" and CN_MARRIAGE="180-离异";*/
run;
proc sort data=Loan;by contract_no;run;

data ever_15;
merge loan(in=a) od_ever_15day(in=b);
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
table &var_name. all,count*(N);
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
	data demo_res_ever15;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res_ever15;
	set demo_res_ever15 demo_&n.;
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

%demo_0(use_database=ever_15,i=45);

/**/
/*proc export data=demo_res_ever15*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_ever15_&work_Day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/
