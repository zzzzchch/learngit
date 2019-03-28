/*Demographics approval rate*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/

data apprvoal;
set DemoFin.use_&work_day.;
if 通过=1 or 拒绝=1;
format check_final 8.;
if 通过=1 then check_final=1;
else check_final=0;


if not kindex(product_code,"续贷");
run;

/*proc freq data=apprvoal;*/
/*table 批核状态;*/
/*run;*/

/*%let n=1;*/
/*%let use_database=apprvoal;*/
/*%let class_g=批核月份;*/
%macro demo_0(use_database,class_g,i);
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
class &class_g. &var_name. /missing;
var check_final;
table &var_name.
all,&class_g.*check_final*(sum N);
run;

data demo_res_&n.;
set demo_res_&n.;
approval_rate=check_final_Sum/check_final_N;
run;
 
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=R;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var approval_rate;
run;

data demo_&n.;
set demo_&n.;
format Group $45.;
format variable $45.;
variable="&var_name.";
if &var_name.="" then group="小计";
else group=&var_name.;
drop _NAME_ &var_name.;
run;

%if &n=1 %then %do;
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

%demo_0(use_database=apprvoal,class_g=批核月份,i=45);

data demo_res_appr;
set demo_res;
run;
proc sql;
create table demo_res_appr_dde as select a.id,a.name,a.class,b.* from title  as  a  left join demo_res_appr as b on a.name =b.variable and a.class = b.group;quit;
proc sort data = demo_res_appr_dde;by id;run;

/*proc export data=demo_res*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_approval_rate&work_day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/
/*链接new loan & approval rate*/
data demo_res_appr_2;
set demo_res_appr;
id=_N_;
run;

data demo_res_loan_2;
set demo_res_loan;
run;

proc sort data=demo_res_appr_2 nodupkey;by variable group;run;
proc sort data=demo_res_loan_2 nodupkey;by variable group;run;

data demo_res_NB;
merge demo_res_loan_2(in=a) demo_res_appr_2(in=b);
by variable group;
if b;
run;

proc sort data=demo_res_NB;by id;run;
/*proc export data=demo_res_NB*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_NB&work_Day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/
/**/
