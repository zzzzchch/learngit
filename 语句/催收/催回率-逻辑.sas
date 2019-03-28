************
1-16号分配的客户都是跟进到月底最后一天截止，17-30号分配的客户是C-M1的客户了,有时候17号之后分配的C-M1的客户到下个月就变成了M1-M2了
************;
data aa;
format dt yymmdd10.;

/*if weekday(today())=2 then dt=today()-3;*/
/*else if weekday(today())=1 then dt=today()-2;*/
/*else dt=today()-1;*/

dt=today()-1;
db=intnx("month",dt,0,"b");
dbpe=intnx("month",dt,0,"b")-1;
db1=intnx("month",dt,-1,"b")+16;
db2=intnx("month",dt,0,"e");
if weekday(dt)=1 then do;weekf=intnx('week',dt,-1)+1;end;
	else do; weekf=intnx('week',dt,0)+1;end;
call symput("dt", dt);
call symput("weekf",weekf);
call symput("db", db);
call symput("dbpe", dbpe);
call symput("db1", db1);
call symput("db2", db2);
run;



data mmlist;
set repayfin.dail_bdgx;

/*reason：张玉萍表示，这个客户暂时放在朱琨主管名下协助跟进，实际为陈秀芬的客户，客户情况特殊。*/
if contract_no="C152239781313802300006770" and username="朱琨" then username="陈秀芬";
/*deal：手工调整，4月初删除该条数据*/

if username in ("杜盼辉","洪高悬","张政嘉","廖翠玲","黄丽华","吴振杭","邱智超",'白璐','陈侃','陈天森','陈秀芬','黄晓妮');
if &db.<=cut_date<=&db2.;
run;

data payment_daily;
set repayfin.payment_daily(where=(营业部^="APP"));
by contract_no cut_date;
run;
proc sql;
create table mmlist_1 as 
select a.*, b.客户姓名, b.营业部, b.资金渠道,e.贷款余额  from mmlist as a
left join payment_daily as b on a.contract_no=b.contract_no and a.cut_date=b.cut_date
left join repayfin.payment as e on a.contract_no=e.contract_no and e.cut_date=&dbpe.;
quit;



data mmlist_2;
set mmlist_1;
if 资金渠道 in ("xyd1","xyd2") then 资金渠道="小雨点";
	else if 资金渠道 in ("bhxt1","bhxt2") then 资金渠道="渤海信托";
	else if 资金渠道 in ("mindai1") then 资金渠道="民贷";
	else if 资金渠道 in ("ynxt1","ynxt2","ynxt3") then 资金渠道="云南信托";
	else if 资金渠道 in ("jrgc1") then 资金渠道="金融工厂";
	else if 资金渠道 in ("irongbei1") then 资金渠道="融贝";
	else if 资金渠道 in ("fotic3","fotic2") then 资金渠道="单一出借人";
	else if 资金渠道 in ("haxt1") then 资金渠道="华澳信托";
	else if 资金渠道 in ("p2p") then 资金渠道="中科财富";
	else if 资金渠道 in ("jsxj1") then 资金渠道="晋商消费金融";
	else if 资金渠道 in ("lanjingjr1") then 资金渠道="蓝鲸金融";
	else if 资金渠道 in ("yjh1","yjh2") then 资金渠道="益菁汇";
	else if 资金渠道 in ("rx1") then 资金渠道="容熙";
	else if 资金渠道 in ("hapx1") then 资金渠道="华澳鹏欣";
	else if 资金渠道 in ("tsjr1") then 资金渠道="通善金融";
run;
proc sort data=mmlist_2;by contract_no cut_date;run;

data mmlist_3;
set mmlist_2;
by contract_no;
if username not in ('杜盼辉','洪高悬') and segment_name^="M1-M2" then delete;
if username in ('杜盼辉','洪高悬') and segment_name^="M2-M3" then delete;
run;
proc sort data=mmlist_3;by contract_no descending cut_date;run;
proc sort data=mmlist_3 out=mmlist_3 nodupkey;by contract_no issues segment_name;run;


proc sql;
create table mmlist_3_2 as 
select a.*,b.催收员 from mmlist_3 as a
left join mmlist_3_1_a as b on a.contract_no=b.合同;
/*left join mmlist_3_1_a as c on a.contract_no=c.合同;*/
quit;


data mmlist_3;
set mmlist_3_2;
if segment_name="M2-M3" and 催收员="" then delete;
/*if 阶段="M1-M2" and 催收员^="" then userName=催收员;*/
run;

************************************************** 减免 ********************************************************************;
data fee_breaks_apply_dtl;
set account.fee_breaks_apply_dtl;
run;
data fee_breaks_apply_dtl_;
set fee_breaks_apply_dtl;
if kindex(contract_no,"C");
if FEE_CODE^='7009';
run;
proc sql;
create table fee_breaks_jm_1_a as 
select contract_no,PERIOD,sum(BREAKS_AMOUNT) as 罚息减免 from fee_breaks_apply_dtl_ group by contract_no,PERIOD;
quit;
proc sql;
create table fee_breaks_jm_1_b as 
select a.*,b.clear_date from fee_breaks_jm_1_a as a 
left join account.bill_main(where=(substr(bill_code,1,3)="BLC")) as b on a.contract_no=b.contract_no and a.period=b.CURR_PERIOD;
quit;
proc sql;
create table fee_breaks_jm_1 as 
select contract_no,sum(罚息减免) as 罚息减免 
from fee_breaks_jm_1_b 
where &dbpe.<=clear_date<=&dt.
group by contract_no;
quit;
************************************************** 减免 ********************************************************************;
*由于存在不同时间催回两期这种情况，计算当月实际催回金额;

************下月初删除*************;
data account.bill_main;
set account.bill_main;
if ID=297880 THEN clear_date=mdy(02,28,2019);
run;
************下月初删除*************;

proc sql;
create table bill_main_a as 
select a.*,b.userName,b.cut_date 
from account.bill_main as a
left join repayfin.dail_bdgx as b on a.contract_no=b.contract_no and a.CLEAR_DATE=b.cut_date;
quit;


proc sql;
create table bill_main_b as 
select contract_no,sum(CURR_RECEIVE_AMT) as CURR_RECEIVE_AMT,max(clear_date) as clear_date
from bill_main_a 
where &dbpe.<=clear_date<=&dt. and userName in ("杜盼辉","洪高悬","张政嘉","黄丽华","廖翠玲","吴振杭","邱智超",'白璐','陈侃','陈天森','陈秀芬','黄晓妮',"龙嘉苑")
group by contract_no;
quit;


proc sql;
create table mmlist_4 as 
select a.*,d.CURR_RECEIVE_AMT as 实际金额,c.罚息减免 from mmlist_3 as a
left join bill_main_b as d on a.contract_no=d.contract_no 
left join fee_breaks_jm_1 as c on a.contract_no=c.contract_no;
quit;
proc sort data=mmlist_4;by contract_no descending issues descending ASSIGN_TIME;run;
proc sort data=mmlist_4 nodupkey;by contract_no descending issues;run;
data mmlist_5;
set mmlist_4;
if 罚息减免=. then 罚息减免=0;
实际金额=实际金额-罚息减免;
/*if od_days-lag_od_days^=1 and lag_od_days>30 then clear_date=cut_date;*/
if datepart(settlement_date)>&dt. or datepart(settlement_date)<&db. then do;实际金额=0;settlement_date=.;end;
if settlement_date=. then 实际金额=.;
run;
proc sort data=mmlist_5;by contract_no username;run;
proc sort data=mmlist_5 nodupkey;by contract_no username;run;
proc sort data=mmlist_5;by descending settlement_date segment_name username;run;

data mmlist_7;
set mmlist_5;
format repy_date yymmdd10.;
repy_date=datepart(settlement_date);

/*该客户为取消提前结清客户，导致payment表中的贷款余额为负数*/
if contract_no ="C2016092315304619856732" then 贷款余额=5675.468; 

if settlement_date not in (0,.) then 催回余额=贷款余额;
    else 催回余额=0;
if 外访中=1 and settlement_date>1 then 催回余额外访=贷款余额/2;
	else if 外访中=0 and settlement_date>1 then 催回余额外访=贷款余额;
	else 催回余额外访=0;
if 外访中=1 and 实际金额>1 then 实际金额外访=实际金额/2;
	else if 外访中=0 and 实际金额>1 then 实际金额外访=实际金额;
if 实际金额=. then 实际金额=0;
run;

proc sort data=mmlist_7;by descending repy_date segment_name username;run;
proc sql;
create table mmlist_8_1 as 
select username,sum(贷款余额) as 贷款余额,sum(催回余额) as 催回余额,sum(催回余额外访) as 催回余额外访,sum(实际金额) as 实际金额,sum(实际金额外访) as 实际金额外访 from mmlist_7 
where segment_name in ('M1-M2','M2-M3')
group by username;
quit;
proc sql;
create table mmlist_8_2 as 
select username,sum(催回余额) as 催回余额day,count(催回余额) as 催回数量day from mmlist_7 where repy_date=&dt. and segment_name in ('M1-M2','M2-M3') group by username;
quit;
data _null_;
format dt yymmdd10.; 
dt = today() - 1;
call symput("dt", dt);
run;
proc sql;
create table mmlist_8_4 as 
select username,sum(催回余额) as 催回余额week,sum(催回余额外访) as 催回余额外访week from mmlist_7 where &weekf.<=repy_date<=&dt. and segment_name in ('M1-M2','M2-M3') group by username;
quit;

proc sql;
create table mmlist_9 as 
select a.*,b.*,c.*,d.* from mmlist_8_3 as a
left join mmlist_8_2 as b on a.username=b.username
left join mmlist_8_1 as c on a.username=c.username
left join mmlist_8_4 as d on a.username=d.username;
quit;
proc sort data=mmlist_9;by 序号;run;
data mmlist_10;
set mmlist_9;
array num _numeric_;
Do Over num;
If num="." Then num=0;
End;
array char _character_;
Do Over char;
If char=" " Then char='0';
End;
Run;
filename DD DDE "EXCEL|[催回率及实收统计.xlsx]report!r3c5:r14c8";
data _null_;set mmlist_10;file DD;put 催回余额day 催回数量day 贷款余额 催回余额;run;
filename DD DDE "EXCEL|[催回率及实收统计.xlsx]report!r3c10:r14c10";
data _null_;set mmlist_10;file DD;put 催回余额外访;run;
filename DD DDE "EXCEL|[催回率及实收统计.xlsx]report!r3c12:r14c14";
data _null_;set mmlist_10;file DD;put 实际金额 实际金额外访 催回余额week;run;
filename DD DDE "EXCEL|[催回率及实收统计.xlsx]report!r3c16:r14c16";
data _null_;set mmlist_10;file DD;put 催回余额外访week;run;

data aa;
set mmlist_7;
format settlement_date yymmdd10.;
keep contract_no segment_name 客户姓名 营业部 资金渠道 贷款余额 username 外访中 实际金额 repy_date;
run;
filename DD DDE "EXCEL|[催回率及实收统计.xlsx]明细!r2c1:r2000c10";
data _null_;set aa;file DD;put contract_no segment_name 客户姓名 营业部 资金渠道 贷款余额 username 外访中 实际金额 repy_date;run;
