/*需要先跑中间表cs_table1_tab_xx_;*/
data repay_plan_qk;
set account.repay_plan;
if CURR_PERIOD=1;
期款=CURR_RECEIVE_CAPITAL_AMT+CURR_RECEIVE_INTEREST_AMT;
run;
proc sort data=repay_plan_qk nodupkey;by contract_no;run;
data payment_daily;
set repayfin.payment_daily;
if 营业部^="APP";
if kindex(contract_no,"C");
run;
proc sort data=payment_daily;by contract_no cut_date;run;
data payment_daily_;
set payment_daily;
by contract_no;
lag_od_days=lag(od_days);
keep contract_no clear_date od_days cut_date lag_od_days 营业部 客户姓名;
run;
*存在当天电话当天还款，这部分客户的欠款几乎=0，造cs_table1_tab2来用lag_欠款替换;
proc sql;
create table cs_table1_tab1_xx as
select a.*,b.lag_od_days,b.od_days,b.营业部,c.期款 from repayfin.cs_table1_tab_xx_ as a
left join payment_daily_ as b on a.contract_no=b.contract_no and a.联系日期=b.cut_date
left join repay_plan_qk as c on a.contract_no=c.contract_no;
quit;
data cs_table1_tab2_xx;
set cs_table1_tab1_xx;
if lag_od_days=od_days-1 then do;
	if od_days>=90 then 欠款=期款*4;
	else if 90>od_days>=60 then 欠款=期款*3;
	else if 60>od_days>=30 then 欠款=期款*2;
	else 欠款=期款;
end;
else do;
	if lag_od_days+1>=90 then 欠款=期款*4;
	else if 90>lag_od_days+1>=60 then 欠款=期款*3;
	else if 60>lag_od_days+1>=30 then 欠款=期款*2;
	else 欠款=期款;
end;
*删除温馨提醒呼出;
/*if 营业部 in ("南京市第一营业部","重庆市第一营业部","南京市业务中心","江门市业务中心","南通市业务中心","深圳市第一营业部","深圳市业务中心") and RESULT='' then delete;*/
if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬",'白璐',"陈侃","陈天森",'黄晓妮',"龙嘉苑","黄丽华") and kindex(CALL_ACTION_ID,"PRE")>0 then delete;
run;
*可以用lag_odays来区分8-60这个区间，考虑到催收同事的工作效果，暂时取数逻辑不变，报表显示8-60吧;
/*proc sql;*/
/*create table cs_table1_tab1 as*/
/*select a.*,b.lag_odays from cs_table1_tab as a*/
/*left join payment_day_last as b on a.contract_no=b.contract_no and a.联系日期=b.cut_date;*/
/*quit;*/
*拨打;
proc sort data=cs_table1_tab2_xx   out=mtd_dail_xx;by contract_no username  descending 拨打;run;
proc sort data=mtd_dail_xx nodupkey;by id;run;
/*proc sort data=mtd_dail nodupkey;by contract_no username ;run;*/
proc sql;
create table person_dail_xx as
select username,sum(拨打) as dail_sum from mtd_dail_xx group by username;quit;

proc sql;
create table person_dail_xx_br as
select username,sum(拨打) as dail_sum from mtd_dail_xx(where=(联系人=0)) group by username;quit;

proc sql;
create table person_dail_xx_nobr as
select username,sum(拨打) as dail_sum from mtd_dail_xx(where=(联系人=1)) group by username;quit;

*拨通;
/*proc sort data=mtd_dail nodupkey;by contract_no username ;run;*/
proc sql;
create table person_dail_su_xx as
select username,sum(拨通) as dail_susum from mtd_dail_xx group by username;quit;

proc sql;
create table person_dail_su_xx_br as
select username,sum(拨通) as dail_susum from mtd_dail_xx(where=(联系人=0)) group by username;quit;

proc sql;
create table person_dail_su_xx_nobr as
select username,sum(拨通) as dail_susum from mtd_dail_xx(where=(联系人=1)) group by username;quit;

*承诺还款;
proc sql;
create table person_dail_ptp_xx as
select username,sum(承诺还款) as dail_ptp from mtd_dail_xx group by username;quit;
proc sql;
create table person_dail_ptps_xx as
select username,sum(欠款) as dail_ptps from mtd_dail_xx(where=(承诺还款=1)) group by username;quit;

proc sort data=mtd_dail_xx;by contract_no 联系日期 username descending 承诺还款;run;
proc sort data=mtd_dail_xx out=mtd_dail_xx_;by contract_no 联系日期 username descending 承诺还款;run;

*每天保留一条拨打记录拼入payment，通过retain保留拨打和承诺还款，到clear_date有值时就表示催回;
proc sql;
create table mtd_pay4_0 as
select a.*,b.承诺还款,b.username,b.拨打,b.欠款
from payment_daily_(where=(cut_date^=&db.-1)) as a
left join mtd_dail_xx_ as b on a.contract_no=b.contract_no and a.cut_date=b.联系日期;
quit;
proc sort data=mtd_pay4_0;by contract_no cut_date;run;
data mtd_pay4_1;
set mtd_pay4_0;
array num _numeric_;
Do Over num;
If num="." Then num=0;
End;
if od_days^=lag_od_days+1 and lag_od_days^=0 then clear_date=cut_date;
run;
data mtd_pay4_2;
set mtd_pay4_1;
by contract_no;
retain 催回拨打 催回承诺;
if first.contract_no then do;催回拨打=拨打;催回承诺=承诺还款;end;
else do;催回拨打=max(催回拨打,拨打);催回承诺=max(催回承诺,承诺还款);end;
run;
*如果一天有两个人拨打时，此处只会保留一个人的记录，暂时不管这种情况;
data mtd_pay4_3;
set mtd_pay4_2;
by contract_no;
retain 坐席;
if first.contract_no then do;坐席=username;end;
else if username^='' then 坐席=username;
else 坐席=坐席;
drop username;
run;
data mtd_pay4;
set mtd_pay4_3;
if 催回拨打=1 and 催回承诺=0 and clear_date=cut_date then 非承诺且还=1;else 非承诺且还=0;
if 催回拨打=1 and 催回承诺=1 and clear_date=cut_date then 承诺且还=1;else 承诺且还=0;
if contract_no='' and cut_date=mdy(10,8,2018) then do;承诺且还=1;clear_date=cut_date;end;
rename 坐席=username;
run;
proc sort data=mtd_pay4;by contract_no cut_date;run;
proc sort data=mtd_pay4 nodupkey;by contract_no cut_date;run;
********************************************** 结清金额 start****************************************************************;
libname acco odbc database=account_nf;
data bill_main_m;
set account.bill_main;
if &dt.>=clear_date>=&db.;
if not kindex(BILL_CODE,'EB');
run;
data fee_breaks_apply_dtl;
set acco.fee_breaks_apply_dtl;
run;
data fee_breaks_apply_dtl_;
set fee_breaks_apply_dtl;
if kindex(contract_no,"C");
if FEE_CODE^='7009';
run;
proc sql;
create table fee_breaks_jm_1 as 
select contract_no,PERIOD,sum(BREAKS_AMOUNT) as 罚息减免 from fee_breaks_apply_dtl_ group by contract_no,PERIOD;
quit;
proc sql;
create table bill_main_m2 as 
select a.contract_no,a.CURR_PERIOD,a.clear_date,a.CURR_RECEIVE_AMT as 总金额,b.罚息减免 from bill_main_m as a
left join fee_breaks_jm_1 as b on a.contract_no=b.contract_no and a.CURR_PERIOD=b.PERIOD;
quit;
data bill_main_m3;
set bill_main_m2;
array num _numeric_;
Do Over num;
If num="." Then num=0;
End;
实收金额=总金额-罚息减免;
run;
proc sql;
create table bill_main_m4 as 
select contract_no,clear_date,sum(实收金额) as 实收金额 from bill_main_m3 group by contract_no,clear_date;
quit;
proc sort data=bill_main_m4;by contract_no clear_date;run;
proc rank data=bill_main_m4 out=bill_main_m4_;var clear_date;ranks rank_;by contract_no;run;

data mtd_pay5;
set mtd_pay4;
if 承诺且还=1 or 非承诺且还=1;
run;
proc sort data=mtd_pay5;by contract_no clear_date;run;
proc rank data=mtd_pay5 out=mtd_pay5_;var clear_date;ranks rank_;by contract_no;run;
proc sql;
create table mtd_pay6 as 
select a.*,b.实收金额 as 实收金额a,c.期款,d.实收金额 from mtd_pay5_ as a
left join bill_main_m4 as b on a.contract_no=b.contract_no and a.clear_date=b.clear_date
left join repay_plan_qk as c on a.contract_no=c.contract_no
left join bill_main_m4_ as d on a.contract_no=d.contract_no and a.rank_=d.rank_;
quit;
data mtd_pay7;
set mtd_pay6;
if 实收金额a>1 then 实收金额=实收金额a;
if od_days=0 and lag_od_days=0 then 实收金额=期款;
if 实收金额 in (0,.) then 实收金额=期款;
drop rank_ 欠款 实收金额a; 
run;
proc sort data=mtd_pay7;by contract_no cut_date;run;
proc sort data=mtd_pay7 nodupkey;by contract_no cut_date;run;
**************************************************************************************************************;
**个数;
proc sql;
create table mtd_pay_ptpn_xx as
select username,sum(承诺且还) as ptpn from mtd_pay7 group by username
;
quit;
**金额;
proc sql;
create table mtd_pay_ptps_xx as
select username,sum(实收金额) as ptps from mtd_pay7(where=(承诺且还=1)) group by username;
quit;
*之前定义过承诺还款为1、0,所以这里承诺还款为0的判断是有限制效果的，如果只定义承诺还款为1,那除了1其他全部是.;
*未承诺还款却还了;
**金额;
proc sql;
create table mtd_pay_nptps_xx as
select username,sum(实收金额) as nptps from mtd_pay7(where=(非承诺且还=1)) group by username;
quit;
**个数;
proc sql;
create table mtd_pay_nptpc_xx as
select username,sum(非承诺且还) as nptpc from mtd_pay7 group by username;
quit;

data test_lr_e_D;
set repayfin.test_lr_b;
if 当天流入调整=1 then do;当天流入=当天流入调整; 当天队列=0;end;
if kindex(contract_no,"C");
/*if repay_date=cut_date then 流失率分母=1;else 流失率分母=0;*/
if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬",'白璐',"陈侃","陈天森",'高宏','袁明明','吴夏姣','易迁英',"胡宸玮","丁洁",'黄晓妮',"龙嘉苑","刘佳","黄丽华");
drop 当天流入调整;
run;
*通过最后一次分配坐席来确定当天队列的件是不是没有在坐席队列，已经流给到何建伟;
data kanr_c;
set repayfin.kanr;
if 分配日期<=&dt.;
run;
proc sort data=kanr_c;by contract_no descending ASSIGN_TIME;run;
proc sort data=kanr_c nodupkey;by contract_no;run;
proc sql;
create table test_lr_e_D1 as
select a.*,b.od_days as od_daysx,c.od_days as od_daysx_db,d.CUSTOMER_STATUS,e.username as username_c
from test_lr_e_D as a
left join payment_daily(where=(cut_date=&dt.)) as b on a.contract_no=b.contract_no
left join payment_daily(where=(cut_date=&db.)) as c on a.contract_no=c.contract_no
left join csdata.ctl_contracts as d on a.contract_no=d.contract_no
left join kanr_c as e on a.contract_no=e.contract_no;
quit;
*米粒之所以在逾期第31天时，当天队列=0是因为系统很准时的将件调到建伟那里;
*队列数据根据月底逾期得来;
data test_lr_e_D2;
set test_lr_e_D1;
if username in ("杜盼辉","洪高悬") then do;
	if cut_date=&db. and 30<=od_daysx_db<=61 and 当天队列=1 then 累计队列=1;
		else if &db.<=cut_date<=&dt. and 当天流入=1 then 累计队列=1;
		else 累计队列=0;
	if cut_date=&dt. and 31<=od_daysx<=60+day(&dt.) and username=username_c then 当天计算队列=1;else 当天计算队列=0;
end;
else if username in ("朱琨","张政嘉","蒋文","吴振杭","邱智超","陈秀芬",'白璐',"陈侃","陈天森",'黄晓妮',"龙嘉苑","廖翠玲","黄丽华") then do;
	if cut_date=&db. and 16<=od_daysx_db<=31 and 当天队列=1 then 累计队列=1;
		else if &db.<=cut_date<=&dt. and 当天流入=1 then 累计队列=1;
		else 累计队列=0;
	if cut_date=&dt. and 16<=od_daysx<=30+day(&dt.) and username=username_c then 当天计算队列=1;else 当天计算队列=0;
end;
else if username in ("胡宸玮",'夏多宜','高宏','吴夏姣','易迁英',"丁洁",'袁明明',"刘佳") then do;
	if cut_date=&db. and 当天队列=1 then 累计队列=1;
		else if &db.<=cut_date<=&dt. and 当天流入=1 then 累计队列=1;
		else 累计队列=0;
	if cut_date=&dt. and 当天队列=1 and username=username_c then 当天计算队列=1;else 当天计算队列=0;
end;
if 累计队列=1 and CUSTOMER_STATUS='失联' then 失联=1;else 失联=0;
run;
proc sql;
create table dt_xx as
select username,sum(当天计算队列) as 当天队列 from test_lr_e_D2 group by username;
quit;
/*proc sort data=test_lr_e_D2 ;by contract_no username descending 累计队列;run;*/
/*proc sort data=test_lr_e_D2 nodupkey;by contract_no username;run;*/
proc sql;
create table ljdl_xx as
select username,sum(累计队列) as 累计队列,sum(失联) as 失联 from test_lr_e_D2 group by username;
quit;

proc sql;
create table cs_all_xx as
select a.序号,a.姓名,b.当天队列,c.dail_sum as 拨打,d.dail_susum as 拨通,e.dail_ptp as 承诺数,
f.dail_ptps as 承诺金额,g.ptpn as 承诺且还数,h.ptps as 承诺且还金额,i.nptps as 未承诺却还金额,j.nptpc as 未承诺却还数,k.累计队列,k.失联
from list as a
left join dt_xx as b on a.姓名=b.userName
left join person_dail_xx as c on a.姓名=c.userName
left join person_dail_su_xx as d on a.姓名=d.userName
left join person_dail_ptp_xx as e on a.姓名=e.userName
left join person_dail_ptps_xx as f on a.姓名=f.username
left join mtd_pay_ptpn_xx as g on a.姓名=g.username
left join mtd_pay_ptps_xx as h on a.姓名=h.username
left join mtd_pay_nptps_xx as i on a.姓名=i.username
left join mtd_pay_nptpc_xx as j on a.姓名=j.username
left join ljdl_xx as k on a.姓名=k.username;
quit;
proc sort data=cs_all_xx;by 序号;run;

data cs_all_xx;
set cs_all_xx;
所有回款数=sum(承诺且还数,未承诺却还数);
所有回款金额=sum(承诺且还金额,未承诺却还金额);
if 序号="" then delete;
run;

/*x  "D:\songts\workteam\登锋\米粒报表\MTD_Collector_Performance.xlsx"; */
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c4:r32c7";
data _null_;set cs_all_xx;file DD;put 累计队列 当天队列 拨打 拨通  ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c21:r32c21";
data _null_;set cs_all_xx;file DD;put 失联;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c11:r32c12";
data _null_;set cs_all_xx;file DD;put 承诺数 承诺金额    ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c14:r32c16";
data _null_;set cs_all_xx;file DD;put 承诺且还数 承诺且还金额  未承诺却还金额    ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c19:r32c20";
data _null_;set cs_all_xx;file DD;put 所有回款数 所有回款金额 ;run;

proc sql;
create table cs_all_d_br as
select a.序号,a.姓名,b.dail_sum as 拨打本人,c.dail_sum as 拨打联系人,d.dail_susum as 拨通本人,e.dail_susum as 拨通联系人 from list as a
left join person_dail_xx_br as b  on a.姓名=b.username
left join person_dail_xx_nobr as c on a.姓名=c.username
left join person_dail_su_xx_br as d  on a.姓名=d.username
left join person_dail_su_xx_nobr as e on a.姓名=e.username;
quit;
proc sort data=cs_all_d_br;by 序号;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r42c4:r62c7";
data _null_;set cs_all_d_br;file DD;put 拨打本人 拨通本人 拨打联系人 拨通联系人;run;

proc sort data=cs_table1_tab1_xx(where=(联系日期=&dt.))    out=dail;by contract_no username  descending 拨打;run;
proc sort data=dail nodupkey;by id ;run;
proc sql;
create table person_dail_xx as
select username,sum(拨打) as dail_sum from dail group by username;quit;

proc sql;
create table person_dail_xx_br as
select username,sum(拨打) as dail_sum from dail(where=(联系人=0)) group by username;quit;

proc sql;
create table person_dail_xx_nobr as
select username,sum(拨打) as dail_sum from dail(where=(联系人=1)) group by username;quit;

*拨通;
proc sql;
create table person_dail_su_xx as
select username,sum(拨通) as dail_susum from dail group by username;quit;

proc sql;
create table person_dail_su_xx_br as
select username,sum(拨通) as dail_susum from dail(where=(联系人=0)) group by username;quit;

proc sql;
create table person_dail_su_xx_nobr as
select username,sum(拨通) as dail_susum from dail(where=(联系人=1)) group by username;quit;

proc sql;
create table cs_all_d as
select a.序号,a.姓名,b.dail_sum,c.dail_susum from list as a
left join person_dail_xx as b  on a.姓名=b.username
left join person_dail_su_xx as c on a.姓名=c.username;
quit;
proc sort data=cs_all_d;by 序号;run;
data cs_all_d;
set cs_all_d;
run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c8:r32c9";
data _null_;set cs_all_d;file DD;put dail_sum dail_susum  ;run;

proc sql;
create table cs_all_d_br as
select a.序号,a.姓名,b.dail_sum as 拨打本人,c.dail_sum as 拨打联系人,d.dail_susum as 拨通本人,e.dail_susum as 拨通联系人 from list as a
left join person_dail_xx_br as b  on a.姓名=b.username
left join person_dail_xx_nobr as c on a.姓名=c.username
left join person_dail_su_xx_br as d  on a.姓名=d.username
left join person_dail_su_xx_nobr as e on a.姓名=e.username;
quit;
proc sort data=cs_all_d_br;by 序号;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r42c8:r62c11";
data _null_;set cs_all_d_br;file DD;put 拨打本人 拨通本人 拨打联系人 拨通联系人;run;

**还款明细;
data mx;
set mtd_pay7;
if username in ("杜盼辉","洪高悬","朱琨","张政嘉","蒋文","吴振杭","邱智超","陈秀芬",'白璐',"陈侃","陈天森",'高宏','袁明明','吴夏姣','易迁英',"胡宸玮","丁洁",'黄晓妮',"龙嘉苑","刘佳","廖翠玲","黄丽华");
keep username contract_no CLEAR_DATE  承诺且还 客户姓名 实收金额;
run;
proc sort data=mx;by username descending 承诺且还;run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]明细!r2c1:r3000c7";
data _null_;set mx;file DD;put username contract_no 客户姓名 CLEAR_DATE 承诺且还 实收金额;run;


data cnhk;
set repayfin.cs_table1_tab_xx_;
if 承诺还款=1;
if 联系日期>=&db.;
keep CREATE_TIME REMARK CONTACTS_NAME userName CONTRACT_NO CUSTOMER_NAME 承诺还款;
rename CREATE_TIME=拨打时间 CONTACTS_NAME=联系人姓名 CUSTOMER_NAME=客户姓名;
run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]承诺还款明细!r2c1:r3000c6";
data _null_;set cnhk;file DD;put CONTRACT_NO 客户姓名 联系人姓名 承诺还款 拨打时间 REMARK;run;

/*承诺还款明细*/
data cnhk;
set repayfin.cs_table1_tab_xx_;
if 承诺还款=1;
if 联系日期>=&db.;
if username in ("杜盼辉","洪高悬","朱琨","张政嘉","蒋文","吴振杭","邱智超","陈秀芬",'白璐',"陈侃","陈天森",'黄晓妮',"龙嘉苑","廖翠玲","黄丽华");
array str CONTACTS_NAME;
do over str;
if str="" then str=".";
end;
keep 联系日期 REMARK CONTACTS_NAME userName CONTRACT_NO CUSTOMER_NAME 承诺还款;
rename CONTACTS_NAME=联系人姓名 CUSTOMER_NAME=客户姓名;
run;
proc sort data=cnhk;by contract_no descending 联系日期;run;
proc sort data=cnhk nodupkey;by contract_no;run;
proc sort data=cnhk;by descending 联系日期;run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]承诺还款明细!r2c1:r3000c7";
data _null_;set cnhk;file DD;put CONTRACT_NO 客户姓名 联系人姓名 承诺还款 username 联系日期 REMARK;run;
