/*Demographics*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/
/*TTD Demographics*/
*这里剃掉续贷;
data TTD;
set DemoFin.use_&work_day.;
if input_complete=1;
apply_month=put(datepart(apply_time),yymmn6.);
if not kindex(product_code,"续贷");
run;


proc freq data = TTD;
table product_code;
run;


/*transpose variable*/
/*age*/
/*%let n=1;*/
/*对内容进行拼接*/
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
var input_complete;
table &var_name.
all,&class_g.*input_complete*(N);
run;
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n.;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var input_complete_N;
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
  datafile='D:\share\线下demo\input\variable_TTD.csv'
  out=var_name
  dbms=csv replace;
  datarow=2;
  GUESSINGROWS=500;
  GETNAMES=YES;
run;
%demo_0(use_database=TTD,class_g=进件月份,i=45);

data demo_res_ttd;
set demo_res;
run;
PROC IMPORT OUT= title
            DATAFILE= "D:\share\线下demo\Monthly Demographics.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="TTD_demo$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
proc sql;
create table demo_res_ttd_dde as select a.id,a.name,a.class,b.* from title  as  a  left join demo_res_ttd as b on a.name =b.variable and a.class = b.group;quit;
proc sort data = demo_res_ttd_dde;by id;run;



proc sql;
create table new_class(where=(id=. or id =0)) as select a.id,b.group,b.variable  from title as a right join demo_res_ttd as b on a.name =b.variable and a.class = b.group;quit;
/*proc export data=demo_res*/
/*outfile="D:\songts\workteam\黄玉州\报表交接\to zhipei\Demographics\output\&work_Day.\demo_res_TTD &work_day..csv"*/
/*dbms=dlm*/
/*replace;*/
/*delimiter=',';*/
/*run;*/

/*x  "D:\share\线下demo\Monthly Demographics.xlsx"; */
/*filename DD DDE 'EXCEL|[MTD_Acquisition.xls]Rawdata!r2c4:r200c6';*/
/*data _null_;set Appl_appr_drawdown_res1;file DD;put M&last_mon. M&work_mon. D&last_date.;run;*/

