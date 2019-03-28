/*Demographics approval rate*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/
*这里剃掉续贷;
/* Demographics*/
data Loan;
set DemoFin.use_&work_day.;

if not kindex(product_code,"续贷");
where 放款状态="已放款";
run;

/*transpose variable*/
/*age*/



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
var count;
table &var_name.
all,&class_g.*count*(N);
run;
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=L;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var count_N;
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

%demo_0(use_database=Loan
,class_g=放款月份,i=45);
data demo_res_loan;
set demo_res;
run;
PROC IMPORT OUT= title
            DATAFILE= "D:\share\线下demo\Monthly Demographics.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="app_demo$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


proc sql;
create table demo_res_loan_dde as select a.id,a.name,a.class,b.* from title  as  a  left join demo_res_loan as b on a.name =b.variable and a.class = b.group;quit;
proc sort data = demo_res_loan_dde;by id;run;

proc sql;
create table new_class_2(where=(id=. or id =0)) as 
select a.id,
       b.group,b.variable  
from title(where=(name^="")) as a right join demo_res_loan as b on a.name =b.variable and a.class = b.group;quit;


/*proc export data=demo_res_loan*/
/*outfile="D:\WORK\Report\Demographics\output\&work_Day.\demo_res_Loan&work_Day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/


/*时间汇总*/
/*201701-2017-04*/
/**/
data test1;
     set Loan;
     qtr=catx('|',trim(year(放款日期)),trim(qtr(放款日期)));
run;



