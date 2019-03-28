**********************************************
    LOAN_STATUS_1(1,"正常"),
    LOAN_STATUS_2(2,"逾期"),
    LOAN_STATUS_3(3,"结清"),
    LOAN_STATUS_4(4,"呆账"),
    LOAN_STATUS_5(5,"转出"),
    CREDIT_STATUS_11(11,"正常"),
    CREDIT_STATUS_12(12,"冻结"),
    CREDIT_STATUS_13(13,"止付"),
    CREDIT_STATUS_14(14,"销户"),
    CREDIT_STATUS_15(15,"呆账"),
    CREDIT_STATUS_16(16,"未激活"),
    CREDIT_STATUS_17(17,"逾期"),

    REASON_2(2,"信用卡审批"),
    REASON_1(1,"贷款审批"),
    REASON_3(3,"担保资格审查"),
    REASON_4(4,"贷后管理"),
    REASON_5(5,"本人查询（临柜）"),
    REASON_6(6,"本人查询(互联网个人信用信息服务平台)"),
    REASON_7(7,"特约商户实名审查"),
    REASON_8(8,"保前审查"),
    REASON_9(9,"客户准入资格审查"),
    REASON_10(10,"保后管理"),
    ;
**********************************************;


option compress=yes validvarname=any;

libname crRaw "D:\share\Datamart\原表\credit";
libname crMid "D:\share\线下demo\线下demo";
libname appMid "D:\share\Datamart\原表\approval";

%macro InitVariableInDataset(dataset,withoutvar, withoutvar2='');

	%local dsid i nvar vname vtype rc strN strC;
	%let strN = %str(=.;);
	%let strC = %str(='';);
	%let dsid = %sysfunc(open(&dataset));
	%if &dsid %then
		%do;
			%let nvar = %sysfunc(attrn(&dsid,NVARS));
%*			%put &nvar;
		   	%do i = 1 %to &nvar;
		      %let vname = %sysfunc(varname(&dsid,&i));
			  %if %UPCASE(&vname) ^= %UPCASE(&withoutvar) 
				and %UPCASE(&vname) ^= %UPCASE(&withoutvar2) %then %do;
			      %let vtype = %sysfunc(vartype(&dsid,&i));
	%*			  	%put _%sysfunc(compress(&vtype))_;
				  %if %sysfunc(compress(&vtype)) = N %then %do;
&vname &strN; 
				  %end; %else %do;
&vname &strC;
				  %end;

			  %end;
		   	%end;

			%let rc = %sysfunc(close(&dsid));
		%end;
	%else %put %sysfunc(sysmsg());

%mend;

/*报告日期 近似等于查询日期*/
proc sort data=crRaw.credit_info_base out=report_date(keep=report_number real_name report_date CREDIT_VALID_ACCT_SUM) nodupkey; by report_number; run;

/*信用卡贷款明细加上报告日期*/
/*proc sort data=crRaw.credit_detail out=credit_detail; by report_number; run;*/
/*data credit_detail;*/
/*merge credit_detail(in=a) report_date(in=b);*/
/*by report_number;*/
/*if a;*/
/*open_month = intck("month", DATE_OPENED, report_date);*/
/*if DATE_OPENED >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;*/
/*if DATE_OPENED >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0;*/
/*if credit_line_amt=. then credit_line_amt=0;*/
/*if usedcredit_line_amt=. then usedcredit_line_amt=0;*/
/*run;*/
/*替换上面先sort再merge的处理，提高速度*/
data credit_detail;
if _n_ = 0 then set report_date;
if _n_ = 1 then do;
	declare hash share(dataset:'report_date');
				share.definekey('report_number');
				share.definedata(all:'yes');
				share.definedone();
call missing (of _all_);
end;
set crRaw.credit_detail;
if share.find() = 0 then do; end;
else do; %InitVariableInDataset(report_date,report_number); end;
run;
data credit_detail;
set credit_detail;
open_month = intck("month", DATE_OPENED, report_date);
if DATE_OPENED >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;
if DATE_OPENED >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0;
if credit_line_amt=. then credit_line_amt=0;
if usedcredit_line_amt=. then usedcredit_line_amt=0;
run;

/*查询明细加上报告日期*/
/*proc sort data=crRaw.credit_query_record out=credit_query_record; by report_number; run;*/
/*data credit_query_record;*/
/*merge credit_query_record(in=a) report_date(in=b);*/
/*by report_number;*/
/*if a;*/
/*if query_date >= intnx("month", report_date, -1, "same") then in1month = 1; else in1month = 0;*/
/*if query_date >= intnx("month", report_date, -3, "same") then in3month = 1; else in3month = 0;*/
/*if query_date >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;*/
/*if query_date >= intnx("month", report_date, -12, "same") then in12month = 1; else in12month = 0;*/
/*if query_date >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0;*/
/**/
/*run;*/
/*替换上面先sort再merge的处理，提高速度*/
data credit_query_record;
if _n_ = 0 then set report_date;
if _n_ = 1 then do;
	declare hash share(dataset:'report_date');
				share.definekey('report_number');
				share.definedata(all:'yes');
				share.definedone();
call missing (of _all_);
end;
set crRaw.credit_query_record;
if share.find() = 0 then do; end;
else do; %InitVariableInDataset(report_date,report_number); end;
run;
data credit_query_record;
set credit_query_record;
if query_date >= intnx("month", report_date, -1, "same") then in1month = 1; else in1month = 0;
if query_date >= intnx("month", report_date, -3, "same") then in3month = 1; else in3month = 0;
if query_date >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;
if query_date >= intnx("month", report_date, -12, "same") then in12month = 1; else in12month = 0;
if query_date >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0;
run;

****************************************************************************
贷记卡相关变量
***************************************************************************;

/*贷记卡明细*/
data card_detail;
set credit_detail(where=(SUB_BUSI_TYPE="贷记卡"));
run;

/*贷记卡张数Card_Org_CNT（未区分营业部）*/
proc sort data=card_detail out=a nodupkey; by report_number org_name; run;
proc sql;
create table card_org_cnt as
select report_number, real_name, count(*) as card_org_cnt
from a
group by report_number, real_name
;
quit;

/*外币账户贷记卡张数Card_Foreign_Org_CNT*/
proc sort data = card_detail(where=(CURRENCY_TYPE^="人民币")) out=a nodupkey; by report_number org_name; run;
proc sql;
create table card_foreign_org_cnt as
select report_number, count(*) as card_foreign_org_cnt
from a
group by report_number
;
quit;

/*未销户贷记卡张数Card_Uncancel_Org_CNT*/
proc sort data = card_detail(where=(ACCT_STATUS^="14")) out=a nodupkey; by report_number org_name; run;
proc sql;
create table card_uncancel_org_cnt as
select report_number, count(*) as card_uncancel_org_cnt
from a
group by report_number
;
quit;

/*首张贷记开户距今月份数Card_First_Open_Month*/
proc sql;
create table card_first_open_month as
select report_number, max(open_month) as card_first_open_month
from card_detail
group by report_number
;
quit;

/*近6个月新开贷记卡张数Card_Open_06_MONTH_Org_CNT*/
proc sort data = card_detail(where=(in6month=1)) out=a nodupkey; by report_number org_name; run;
proc sql;
create table card_open_06_month_org_cnt as
select report_number, count(*) as card_open_06_month_org_cnt
from a
group by report_number
;
quit;

/*近24个月新开贷记卡张数Card_Open_24_MONTH_Org_CNT*/
proc sort data = card_detail(where=(in24month=1)) out=a nodupkey; by report_number org_name; run;
proc sql;
create table card_open_24_month_org_cnt as
select report_number, count(*) as card_open_24_month_org_cnt
from a
group by report_number
;
quit;

/*贷记卡最大授信额度Card_Max_Credit_Line_Amt*/
proc sql;
create table card_max_credit_line_amt as
select report_number, max(CREDIT_LINE_AMT) as card_max_credit_line_amt
from card_detail
group by report_number
;
quit;

/*贷记卡最大授信额度之和Card_Max_Credit_Line_Amt_Sum*/
proc sql;
create table a as
select report_number, org_name, max(CREDIT_LINE_AMT) as card_max_credit_line
from card_detail
group by report_number, org_name
;
quit;
proc sql;
create table card_max_credit_line_amt_sum as
select report_number, sum(card_max_credit_line) as card_max_credit_line_amt_sum
from a
group by report_number
;
quit;

/*贷记卡平均授信额度Card_Avg_Credit_Line_Amt*/
proc sort data=card_max_credit_line_amt_sum nodupkey; by report_number; run;
proc sort data=card_uncancel_org_cnt nodupkey; by report_number; run;
data card_avg_credit_line_amt;
merge card_max_credit_line_amt_sum(in=a) card_uncancel_org_cnt(in=b);
by report_number;
if a;
if card_uncancel_org_cnt>0 then card_avg_credit_line_amt=card_max_credit_line_amt_sum/card_uncancel_org_cnt; else card_avg_credit_line_amt=0;
run;

/*贷记卡使用总额度Card_Credit_Used_Line_Total*/
proc sql;
create table card_credit_used_line_total as
select report_number, sum(USEDCREDIT_LINE_AMT) as card_credit_used_line_total
from card_detail
group by report_number
;
quit;

/*贷记卡额度使用率Card_Credit_Used_Percent*/
proc sort data=card_credit_used_line_total nodupkey; by report_number; run;
proc sort data=card_max_credit_line_amt_sum nodupkey; by report_number; run;
data card_credit_used_percent;
merge card_credit_used_line_total(in=a) card_max_credit_line_amt_sum(in=b);
by report_number;
if a;
if card_max_credit_line_amt_sum>0 then card_credit_used_percent=card_credit_used_line_total/card_max_credit_line_amt_sum; else card_credit_used_percent=0;
run;

/*贷记卡逾期总额Card_Pastdue_Total*/
proc sql;
create table card_pastdue_total as
select report_number, sum(PASTDUE_AMT) as card_pastdue_total
from card_detail
group by report_number
;
quit;


/*贷记卡相关变量汇总*/
proc sort data = card_org_cnt nodupkey; by report_number; run;
proc sort data = card_foreign_org_cnt nodupkey; by report_number; run;
proc sort data = card_uncancel_org_cnt nodupkey; by report_number; run;
proc sort data = card_first_open_month nodupkey; by report_number; run;
proc sort data = card_open_06_month_org_cnt nodupkey; by report_number; run;
proc sort data = card_open_24_month_org_cnt nodupkey; by report_number; run;
proc sort data = card_max_credit_line_amt nodupkey; by report_number; run;
proc sort data = card_max_credit_line_amt_sum nodupkey; by report_number; run;
proc sort data = card_avg_credit_line_amt nodupkey; by report_number; run;
proc sort data = card_credit_used_line_total nodupkey; by report_number; run;
proc sort data = card_credit_used_percent nodupkey; by report_number; run;
proc sort data = card_pastdue_total nodupkey; by report_number; run;
data card_info;
merge card_org_cnt(in = a)
		card_foreign_org_cnt(in = b)
		card_uncancel_org_cnt(in = c)
		card_first_open_month(in = d)
		card_open_06_month_org_cnt(in = e)
		card_open_24_month_org_cnt(in = f)
		card_max_credit_line_amt(in = g)
		card_max_credit_line_amt_sum(in = h)
		card_avg_credit_line_amt(in = i)
		card_credit_used_line_total(in = j)
		card_credit_used_percent(in = k)
		card_pastdue_total(in = l);
by report_number;
if a;
if card_foreign_org_cnt = . then card_foreign_org_cnt = 0;
if card_uncancel_org_cnt = . then card_uncancel_org_cnt = 0;
if card_open_06_month_org_cnt = . then card_open_06_month_org_cnt = 0;
if card_open_24_month_org_cnt = . then card_open_24_month_org_cnt = 0;

run;

****************************************************************************
贷款相关变量
***************************************************************************;

/*贷款明细*/
data loan_detail;
set credit_detail(where=(BUSI_TYPE="LOAN"));
if LOAN_BALANCE=. then LOAN_BALANCE=0;
if index(sub_busi_type, "汽车") or index(sub_busi_type, "商用房") or index(sub_busi_type, "住房") then 抵押贷款 = 1; else 抵押贷款 = 0;
run;

/*贷款总账户数Loan_Account_CNT*/
proc sql;
create table loan_account_cnt as
select report_number, real_name, count(*) as loan_account_cnt
from loan_detail
group by report_number, real_name
;
quit;

/*未结清贷款账户数Loan_Uncleared_Account_CNT*/
proc sql;
create table loan_uncleared_account_cnt as
select report_number, count(*) as loan_uncleared_account_cnt
from loan_detail
where ACCT_STATUS^="3"
group by report_number
;
quit;

/*首笔贷款发放距今月份数Loan_First_Open_Month*/
proc sql;
create table loan_first_open_month as
select report_number, max(open_month) as loan_first_open_month
from loan_detail
group by report_number
;
quit;

/*单笔最大贷款授信额度Loan_Max_Credit_Line_Amt*/
proc sql;
create table loan_max_credit_line_amt as
select report_number, max(CREDIT_LINE_AMT) as loan_max_credit_line_amt
from loan_detail
group by report_number
;
quit;

/*贷款总余额Loan_Balance_Sum*/
proc sql;
create table loan_balance_sum as
select report_number, sum(LOAN_BALANCE) as loan_balance_sum
from loan_detail
group by report_number
;
quit;

/*未结清贷款授信额度总和Loan_Uncleared_Credit_Line_Amt_Sum*/
proc sql;
create table loan_uncleared_line_amt_sum as
select report_number, sum(CREDIT_LINE_AMT) as loan_uncleared_line_amt_sum
from loan_detail
where ACCT_STATUS^="3"
group by report_number
;
quit;

/*贷款余额占授信总额的比例Loan_Balance_Percent*/
proc sort data=loan_balance_sum nodupkey; by report_number; run;
proc sort data=loan_uncleared_line_amt_sum nodupkey; by report_number; run;
data loan_balance_percent;
merge loan_balance_sum(in=a) loan_uncleared_line_amt_sum(in=b);
by report_number;
if a;
if loan_uncleared_line_amt_sum>0 then loan_balance_percent=loan_balance_sum/loan_uncleared_line_amt_sum; else loan_balance_percent=0;
run;

/*未结清抵押贷款(商用房、住房、公积金、汽车)账户数Loan_Uncleared_Mor_Account_CNT*/
proc sql;
create table loan_uncleared_mor_account_cnt as
select report_number, count(*) as loan_uncleared_mor_account_cnt
from loan_detail
where ACCT_STATUS^="3" and (index(SUB_BUSI_TYPE, "汽车") or index(SUB_BUSI_TYPE, "商用房") or index(SUB_BUSI_TYPE, "住房"))
group by report_number
;
quit;

/*未结清个人消费贷款账户数Loan_Uncleared_Con_Account_CNT*/
proc sql;
create table loan_uncleared_con_account_cnt as
select report_number, count(*) as loan_uncleared_con_account_cnt
from loan_detail
where ACCT_STATUS^="3" and index(SUB_BUSI_TYPE, "消费")
group by report_number
;
quit;

/*未结清大其他贷款(经营、助学、农户、其他)账户数Loan_Uncleared_Mor_Account_CNT*/
proc sql;
create table loan_uncleared_oth_account_cnt as
select report_number, count(*) as loan_uncleared_oth_account_cnt
from loan_detail
where ACCT_STATUS^="3" and (index(SUB_BUSI_TYPE, "经营") or index(SUB_BUSI_TYPE, "助学") or index(SUB_BUSI_TYPE, "农户") or index(SUB_BUSI_TYPE, "其他"))
group by report_number
;
quit;

/*个人消费贷款总余额Loan_Balance_Sum*/
proc sql;
create table loan_con_balance_sum as
select report_number, sum(LOAN_BALANCE) as loan_con_balance_sum
from loan_detail
where index(SUB_BUSI_TYPE, "消费")
group by report_number
;
quit;

/*个人大其他贷款(经营、助学、农户、其他)总余额Loan_Balance_Sum*/
proc sql;
create table loan_oth_balance_sum as
select report_number, sum(LOAN_BALANCE) as loan_oth_balance_sum
from loan_detail
where (index(SUB_BUSI_TYPE, "经营") or index(SUB_BUSI_TYPE, "助学") or index(SUB_BUSI_TYPE, "农户") or index(SUB_BUSI_TYPE, "其他"))
group by report_number
;
quit;

/*month_return*/
proc sql;
create table loan_month_return as
select report_number,
		sum(case when 抵押贷款 = 1 and acct_status ^= "3" then MONTHLY_PAYMENT else 0 end) as month_return_mort,
		sum(case when 抵押贷款 = 0 and acct_status ^= "3" then MONTHLY_PAYMENT else 0 end) as month_return_nonmort
from loan_detail
group by report_number
;
quit;

/*贷款逾期总额Loan_Pastdue_Sum*/
proc sql;
create table loan_pastdue_sum as
select report_number, sum(pastdue_amt) as loan_pastdue_sum
from loan_detail
group by report_number
;
quit;


/*贷款相关变量汇总*/
proc sort data = loan_account_cnt nodupkey; by report_number; run;
proc sort data = loan_uncleared_account_cnt nodupkey; by report_number; run;
proc sort data = loan_first_open_month nodupkey; by report_number; run;
proc sort data = loan_max_credit_line_amt nodupkey; by report_number; run;
proc sort data = loan_balance_sum nodupkey; by report_number; run;
proc sort data = loan_uncleared_line_amt_sum nodupkey; by report_number; run;
proc sort data = loan_balance_percent nodupkey; by report_number; run;
proc sort data = loan_uncleared_mor_account_cnt nodupkey; by report_number; run;
proc sort data = loan_uncleared_con_account_cnt nodupkey; by report_number; run;
proc sort data = loan_uncleared_oth_account_cnt nodupkey; by report_number; run;
proc sort data = loan_con_balance_sum nodupkey; by report_number; run;
proc sort data = loan_oth_balance_sum nodupkey; by report_number; run; 
proc sort data = loan_month_return nodupkey; by report_number; run;
proc sort data = loan_pastdue_sum nodupkey; by report_number; run;
/*贷款信息汇总*/
data loan_info;
merge loan_account_cnt(in = a)
		loan_uncleared_account_cnt(in = b)
		loan_first_open_month(in = c)
		loan_max_credit_line_amt(in = d)
		loan_balance_sum(in = e)
		loan_uncleared_line_amt_sum(in = f)
		loan_balance_percent(in = g)
		loan_uncleared_mor_account_cnt(in = h)
		loan_uncleared_con_account_cnt(in = i)
		loan_uncleared_oth_account_cnt(in = j)
		loan_con_balance_sum(in = k)
		loan_oth_balance_sum(in = l)
		loan_month_return(in = m)
		loan_pastdue_sum(in = n)
		;
by report_number; 
if a;
if loan_uncleared_account_cnt = . then loan_uncleared_account_cnt = 0;
if loan_uncleared_line_amt_sum = . then loan_uncleared_line_amt_sum = 0;
run;

********************************************************************************
查询相关变量
*******************************************************************************;

/*最近查询次数-本人查询*/
proc sql;
create table self_query_frequency as
select report_number,
		sum(in1month) as self_query_01_month_frequency,
		sum(in3month) as self_query_03_month_frequency,
		sum(in6month) as self_query_06_month_frequency,
		sum(in12month) as self_query_12_month_frequency,
		sum(in24month) as self_query_24_month_frequency
from credit_query_record
where QUERY_OPERATOR = "2"
group by report_number
;
quit;

/*最近查询次数-机构查询*/
proc sql;
create table org_query_frequency as
select report_number, 
		sum(in1month) as org_query_01_month_frequency,
		sum(in3month) as org_query_03_month_frequency,
		sum(in6month) as org_query_06_month_frequency,
		sum(in12month) as org_query_12_month_frequency,
		sum(in24month) as org_query_24_month_frequency
from credit_query_record
where QUERY_OPERATOR = "1"
group by report_number
;
quit;

/*最近查询次数-信用卡审批*/
proc sql;
create table card_apply_frequency as
select report_number, 
		sum(in1month) as card_apply_01_month_frequency,
		sum(in3month) as card_apply_03_month_frequency,
		sum(in6month) as card_apply_06_month_frequency,
		sum(in12month) as card_apply_12_month_frequency,
		sum(in24month) as card_apply_24_month_frequency
from credit_query_record
where QUERY_REASON = "2"
group by report_number
;
quit;

/*最近查询次数-贷款审批*/
proc sql;
create table loan_apply_24_month_frequency as
select report_number, 
		sum(in1month) as loan_apply_01_month_frequency,
		sum(in3month) as loan_apply_03_month_frequency,
		sum(in6month) as loan_apply_06_month_frequency,
		sum(in12month) as loan_apply_12_month_frequency,
		sum(in24month) as loan_apply_24_month_frequency
from credit_query_record
where QUERY_REASON = "1"
group by report_number
;
quit;

/*查询信息汇总*/
proc sort data = self_query_frequency nodupkey; by report_number; run;
proc sort data = org_query_frequency nodupkey; by report_number; run;
proc sort data = card_apply_frequency nodupkey; by report_number; run;
proc sort data = loan_apply_24_month_frequency nodupkey; by report_number; run;
data query_info;
merge self_query_frequency(in = a)
		org_query_frequency(in = b)
		card_apply_frequency(in = c)
		loan_apply_24_month_frequency(in = d);
by report_number;
if self_query_01_month_frequency = . then self_query_01_month_frequency = 0;
if self_query_03_month_frequency = . then self_query_03_month_frequency = 0;
if self_query_06_month_frequency = . then self_query_06_month_frequency = 0;
if self_query_12_month_frequency = . then self_query_12_month_frequency = 0;
if self_query_24_month_frequency = . then self_query_24_month_frequency = 0;

if org_query_01_month_frequency = . then org_query_01_month_frequency = 0;
if org_query_03_month_frequency = . then org_query_03_month_frequency = 0;
if org_query_06_month_frequency = . then org_query_06_month_frequency = 0;
if org_query_12_month_frequency = . then org_query_12_month_frequency = 0;
if org_query_24_month_frequency = . then org_query_24_month_frequency = 0;

if card_apply_01_month_frequency = . then card_apply_01_month_frequency = 0;
if card_apply_03_month_frequency = . then card_apply_03_month_frequency = 0;
if card_apply_06_month_frequency = . then card_apply_06_month_frequency = 0;
if card_apply_12_month_frequency = . then card_apply_12_month_frequency = 0;
if card_apply_24_month_frequency = . then card_apply_24_month_frequency = 0;

if loan_apply_01_month_frequency = . then loan_apply_01_month_frequency = 0 ;
if loan_apply_03_month_frequency = . then loan_apply_03_month_frequency = 0 ;
if loan_apply_06_month_frequency = . then loan_apply_06_month_frequency = 0 ;
if loan_apply_12_month_frequency = . then loan_apply_12_month_frequency = 0 ;
if loan_apply_24_month_frequency = . then loan_apply_24_month_frequency = 0 ;

run;


***************************************************************************
征信报告信息汇总
**************************************************************************;
proc sort data = crRaw.credit_report out = credit_report nodupkey; by report_number; run;
proc sort data = card_info nodupkey; by report_number; run;
proc sort data = loan_info nodupkey; by report_number; run;
proc sort data = query_info nodupkey; by report_number; run;
data crMid.pboc_info;
merge credit_report(in = a)
		card_info(in = b)
		loan_info(in = c)
		query_info(in = d)
		report_date(in = e);
by report_number;
if a;

if card_first_open_month = . then card_first_open_month = -9;
if card_org_cnt = . then card_org_cnt = 0;
if card_foreign_org_cnt = . then card_foreign_org_cnt = 0;
if card_uncancel_org_cnt = . then card_uncancel_org_cnt = 0;
if card_open_06_month_org_cnt = . then card_open_06_month_org_cnt = 0;
if card_open_24_month_org_cnt = . then card_open_24_month_org_cnt = 0;
if card_max_credit_line_amt = . then card_max_credit_line_amt = 0;
if card_max_credit_line_amt_sum = . then card_max_credit_line_amt_sum = 0;
if card_avg_credit_line_amt = . then card_avg_credit_line_amt = 0;
if card_credit_used_line_total = . then card_credit_used_line_total = 0;
if card_credit_used_percent = . then card_credit_used_percent = 0;

if loan_first_open_month = . then loan_first_open_month = -9;
if loan_account_cnt = . then loan_account_cnt = 0;
if loan_uncleared_account_cnt = . then loan_uncleared_account_cnt = 0;
if loan_max_credit_line_amt = . then loan_max_credit_line_amt = 0;
if loan_balance_sum = . then loan_balance_sum = 0;
if loan_uncleared_line_amt_sum = . then loan_uncleared_line_amt_sum = 0;
if loan_balance_percent = . then loan_balance_percent = 0;

if self_query_01_month_frequency = . then self_query_01_month_frequency = 0;
if self_query_03_month_frequency = . then self_query_03_month_frequency = 0;
if self_query_06_month_frequency = . then self_query_06_month_frequency = 0;
if self_query_12_month_frequency = . then self_query_12_month_frequency = 0;
if self_query_24_month_frequency = . then self_query_24_month_frequency = 0;

if org_query_01_month_frequency = . then org_query_01_month_frequency = 0;
if org_query_03_month_frequency = . then org_query_03_month_frequency = 0;
if org_query_06_month_frequency = . then org_query_06_month_frequency = 0;
if org_query_12_month_frequency = . then org_query_12_month_frequency = 0;
if org_query_24_month_frequency = . then org_query_24_month_frequency = 0;

if card_apply_01_month_frequency = . then card_apply_01_month_frequency = 0;
if card_apply_03_month_frequency = . then card_apply_03_month_frequency = 0;
if card_apply_06_month_frequency = . then card_apply_06_month_frequency = 0;
if card_apply_12_month_frequency = . then card_apply_12_month_frequency = 0;
if card_apply_24_month_frequency = . then card_apply_24_month_frequency = 0;

if loan_apply_01_month_frequency = . then loan_apply_01_month_frequency = 0 ;
if loan_apply_03_month_frequency = . then loan_apply_03_month_frequency = 0 ;
if loan_apply_06_month_frequency = . then loan_apply_06_month_frequency = 0 ;
if loan_apply_12_month_frequency = . then loan_apply_12_month_frequency = 0 ;
if loan_apply_24_month_frequency = . then loan_apply_24_month_frequency = 0 ;

card_reject_06_month_frequency = card_apply_06_month_frequency - card_open_06_month_org_cnt;
card_reject_24_month_frequency = card_apply_24_month_frequency - card_open_24_month_org_cnt;

format 征信获取时间 yymmdd10.;
征信获取时间 = datepart(created_time);
drop created_time;
run;


/*data credit_report;*/
/*set crRaw.credit_report(keep = report_number created_time);*/
/*format 征信获取时间 yymmdd10.;*/
/*征信获取时间 = datepart(created_time);*/
/*drop created_time;*/
/*run;*/
/**/
/*proc sort data = credit_report nodupkey; by report_number; run;*/
/*proc sort data = crmid.pboc_info out = pboc_info nodupkey; by report_number; run;*/
/*data crmid.pboc_info;*/
/*merge pboc_info(in = a) credit_report(in = b);*/
/*by report_number;*/
/*if a;*/
/*run;*/
data crmid.pboc_info;
set crmid.pboc_info crmid.pboc_info_1;
run;

proc sql;
create table pboc_info as
select a.apply_code, b.*
from appMid.apply_time as a
inner join crMid.pboc_info as b on a.id_card_no = b.id_card and datepart(a.apply_time) >= b.征信获取时间
;
quit;
proc sort data = pboc_info nodupkey; by apply_code descending 征信获取时间; run;
proc sort data = pboc_info out = crMid.pboc_info nodupkey; by apply_code; run;

data crmid.pboc_achieve_time;
set crmid.pboc_info(keep = apply_code 征信获取时间);
run;


/*模型用到的征信变量*/
data crMid.model_var;
set crMid.pboc_info(keep = apply_code card_first_open_month 
						self_query_24_month_frequency org_query_24_month_frequency
						self_query_03_month_frequency org_query_03_month_frequency
						card_open_06_month_org_cnt card_foreign_org_cnt
						card_reject_06_month_frequency card_reject_24_month_frequency 
						card_credit_used_percent loan_first_open_month card_avg_credit_line_amt card_max_credit_line_amt
						CREDIT_VALID_ACCT_SUM loan_uncleared_mor_account_cnt loan_uncleared_con_account_cnt loan_uncleared_oth_account_cnt
						loan_con_balance_sum loan_oth_balance_sum
						);
s2yquery = self_query_24_month_frequency + org_query_24_month_frequency;
s3mquery = self_query_03_month_frequency + org_query_03_month_frequency;
rename s2yquery = 近2年查询次数 s3mquery = 近3个月查询次数
		card_reject_24_month_frequency = 近2年信用卡申请被拒次数 card_reject_06_month_frequency = 近6个月信用卡申请被拒次数
		card_first_open_month = 信用卡使用时长 
		card_credit_used_percent = 信用卡使用率 
		card_avg_credit_line_amt = 信用卡平均授信额度 
		card_foreign_org_cnt = 有外币账户的信用卡张数 
		card_open_06_month_org_cnt = 近6个月新开信用卡张数
		card_max_credit_line_amt = 信用卡最大授信额度
		loan_first_open_month = 贷款发放时长
		loan_uncleared_mor_account_cnt = 未结清抵押贷款数量
		loan_uncleared_con_account_cnt = 未结清消费贷款数量
		loan_uncleared_oth_account_cnt = 未结清其他贷款数量
		loan_con_balance_sum = 未结清消费贷款余额
		loan_oth_balance_sum = 未结清其他贷款余额
		CREDIT_VALID_ACCT_SUM = 未结清信用卡账户数
		;
drop self_query_24_month_frequency org_query_24_month_frequency self_query_03_month_frequency org_query_03_month_frequency;
run;

option missing=.;


/*credit_score*/
proc sort data = appMid.credit_score out = credit_score1; by apply_code;run;
proc sort data = crMid.credit_score out = credit_score2; by apply_code;run;


data crMid.credit_score;
merge credit_score2 credit_score1 ;
by apply_code;
run;


