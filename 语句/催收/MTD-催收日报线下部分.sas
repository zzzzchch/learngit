/*��Ҫ�����м��cs_table1_tab_xx_;*/
data repay_plan_qk;
set account.repay_plan;
if CURR_PERIOD=1;
�ڿ�=CURR_RECEIVE_CAPITAL_AMT+CURR_RECEIVE_INTEREST_AMT;
run;
proc sort data=repay_plan_qk nodupkey;by contract_no;run;
data payment_daily;
set repayfin.payment_daily;
if Ӫҵ��^="APP";
if kindex(contract_no,"C");
run;
proc sort data=payment_daily;by contract_no cut_date;run;
data payment_daily_;
set payment_daily;
by contract_no;
lag_od_days=lag(od_days);
keep contract_no clear_date od_days cut_date lag_od_days Ӫҵ�� �ͻ�����;
run;
*���ڵ���绰���컹��ⲿ�ֿͻ���Ƿ���=0����cs_table1_tab2����lag_Ƿ���滻;
proc sql;
create table cs_table1_tab1_xx as
select a.*,b.lag_od_days,b.od_days,b.Ӫҵ��,c.�ڿ� from repayfin.cs_table1_tab_xx_ as a
left join payment_daily_ as b on a.contract_no=b.contract_no and a.��ϵ����=b.cut_date
left join repay_plan_qk as c on a.contract_no=c.contract_no;
quit;
data cs_table1_tab2_xx;
set cs_table1_tab1_xx;
if lag_od_days=od_days-1 then do;
	if od_days>=90 then Ƿ��=�ڿ�*4;
	else if 90>od_days>=60 then Ƿ��=�ڿ�*3;
	else if 60>od_days>=30 then Ƿ��=�ڿ�*2;
	else Ƿ��=�ڿ�;
end;
else do;
	if lag_od_days+1>=90 then Ƿ��=�ڿ�*4;
	else if 90>lag_od_days+1>=60 then Ƿ��=�ڿ�*3;
	else if 60>lag_od_days+1>=30 then Ƿ��=�ڿ�*2;
	else Ƿ��=�ڿ�;
end;
*ɾ����ܰ���Ѻ���;
/*if Ӫҵ�� in ("�Ͼ��е�һӪҵ��","�����е�һӪҵ��","�Ͼ���ҵ������","������ҵ������","��ͨ��ҵ������","�����е�һӪҵ��","������ҵ������") and RESULT='' then delete;*/
if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����",'���',"��٩","����ɭ",'������',"����Է","������") and kindex(CALL_ACTION_ID,"PRE")>0 then delete;
run;
*������lag_odays������8-60������䣬���ǵ�����ͬ�µĹ���Ч������ʱȡ���߼����䣬������ʾ8-60��;
/*proc sql;*/
/*create table cs_table1_tab1 as*/
/*select a.*,b.lag_odays from cs_table1_tab as a*/
/*left join payment_day_last as b on a.contract_no=b.contract_no and a.��ϵ����=b.cut_date;*/
/*quit;*/
*����;
proc sort data=cs_table1_tab2_xx   out=mtd_dail_xx;by contract_no username  descending ����;run;
proc sort data=mtd_dail_xx nodupkey;by id;run;
/*proc sort data=mtd_dail nodupkey;by contract_no username ;run;*/
proc sql;
create table person_dail_xx as
select username,sum(����) as dail_sum from mtd_dail_xx group by username;quit;

proc sql;
create table person_dail_xx_br as
select username,sum(����) as dail_sum from mtd_dail_xx(where=(��ϵ��=0)) group by username;quit;

proc sql;
create table person_dail_xx_nobr as
select username,sum(����) as dail_sum from mtd_dail_xx(where=(��ϵ��=1)) group by username;quit;

*��ͨ;
/*proc sort data=mtd_dail nodupkey;by contract_no username ;run;*/
proc sql;
create table person_dail_su_xx as
select username,sum(��ͨ) as dail_susum from mtd_dail_xx group by username;quit;

proc sql;
create table person_dail_su_xx_br as
select username,sum(��ͨ) as dail_susum from mtd_dail_xx(where=(��ϵ��=0)) group by username;quit;

proc sql;
create table person_dail_su_xx_nobr as
select username,sum(��ͨ) as dail_susum from mtd_dail_xx(where=(��ϵ��=1)) group by username;quit;

*��ŵ����;
proc sql;
create table person_dail_ptp_xx as
select username,sum(��ŵ����) as dail_ptp from mtd_dail_xx group by username;quit;
proc sql;
create table person_dail_ptps_xx as
select username,sum(Ƿ��) as dail_ptps from mtd_dail_xx(where=(��ŵ����=1)) group by username;quit;

proc sort data=mtd_dail_xx;by contract_no ��ϵ���� username descending ��ŵ����;run;
proc sort data=mtd_dail_xx out=mtd_dail_xx_;by contract_no ��ϵ���� username descending ��ŵ����;run;

*ÿ�챣��һ�������¼ƴ��payment��ͨ��retain��������ͳ�ŵ�����clear_date��ֵʱ�ͱ�ʾ�߻�;
proc sql;
create table mtd_pay4_0 as
select a.*,b.��ŵ����,b.username,b.����,b.Ƿ��
from payment_daily_(where=(cut_date^=&db.-1)) as a
left join mtd_dail_xx_ as b on a.contract_no=b.contract_no and a.cut_date=b.��ϵ����;
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
retain �߻ز��� �߻س�ŵ;
if first.contract_no then do;�߻ز���=����;�߻س�ŵ=��ŵ����;end;
else do;�߻ز���=max(�߻ز���,����);�߻س�ŵ=max(�߻س�ŵ,��ŵ����);end;
run;
*���һ���������˲���ʱ���˴�ֻ�ᱣ��һ���˵ļ�¼����ʱ�����������;
data mtd_pay4_3;
set mtd_pay4_2;
by contract_no;
retain ��ϯ;
if first.contract_no then do;��ϯ=username;end;
else if username^='' then ��ϯ=username;
else ��ϯ=��ϯ;
drop username;
run;
data mtd_pay4;
set mtd_pay4_3;
if �߻ز���=1 and �߻س�ŵ=0 and clear_date=cut_date then �ǳ�ŵ�һ�=1;else �ǳ�ŵ�һ�=0;
if �߻ز���=1 and �߻س�ŵ=1 and clear_date=cut_date then ��ŵ�һ�=1;else ��ŵ�һ�=0;
if contract_no='' and cut_date=mdy(10,8,2018) then do;��ŵ�һ�=1;clear_date=cut_date;end;
rename ��ϯ=username;
run;
proc sort data=mtd_pay4;by contract_no cut_date;run;
proc sort data=mtd_pay4 nodupkey;by contract_no cut_date;run;
********************************************** ������ start****************************************************************;
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
select contract_no,PERIOD,sum(BREAKS_AMOUNT) as ��Ϣ���� from fee_breaks_apply_dtl_ group by contract_no,PERIOD;
quit;
proc sql;
create table bill_main_m2 as 
select a.contract_no,a.CURR_PERIOD,a.clear_date,a.CURR_RECEIVE_AMT as �ܽ��,b.��Ϣ���� from bill_main_m as a
left join fee_breaks_jm_1 as b on a.contract_no=b.contract_no and a.CURR_PERIOD=b.PERIOD;
quit;
data bill_main_m3;
set bill_main_m2;
array num _numeric_;
Do Over num;
If num="." Then num=0;
End;
ʵ�ս��=�ܽ��-��Ϣ����;
run;
proc sql;
create table bill_main_m4 as 
select contract_no,clear_date,sum(ʵ�ս��) as ʵ�ս�� from bill_main_m3 group by contract_no,clear_date;
quit;
proc sort data=bill_main_m4;by contract_no clear_date;run;
proc rank data=bill_main_m4 out=bill_main_m4_;var clear_date;ranks rank_;by contract_no;run;

data mtd_pay5;
set mtd_pay4;
if ��ŵ�һ�=1 or �ǳ�ŵ�һ�=1;
run;
proc sort data=mtd_pay5;by contract_no clear_date;run;
proc rank data=mtd_pay5 out=mtd_pay5_;var clear_date;ranks rank_;by contract_no;run;
proc sql;
create table mtd_pay6 as 
select a.*,b.ʵ�ս�� as ʵ�ս��a,c.�ڿ�,d.ʵ�ս�� from mtd_pay5_ as a
left join bill_main_m4 as b on a.contract_no=b.contract_no and a.clear_date=b.clear_date
left join repay_plan_qk as c on a.contract_no=c.contract_no
left join bill_main_m4_ as d on a.contract_no=d.contract_no and a.rank_=d.rank_;
quit;
data mtd_pay7;
set mtd_pay6;
if ʵ�ս��a>1 then ʵ�ս��=ʵ�ս��a;
if od_days=0 and lag_od_days=0 then ʵ�ս��=�ڿ�;
if ʵ�ս�� in (0,.) then ʵ�ս��=�ڿ�;
drop rank_ Ƿ�� ʵ�ս��a; 
run;
proc sort data=mtd_pay7;by contract_no cut_date;run;
proc sort data=mtd_pay7 nodupkey;by contract_no cut_date;run;
**************************************************************************************************************;
**����;
proc sql;
create table mtd_pay_ptpn_xx as
select username,sum(��ŵ�һ�) as ptpn from mtd_pay7 group by username
;
quit;
**���;
proc sql;
create table mtd_pay_ptps_xx as
select username,sum(ʵ�ս��) as ptps from mtd_pay7(where=(��ŵ�һ�=1)) group by username;
quit;
*֮ǰ�������ŵ����Ϊ1��0,���������ŵ����Ϊ0���ж���������Ч���ģ����ֻ�����ŵ����Ϊ1,�ǳ���1����ȫ����.;
*δ��ŵ����ȴ����;
**���;
proc sql;
create table mtd_pay_nptps_xx as
select username,sum(ʵ�ս��) as nptps from mtd_pay7(where=(�ǳ�ŵ�һ�=1)) group by username;
quit;
**����;
proc sql;
create table mtd_pay_nptpc_xx as
select username,sum(�ǳ�ŵ�һ�) as nptpc from mtd_pay7 group by username;
quit;

data test_lr_e_D;
set repayfin.test_lr_b;
if �����������=1 then do;��������=�����������; �������=0;end;
if kindex(contract_no,"C");
/*if repay_date=cut_date then ��ʧ�ʷ�ĸ=1;else ��ʧ�ʷ�ĸ=0;*/
if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����",'���',"��٩","����ɭ",'�ߺ�','Ԭ����','�����','��ǨӢ',"�����","����",'������',"����Է","����","������");
drop �����������;
run;
*ͨ�����һ�η�����ϯ��ȷ��������еļ��ǲ���û������ϯ���У��Ѿ��������ν�ΰ;
data kanr_c;
set repayfin.kanr;
if ��������<=&dt.;
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
*����֮���������ڵ�31��ʱ���������=0����Ϊϵͳ��׼ʱ�Ľ���������ΰ����;
*�������ݸ����µ����ڵ���;
data test_lr_e_D2;
set test_lr_e_D1;
if username in ("���λ�","�����") then do;
	if cut_date=&db. and 30<=od_daysx_db<=61 and �������=1 then �ۼƶ���=1;
		else if &db.<=cut_date<=&dt. and ��������=1 then �ۼƶ���=1;
		else �ۼƶ���=0;
	if cut_date=&dt. and 31<=od_daysx<=60+day(&dt.) and username=username_c then ����������=1;else ����������=0;
end;
else if username in ("����","������","����","����","���ǳ�","�����",'���',"��٩","����ɭ",'������',"����Է","�δ���","������") then do;
	if cut_date=&db. and 16<=od_daysx_db<=31 and �������=1 then �ۼƶ���=1;
		else if &db.<=cut_date<=&dt. and ��������=1 then �ۼƶ���=1;
		else �ۼƶ���=0;
	if cut_date=&dt. and 16<=od_daysx<=30+day(&dt.) and username=username_c then ����������=1;else ����������=0;
end;
else if username in ("�����",'�Ķ���','�ߺ�','�����','��ǨӢ',"����",'Ԭ����',"����") then do;
	if cut_date=&db. and �������=1 then �ۼƶ���=1;
		else if &db.<=cut_date<=&dt. and ��������=1 then �ۼƶ���=1;
		else �ۼƶ���=0;
	if cut_date=&dt. and �������=1 and username=username_c then ����������=1;else ����������=0;
end;
if �ۼƶ���=1 and CUSTOMER_STATUS='ʧ��' then ʧ��=1;else ʧ��=0;
run;
proc sql;
create table dt_xx as
select username,sum(����������) as ������� from test_lr_e_D2 group by username;
quit;
/*proc sort data=test_lr_e_D2 ;by contract_no username descending �ۼƶ���;run;*/
/*proc sort data=test_lr_e_D2 nodupkey;by contract_no username;run;*/
proc sql;
create table ljdl_xx as
select username,sum(�ۼƶ���) as �ۼƶ���,sum(ʧ��) as ʧ�� from test_lr_e_D2 group by username;
quit;

proc sql;
create table cs_all_xx as
select a.���,a.����,b.�������,c.dail_sum as ����,d.dail_susum as ��ͨ,e.dail_ptp as ��ŵ��,
f.dail_ptps as ��ŵ���,g.ptpn as ��ŵ�һ���,h.ptps as ��ŵ�һ����,i.nptps as δ��ŵȴ�����,j.nptpc as δ��ŵȴ����,k.�ۼƶ���,k.ʧ��
from list as a
left join dt_xx as b on a.����=b.userName
left join person_dail_xx as c on a.����=c.userName
left join person_dail_su_xx as d on a.����=d.userName
left join person_dail_ptp_xx as e on a.����=e.userName
left join person_dail_ptps_xx as f on a.����=f.username
left join mtd_pay_ptpn_xx as g on a.����=g.username
left join mtd_pay_ptps_xx as h on a.����=h.username
left join mtd_pay_nptps_xx as i on a.����=i.username
left join mtd_pay_nptpc_xx as j on a.����=j.username
left join ljdl_xx as k on a.����=k.username;
quit;
proc sort data=cs_all_xx;by ���;run;

data cs_all_xx;
set cs_all_xx;
���лؿ���=sum(��ŵ�һ���,δ��ŵȴ����);
���лؿ���=sum(��ŵ�һ����,δ��ŵȴ�����);
if ���="" then delete;
run;

/*x  "D:\songts\workteam\�Ƿ�\��������\MTD_Collector_Performance.xlsx"; */
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c4:r32c7";
data _null_;set cs_all_xx;file DD;put �ۼƶ��� ������� ���� ��ͨ  ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c21:r32c21";
data _null_;set cs_all_xx;file DD;put ʧ��;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c11:r32c12";
data _null_;set cs_all_xx;file DD;put ��ŵ�� ��ŵ���    ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c14:r32c16";
data _null_;set cs_all_xx;file DD;put ��ŵ�һ��� ��ŵ�һ����  δ��ŵȴ�����    ;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c19:r32c20";
data _null_;set cs_all_xx;file DD;put ���лؿ��� ���лؿ��� ;run;

proc sql;
create table cs_all_d_br as
select a.���,a.����,b.dail_sum as ������,c.dail_sum as ������ϵ��,d.dail_susum as ��ͨ����,e.dail_susum as ��ͨ��ϵ�� from list as a
left join person_dail_xx_br as b  on a.����=b.username
left join person_dail_xx_nobr as c on a.����=c.username
left join person_dail_su_xx_br as d  on a.����=d.username
left join person_dail_su_xx_nobr as e on a.����=e.username;
quit;
proc sort data=cs_all_d_br;by ���;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r42c4:r62c7";
data _null_;set cs_all_d_br;file DD;put ������ ��ͨ���� ������ϵ�� ��ͨ��ϵ��;run;

proc sort data=cs_table1_tab1_xx(where=(��ϵ����=&dt.))    out=dail;by contract_no username  descending ����;run;
proc sort data=dail nodupkey;by id ;run;
proc sql;
create table person_dail_xx as
select username,sum(����) as dail_sum from dail group by username;quit;

proc sql;
create table person_dail_xx_br as
select username,sum(����) as dail_sum from dail(where=(��ϵ��=0)) group by username;quit;

proc sql;
create table person_dail_xx_nobr as
select username,sum(����) as dail_sum from dail(where=(��ϵ��=1)) group by username;quit;

*��ͨ;
proc sql;
create table person_dail_su_xx as
select username,sum(��ͨ) as dail_susum from dail group by username;quit;

proc sql;
create table person_dail_su_xx_br as
select username,sum(��ͨ) as dail_susum from dail(where=(��ϵ��=0)) group by username;quit;

proc sql;
create table person_dail_su_xx_nobr as
select username,sum(��ͨ) as dail_susum from dail(where=(��ϵ��=1)) group by username;quit;

proc sql;
create table cs_all_d as
select a.���,a.����,b.dail_sum,c.dail_susum from list as a
left join person_dail_xx as b  on a.����=b.username
left join person_dail_su_xx as c on a.����=c.username;
quit;
proc sort data=cs_all_d;by ���;run;
data cs_all_d;
set cs_all_d;
run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r12c8:r32c9";
data _null_;set cs_all_d;file DD;put dail_sum dail_susum  ;run;

proc sql;
create table cs_all_d_br as
select a.���,a.����,b.dail_sum as ������,c.dail_sum as ������ϵ��,d.dail_susum as ��ͨ����,e.dail_susum as ��ͨ��ϵ�� from list as a
left join person_dail_xx_br as b  on a.����=b.username
left join person_dail_xx_nobr as c on a.����=c.username
left join person_dail_su_xx_br as d  on a.����=d.username
left join person_dail_su_xx_nobr as e on a.����=e.username;
quit;
proc sort data=cs_all_d_br;by ���;run;

filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]Sheet1!r42c8:r62c11";
data _null_;set cs_all_d_br;file DD;put ������ ��ͨ���� ������ϵ�� ��ͨ��ϵ��;run;

**������ϸ;
data mx;
set mtd_pay7;
if username in ("���λ�","�����","����","������","����","����","���ǳ�","�����",'���',"��٩","����ɭ",'�ߺ�','Ԭ����','�����','��ǨӢ',"�����","����",'������',"����Է","����","�δ���","������");
keep username contract_no CLEAR_DATE  ��ŵ�һ� �ͻ����� ʵ�ս��;
run;
proc sort data=mx;by username descending ��ŵ�һ�;run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]��ϸ!r2c1:r3000c7";
data _null_;set mx;file DD;put username contract_no �ͻ����� CLEAR_DATE ��ŵ�һ� ʵ�ս��;run;


data cnhk;
set repayfin.cs_table1_tab_xx_;
if ��ŵ����=1;
if ��ϵ����>=&db.;
keep CREATE_TIME REMARK CONTACTS_NAME userName CONTRACT_NO CUSTOMER_NAME ��ŵ����;
rename CREATE_TIME=����ʱ�� CONTACTS_NAME=��ϵ������ CUSTOMER_NAME=�ͻ�����;
run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]��ŵ������ϸ!r2c1:r3000c6";
data _null_;set cnhk;file DD;put CONTRACT_NO �ͻ����� ��ϵ������ ��ŵ���� ����ʱ�� REMARK;run;

/*��ŵ������ϸ*/
data cnhk;
set repayfin.cs_table1_tab_xx_;
if ��ŵ����=1;
if ��ϵ����>=&db.;
if username in ("���λ�","�����","����","������","����","����","���ǳ�","�����",'���',"��٩","����ɭ",'������',"����Է","�δ���","������");
array str CONTACTS_NAME;
do over str;
if str="" then str=".";
end;
keep ��ϵ���� REMARK CONTACTS_NAME userName CONTRACT_NO CUSTOMER_NAME ��ŵ����;
rename CONTACTS_NAME=��ϵ������ CUSTOMER_NAME=�ͻ�����;
run;
proc sort data=cnhk;by contract_no descending ��ϵ����;run;
proc sort data=cnhk nodupkey;by contract_no;run;
proc sort data=cnhk;by descending ��ϵ����;run;
filename DD DDE "EXCEL|[MTD_Collector_Performance.xlsx]��ŵ������ϸ!r2c1:r3000c7";
data _null_;set cnhk;file DD;put CONTRACT_NO �ͻ����� ��ϵ������ ��ŵ���� username ��ϵ���� REMARK;run;
