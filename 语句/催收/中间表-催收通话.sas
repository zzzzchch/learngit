option compress = yes validvarname = any;
libname account 'D:\share\Datamart\原表\account';
libname csdata 'D:\share\Datamart\原表\csdata';
libname res  'D:\share\Datamart\原表\res';
libname repayfin "D:\share\Datamart\中间表\repayAnalysis";

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
proc sql;
create table repayfin.cs_table1_xx(where=( kindex(contract_no,"C"))) as
select a.id,a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,
       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME
from csdata.Ctl_call_record as a 
left join csdata.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id
left join ca_staff as c on b.emp_id=c.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sql;
create table cs_table_ta_xx as
select a.*,b.itemName_zh as RESULT  from repayfin.cs_table1_xx as a
left join res.optionitem(where=(groupCode="CSJL" or groupCode="YCJG")) as b on a.CALL_RESULT_ID=b.itemCode;
quit;

data _null_;
format dt yymmdd10.;
 dt = today() - 1;
 if month(dt)=month(dt-2) then 
 db=intnx("month",dt,0,"b");
 else if weekday(dt)=1 then
db=intnx("month",dt-2,0,"b");
else db=intnx("month",dt,0,"b");
/*dt=mdy(9,30,2017);*/
/*db=mdy(9,1,2017);*/
 nd = dt-db;
weekf=intnx('week',dt,0);
call symput("nd", nd);
call symput("db",db);
if weekday(dt)=1 then
call symput("dt",dt-2);
else call symput("dt",dt);
call symput("weekf",weekf);
run;
*只针对OUTBOUND、INBOUND的客户，其他的再说吧，虽然确实有一定的量,存在sms承诺还款的;
/*data repayfin.cs_table1_tab_xx;*/
/*set repayfin.cs_table_ta_xx;*/
/*format 联系日期 yymmdd10.;*/
/*联系日期=datepart(CREATE_TIME);*/
/*联系月份=put(联系日期,yymmn6.);*/
/*通话时长_秒=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);*/
/*if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","胡宸玮","丁洁","邵辉辉","邹群","赵婷燕","张慧",*/
/*			"邵辉辉111","邹群111","赵婷燕111","张慧111",'吴成春','杜娟','吴成春111','杜娟111','夏多宜111','夏多宜');*/
/*if &db.<=联系日期<=&dt.;*/
/*if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","邵辉辉","邹群","赵婷燕","张慧",*/
/*			"邵辉辉111","邹群111","赵婷燕111","张慧111",'吴成春','杜娟','徐茂思','吴成春111','杜娟111','徐茂思111') then do;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") then 拨打=1;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;*/
/*	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","无力偿还")) then 联系人=0;else 联系人=1;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;*/
/*	if username="邵辉辉111" then username="邵辉辉";*/
/*	if username="邹群111" then username="邹群";*/
/*	if username="赵婷燕111" then username="赵婷燕";*/
/*	if username="张慧111" then username="张慧";*/
/*	if username="吴成春111" then username="吴成春";*/
/*	if username="杜娟111" then username="杜娟";*/
/*	if username="徐茂思111" then username="徐茂思";*/
/*	if username="邹群" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="吴成春" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="徐茂思" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客户表示") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="张慧" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*end;*/
/*else if username in ("胡宸玮","丁洁",'夏多宜111','夏多宜') then do;*/
/*	if username="夏多宜111" then username="夏多宜";*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then 拨打=1;*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还",'无法转告','提醒还款') then 拨通=1;else 拨通=0;*/
/*	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","无力偿还")) then 联系人=0;else 联系人=1;*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;*/
/*end;*/
/*run;*/
data repayfin.cs_table1_tab_xx_;
set cs_table_ta_xx;
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
联系月份=put(联系日期,yymmn6.);
通话时长_秒=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);
if &db.<=联系日期<=&dt.;
/*取的是这个月的所有呼叫记录*/
if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬","白璐","陈侃","陈天森","黄晓妮","龙嘉苑","黄丽华") then do;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") then 拨打=1;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","无力偿还")) then 联系人=0;else 联系人=1;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;
/*	if username="邹群" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="吴成春" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="徐茂思" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客户表示") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
/*	if username="张慧" and (kindex(REMARK,"本人") or kindex(REMARK,"微信") or kindex(REMARK,"客称") or kindex(REMARK,"短信") or kindex(REMARK,"客户称")) then 联系人=0;*/
end;
else do;
	if username="夏多宜111" then username="夏多宜";
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then 拨打=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还",'无法转告','提醒还款') then 拨通=1;else 拨通=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","无力偿还")) then 联系人=0;else 联系人=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;
end;
run;
/*data repayfin.cs_table1_tab_xx;;*/
/*set repayfin.cs_table1_tab_xx_;*/
/*/*if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬","白璐","陈侃","陈天森",'丁洁','罗俊','袁明明','吴夏姣','易迁英','胡宸玮',"张洁","王佳旎","闫霜","仲秋尘");*/*/
/*/*if username in ("朱琨","杜盼辉","廖翠玲","洪高悬","张政嘉","蒋文","吴振杭","邱智超","陈秀芬","白璐","陈侃","陈天森","黄晓妮","龙嘉苑",'丁洁','罗俊','袁明明','吴夏姣','易迁英','胡宸玮');*/*/
/*run;*/

/*即为该月所有的通话记录，数据处理后，为通话记录对应的（是否拨通、是否联系人、是否承诺还款，通话时长等）*/
