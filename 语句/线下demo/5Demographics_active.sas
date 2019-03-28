/*Demographics approval rate*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/
/*account*/
/*libname accRaw "D:\WORK\Database\Account";*/
libname accRaw odbc  datasrc=account_nf;

/*活动账户*/

/*账户状态*/
/*data account_status;*/
/*set accraw.account_info;*/
/*keep contract_no account_status;*/
/*run;*/
data account_status;
set repayfin.payment_daily(where=(营业部^="APP"));
if cut_date=&work_date.;
keep contract_no ACCOUNT_STATUS es status cut_date;
run;
data Loan;
set DemoFin.use_&work_day.;
where 放款状态="已放款";
if 放款日期<=&work_date.;
/*if 放款月份 not in ("201511","201512","201601","201602","201603","201604");*/
run;
proc sort data=loan;by contract_no;run;
proc sort data=account_status;by contract_no;run;
data active_loan;
merge loan(in=a) account_status(in=b);
by contract_no; 
if a;
/*提前结清账户*/
/*if account_status ne "0003" and CN_MARRIAGE="180-离异";*/
if es^=1;
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
	data demo_res;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res;
	set demo_res demo_&n.;
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

%demo_0(use_database=active_loan,i=45);
data demo_res_active;
set demo_res;
run;

/*proc export data=demo_res_active*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_active&work_Day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/

