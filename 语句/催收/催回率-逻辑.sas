************
1-16�ŷ���Ŀͻ����Ǹ������µ����һ���ֹ��17-30�ŷ���Ŀͻ���C-M1�Ŀͻ���,��ʱ��17��֮������C-M1�Ŀͻ����¸��¾ͱ����M1-M2��
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

/*reason������Ƽ��ʾ������ͻ���ʱ����������������Э��������ʵ��Ϊ����ҵĿͻ����ͻ�������⡣*/
if contract_no="C152239781313802300006770" and username="����" then username="�����";
/*deal���ֹ�������4�³�ɾ����������*/

if username in ("���λ�","�����","������","�δ���","������","����","���ǳ�",'���','��٩','����ɭ','�����','������');
if &db.<=cut_date<=&db2.;
run;

data payment_daily;
set repayfin.payment_daily(where=(Ӫҵ��^="APP"));
by contract_no cut_date;
run;
proc sql;
create table mmlist_1 as 
select a.*, b.�ͻ�����, b.Ӫҵ��, b.�ʽ�����,e.�������  from mmlist as a
left join payment_daily as b on a.contract_no=b.contract_no and a.cut_date=b.cut_date
left join repayfin.payment as e on a.contract_no=e.contract_no and e.cut_date=&dbpe.;
quit;



data mmlist_2;
set mmlist_1;
if �ʽ����� in ("xyd1","xyd2") then �ʽ�����="С���";
	else if �ʽ����� in ("bhxt1","bhxt2") then �ʽ�����="��������";
	else if �ʽ����� in ("mindai1") then �ʽ�����="���";
	else if �ʽ����� in ("ynxt1","ynxt2","ynxt3") then �ʽ�����="��������";
	else if �ʽ����� in ("jrgc1") then �ʽ�����="���ڹ���";
	else if �ʽ����� in ("irongbei1") then �ʽ�����="�ڱ�";
	else if �ʽ����� in ("fotic3","fotic2") then �ʽ�����="��һ������";
	else if �ʽ����� in ("haxt1") then �ʽ�����="��������";
	else if �ʽ����� in ("p2p") then �ʽ�����="�пƲƸ�";
	else if �ʽ����� in ("jsxj1") then �ʽ�����="�������ѽ���";
	else if �ʽ����� in ("lanjingjr1") then �ʽ�����="��������";
	else if �ʽ����� in ("yjh1","yjh2") then �ʽ�����="��ݼ��";
	else if �ʽ����� in ("rx1") then �ʽ�����="����";
	else if �ʽ����� in ("hapx1") then �ʽ�����="��������";
	else if �ʽ����� in ("tsjr1") then �ʽ�����="ͨ�ƽ���";
run;
proc sort data=mmlist_2;by contract_no cut_date;run;

data mmlist_3;
set mmlist_2;
by contract_no;
if username not in ('���λ�','�����') and segment_name^="M1-M2" then delete;
if username in ('���λ�','�����') and segment_name^="M2-M3" then delete;
run;
proc sort data=mmlist_3;by contract_no descending cut_date;run;
proc sort data=mmlist_3 out=mmlist_3 nodupkey;by contract_no issues segment_name;run;


proc sql;
create table mmlist_3_2 as 
select a.*,b.����Ա from mmlist_3 as a
left join mmlist_3_1_a as b on a.contract_no=b.��ͬ;
/*left join mmlist_3_1_a as c on a.contract_no=c.��ͬ;*/
quit;


data mmlist_3;
set mmlist_3_2;
if segment_name="M2-M3" and ����Ա="" then delete;
/*if �׶�="M1-M2" and ����Ա^="" then userName=����Ա;*/
run;

************************************************** ���� ********************************************************************;
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
select contract_no,PERIOD,sum(BREAKS_AMOUNT) as ��Ϣ���� from fee_breaks_apply_dtl_ group by contract_no,PERIOD;
quit;
proc sql;
create table fee_breaks_jm_1_b as 
select a.*,b.clear_date from fee_breaks_jm_1_a as a 
left join account.bill_main(where=(substr(bill_code,1,3)="BLC")) as b on a.contract_no=b.contract_no and a.period=b.CURR_PERIOD;
quit;
proc sql;
create table fee_breaks_jm_1 as 
select contract_no,sum(��Ϣ����) as ��Ϣ���� 
from fee_breaks_jm_1_b 
where &dbpe.<=clear_date<=&dt.
group by contract_no;
quit;
************************************************** ���� ********************************************************************;
*���ڴ��ڲ�ͬʱ��߻�����������������㵱��ʵ�ʴ߻ؽ��;

************���³�ɾ��*************;
data account.bill_main;
set account.bill_main;
if ID=297880 THEN clear_date=mdy(02,28,2019);
run;
************���³�ɾ��*************;

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
where &dbpe.<=clear_date<=&dt. and userName in ("���λ�","�����","������","������","�δ���","����","���ǳ�",'���','��٩','����ɭ','�����','������',"����Է")
group by contract_no;
quit;


proc sql;
create table mmlist_4 as 
select a.*,d.CURR_RECEIVE_AMT as ʵ�ʽ��,c.��Ϣ���� from mmlist_3 as a
left join bill_main_b as d on a.contract_no=d.contract_no 
left join fee_breaks_jm_1 as c on a.contract_no=c.contract_no;
quit;
proc sort data=mmlist_4;by contract_no descending issues descending ASSIGN_TIME;run;
proc sort data=mmlist_4 nodupkey;by contract_no descending issues;run;
data mmlist_5;
set mmlist_4;
if ��Ϣ����=. then ��Ϣ����=0;
ʵ�ʽ��=ʵ�ʽ��-��Ϣ����;
/*if od_days-lag_od_days^=1 and lag_od_days>30 then clear_date=cut_date;*/
if datepart(settlement_date)>&dt. or datepart(settlement_date)<&db. then do;ʵ�ʽ��=0;settlement_date=.;end;
if settlement_date=. then ʵ�ʽ��=.;
run;
proc sort data=mmlist_5;by contract_no username;run;
proc sort data=mmlist_5 nodupkey;by contract_no username;run;
proc sort data=mmlist_5;by descending settlement_date segment_name username;run;

data mmlist_7;
set mmlist_5;
format repy_date yymmdd10.;
repy_date=datepart(settlement_date);

/*�ÿͻ�Ϊȡ����ǰ����ͻ�������payment���еĴ������Ϊ����*/
if contract_no ="C2016092315304619856732" then �������=5675.468; 

if settlement_date not in (0,.) then �߻����=�������;
    else �߻����=0;
if �����=1 and settlement_date>1 then �߻�������=�������/2;
	else if �����=0 and settlement_date>1 then �߻�������=�������;
	else �߻�������=0;
if �����=1 and ʵ�ʽ��>1 then ʵ�ʽ�����=ʵ�ʽ��/2;
	else if �����=0 and ʵ�ʽ��>1 then ʵ�ʽ�����=ʵ�ʽ��;
if ʵ�ʽ��=. then ʵ�ʽ��=0;
run;

proc sort data=mmlist_7;by descending repy_date segment_name username;run;
proc sql;
create table mmlist_8_1 as 
select username,sum(�������) as �������,sum(�߻����) as �߻����,sum(�߻�������) as �߻�������,sum(ʵ�ʽ��) as ʵ�ʽ��,sum(ʵ�ʽ�����) as ʵ�ʽ����� from mmlist_7 
where segment_name in ('M1-M2','M2-M3')
group by username;
quit;
proc sql;
create table mmlist_8_2 as 
select username,sum(�߻����) as �߻����day,count(�߻����) as �߻�����day from mmlist_7 where repy_date=&dt. and segment_name in ('M1-M2','M2-M3') group by username;
quit;
data _null_;
format dt yymmdd10.; 
dt = today() - 1;
call symput("dt", dt);
run;
proc sql;
create table mmlist_8_4 as 
select username,sum(�߻����) as �߻����week,sum(�߻�������) as �߻�������week from mmlist_7 where &weekf.<=repy_date<=&dt. and segment_name in ('M1-M2','M2-M3') group by username;
quit;

proc sql;
create table mmlist_9 as 
select a.*,b.*,c.*,d.* from mmlist_8_3 as a
left join mmlist_8_2 as b on a.username=b.username
left join mmlist_8_1 as c on a.username=c.username
left join mmlist_8_4 as d on a.username=d.username;
quit;
proc sort data=mmlist_9;by ���;run;
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
filename DD DDE "EXCEL|[�߻��ʼ�ʵ��ͳ��.xlsx]report!r3c5:r14c8";
data _null_;set mmlist_10;file DD;put �߻����day �߻�����day ������� �߻����;run;
filename DD DDE "EXCEL|[�߻��ʼ�ʵ��ͳ��.xlsx]report!r3c10:r14c10";
data _null_;set mmlist_10;file DD;put �߻�������;run;
filename DD DDE "EXCEL|[�߻��ʼ�ʵ��ͳ��.xlsx]report!r3c12:r14c14";
data _null_;set mmlist_10;file DD;put ʵ�ʽ�� ʵ�ʽ����� �߻����week;run;
filename DD DDE "EXCEL|[�߻��ʼ�ʵ��ͳ��.xlsx]report!r3c16:r14c16";
data _null_;set mmlist_10;file DD;put �߻�������week;run;

data aa;
set mmlist_7;
format settlement_date yymmdd10.;
keep contract_no segment_name �ͻ����� Ӫҵ�� �ʽ����� ������� username ����� ʵ�ʽ�� repy_date;
run;
filename DD DDE "EXCEL|[�߻��ʼ�ʵ��ͳ��.xlsx]��ϸ!r2c1:r2000c10";
data _null_;set aa;file DD;put contract_no segment_name �ͻ����� Ӫҵ�� �ʽ����� ������� username ����� ʵ�ʽ�� repy_date;run;
