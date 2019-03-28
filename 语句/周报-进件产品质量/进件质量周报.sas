option compress=yes validvarname=any;

libname credit odbc datasrc = credit_nf;
libname dta "D:\share\Datamart\中间表\daily";


/*data tme;*/
/*format t ld yymmdd10.;*/
/*t =today();*/


data credit_zx_detail;
set credit.credit_zx_detail;
if SUB_BIZ_TYPE="无抵押贷款" then 无抵押贷款 =1;
run;

proc freq data = credit_zx_detail;
table ACCT_STATUS;
run;

proc sql;
create table zx_detail as select apply_code ,count(无抵押贷款) as 资信无抵押贷款数,count(*) as 资信贷款数 from credit_zx_detail(where=(ACCT_STATUS^="结清")) group by apply_code;quit;

data customer_info ;
set dta.customer_info;
run;

/*data dianhuab;*/
/*set customer_info;*/
/*if third_refuse_code="R754";*/
/*run;*/


proc sql ;
create table all_info as select a.*,b.资信无抵押贷款数,b.资信贷款数 from customer_info as a left join zx_detail as b on a.apply_code = b.apply_code;
quit;





data all_info1;
set all_info(where=(进件时间>intnx("month",today(),-1,"b")));
进件月份=substr(compress(put(进件时间,yymmdd10.),"-"),1,6);
input_week =week(进件时间);

if weekday(today())>=2 then input_week_ds = week(today())-1;
else input_week_ds = week(today());
if input_week=input_week_ds;
/*if input_week = 51;*/

/*2018调整dde 输出位置*/
/*call symput ("i",compress(put(week(today())-36,12.)));*/
/*call symput ("i",compress(put(52-36,12.)));*/
/*2019调整dde 输出位置*/
if weekday(today())>=2 then call symput ("i",compress(put(week(today())+16,12.)));
else call symput ("i",compress(put(week(today())+17,12.)));



if approve_产品="" 
then do;
	if DESIRED_PRODUCT="Elite" then approve_产品="U贷通";

end;

if kindex(approve_产品,"E微贷") then approve_产品 ="E微贷";
if kindex(approve_产品,"E保通") then approve_产品 ="E保通";
if kindex(approve_产品,"E宅通") then approve_产品 ="E宅通";

if  外地标签="外地"  then  nonlocal=0;
else if 外地标签="本地"  then  nonlocal=1;

if IS_HAS_HOURSE="y" then IS_HAS_HOURSE1=1;
else if IS_HAS_HOURSE="n" then IS_HAS_HOURSE1=0;

if 通过=1 then 审批结果="1通过客户" ;else 审批结果="2拒绝客户";

近3月查询次数 =sum(近3个月本人查询次数,近3个月贷款查询次数);
近2年查询次数=sum(近2年贷款查询次数,近2年信用卡查询次数,近2年个人查询次数);

if 其他负债>0 then 其他负债笔数=1;
if 公积金基数<1 then 公积金基数=社保基数;
无抵押贷款数总计 = sum(其他负债笔数,未结清无抵押贷款);
未结清贷款总计 = sum(其他负债笔数,未结清贷款);
其他未结清无抵押贷款=sum(其他负债笔数,其他未结清无抵押贷款);

array numr _numeric_;
do over numr;
if numr=. then numr=0;
end;
run;

/*测试 高峰 31ge 没问题。 刘建翠 11个*/
data test;
set all_info1;
/*if apply_code="PL153925039126802300000699" ;*/
keep apply_code name 资信贷款数 其他负债笔数 未结清贷款 近6个月本人查询次数;
if approve_产品="E房通";
run ;


proc sql ;
create table report as select approve_产品,input_week,count(*)as 处理件数,sum(通过)/count(*) as 通过率,sum(nonlocal)/count(*) as 本地人数占比,sum(IS_HAS_HOURSE1)/count(*) as 有房人数占比
,mean(核实收入) as 平均收入,mean(公积金基数) as 平均社保或公积金缴费基数,mean(外部负债率) as 平均外部负债率
,mean(信用卡使用率) as 平均信用卡使用率,mean(简版汇总负债总计) as 平均月还款额,mean(近3月查询次数) as 平均近3月查询次数 ,mean(近6个月本人查询次数) as 平均近6个月本人查询次数
,mean(近2年查询次数) as 平均近2年查询次数,mean(未结清贷款总计) as 平均所有贷款笔数,mean(无抵押贷款数总计) as 平均同行贷款笔数  
,mean(银行未结清无抵押贷款) as 平均银行无抵押贷款数 ,mean(消费金融未结清无抵押贷款) as 平均消费金融无抵押贷款数 ,mean(其他未结清无抵押贷款) as 平均其他无抵押贷款数
,mean(资信无抵押贷款数) as 平均资信无抵押贷款数
 
from all_info1(where=(check_end =1 )) group by approve_产品,input_week;quit;

proc sql ;
create table report2 as select approve_产品,审批结果,input_week,count(*)as 处理件数,sum(nonlocal)/count(*) as 本地人数占比,sum(IS_HAS_HOURSE1)/count(*) as 有房人数占比,mean(无抵押贷款数总计) as 平均同行贷款笔数  
,mean(核实收入) as 平均收入,mean(公积金基数) as 平均社保或公积金缴费基数,mean(外部负债率) as 平均外部负债率
,mean(信用卡使用率) as 平均信用卡使用率,mean(简版汇总负债总计) as 平均月还款额,mean(近3月查询次数) as 平均近3月查询次数 ,mean(近6个月本人查询次数) as 平均近6个月本人查询次数
,mean(近2年查询次数) as 平均近2年查询次数,mean(未结清贷款总计) as 平均所有贷款笔数
,mean(银行未结清无抵押贷款) as 平均银行无抵押贷款数 ,mean(消费金融未结清无抵押贷款) as 平均消费金融无抵押贷款数 ,mean(其他未结清无抵押贷款) as 平均其他无抵押贷款数
,mean(资信无抵押贷款数) as 平均资信无抵押贷款数

from all_info1(where=(check_end =1 )) group by approve_产品,审批结果,input_week ;quit;

proc sql ;
create table report3 as select 审批结果,input_week,count(*)as 处理件数,sum(nonlocal)/count(*) as 本地人数占比,sum(IS_HAS_HOURSE1)/count(*) as 有房人数占比,mean(无抵押贷款数总计) as 平均同行贷款笔数  
,mean(核实收入) as 平均收入,mean(公积金基数) as 平均社保或公积金缴费基数,mean(外部负债率) as 平均外部负债率
,mean(信用卡使用率) as 平均信用卡使用率,mean(简版汇总负债总计) as 平均月还款额,mean(近3月查询次数) as 平均近3月查询次数 ,mean(近6个月本人查询次数) as 平均近6个月本人查询次数
,mean(近2年查询次数) as 平均近2年查询次数,mean(未结清贷款总计) as 平均所有贷款笔数
,mean(银行未结清无抵押贷款) as 平均银行无抵押贷款数 ,mean(消费金融未结清无抵押贷款) as 平均消费金融无抵押贷款数 ,mean(其他未结清无抵押贷款) as 平均其他无抵押贷款数
,mean(资信无抵押贷款数) as 平均资信无抵押贷款数

from all_info1(where=(check_end =1 )) group by 审批结果,input_week;quit;

proc sql ;
create table report4 as select input_week,count(*)as 处理件数,sum(通过)/count(*) as 通过率,sum(nonlocal)/count(*) as 本地人数占比,sum(IS_HAS_HOURSE1)/count(*) as 有房人数占比,mean(无抵押贷款数总计) as 平均同行贷款笔数  
,mean(核实收入) as 平均收入,mean(公积金基数) as 平均社保或公积金缴费基数,mean(外部负债率) as 平均外部负债率
,mean(信用卡使用率) as 平均信用卡使用率,mean(简版汇总负债总计) as 平均月还款额,mean(近3月查询次数) as 平均近3月查询次数 ,mean(近6个月本人查询次数) as 平均近6个月本人查询次数
,mean(近2年查询次数) as 平均近2年查询次数,mean(未结清贷款总计) as 平均所有贷款笔数
,mean(银行未结清无抵押贷款) as 平均银行无抵押贷款数 ,mean(消费金融未结清无抵押贷款) as 平均消费金融无抵押贷款数 ,mean(其他未结清无抵押贷款) as 平均其他无抵押贷款数
,mean(资信无抵押贷款数) as 平均资信无抵押贷款数

from all_info1(where=(check_end =1 )) group by input_week;quit;

data report_Com;
set report2 report report3 report4;
if 审批结果="" then 审批结果="3审批客户";
if approve_产品="" then approve_产品="ALL";

/*if 进件月份="201809";*/
run;

proc sort data = report_Com;by approve_产品 审批结果;run;


/*PROC EXPORT DATA=report_Com*/
/*OUTFILE= "F:\share\周报表\进件产品质量\10月第二周进件产品质量.xlsx" DBMS=EXCEL REPLACE;SHEET="审批客户"; RUN;*/

/*导入需要的字段 分群*/
PROC IMPORT OUT= title
            DATAFILE= "D:\share\周报表\进件产品质量\进件产品质量.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="dde$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc sql;
create table report_Com_dde as select a.*,b.* from title as a left join report_Com as b on a.approve_产品=b.approve_产品 and a.审批结果=b.审批结果;quit;


x  "D:\share\周报表\进件产品质量\进件产品质量.xlsx"; 
/*filename DD DDE "EXCEL|[进件产品质量.xlsx]审批客户!r2c2:r19c3";*/
/*data _null_;set report_Com_dde;file dd;put 处理件数 通过率 ;run;*/
/**/
/*filename DD DDE "EXCEL|[进件产品质量.xlsx]审批客户!r2c5:r19c16";*/
/*data _null_;set report_Com_dde;file dd;put 本地人数占比 有房人数占比 平均收入 平均社保或公积金缴费基数 平均外部负债率 平均信用卡使用率 平均同行贷款笔数 平均所有贷款笔数*/
/* 平均月还款额 平均近3月查询次数 平均近6个月本人查询次数 平均近2年查询次数;run;*/


PROC IMPORT OUT= title2
            DATAFILE= "D:\share\周报表\进件产品质量\进件产品质量.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="dde2$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc transpose data =report_Com out=report_tran ;
by approve_产品 审批结果;
run;

proc sql;
create table report_tran_dde as select a.*,b.* from title2 as a left join report_tran as b on
a.产品=b.approve_产品 and a.维度=b._name_ and a.案件结果=b.审批结果;quit;

proc sort data = report_tran_dde;by id;run;

filename DD DDE "EXCEL|[进件产品质量.xlsx]进件产品质量周报!r3c&i.:r314c&i.";
data _null_;set report_tran_dde;file dd;put col1;run;

