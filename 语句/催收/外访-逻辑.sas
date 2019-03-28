data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
data ctl_apply_visit;
set csdata.ctl_apply_visit;
run;
data ctl_visit_task;
set csdata.ctl_visit_task;
run; 
data ctl_visit;
set csdata.ctl_visit;
run;
data ctl_visit_result;
set csdata.ctl_visit_result;
run;
data bill_main;
set account.bill_main;
if clear_date<=&dbpe. then delete;
run;
proc sort data=bill_main;by contract_no clear_date CURR_PERIOD;run;
proc sort data=bill_main nodupkey;by contract_no clear_date;run;
data ctl_vlist_1;
set ctl_visit;
format ��ÿ�ʼ���� yymmdd10.;
��ÿ�ʼ����=datepart(VISIT_START_TIME);
format ��ý������� yymmdd10.;
��ý�������=datepart(VISIT_END_TIME);
format ��ô������� yymmdd10.;
��ô�������=datepart(CREATE_TIME);
run;

/******���ctl_vlist_1ȥ��hhq********/
proc sort data=ctl_vlist_1;by CONTRACT_NO ��ÿ�ʼ����;run;
data ctl_vlist_1;
set ctl_vlist_1;
by CONTRACT_NO;
if last.CONTRACT_NO;
run;
/*�Ƿ����ͬһ����������¼����ȡ��������ͻ������һ����¼*/

****************************************************************

status	����
-2	�����Ѿ��رգ������ѱ�����
-1	��������Ѿ��ر�
0	δ����
1	ÿ���°���
2	�����е�����
3	���������

****************************************************************;
proc sql;
create table kanr_visit as
select a.*,b.userName,c.contract_no  from ctl_visit_task as a
left join ca_staff as b on a.emp_id=b.id1
left join ctl_apply_visit as c on a.VISIT_ID=c.id;
quit;
data kanr_visit1;
set kanr_visit;
format ��÷������� yymmdd10.;
format Ԥ����ÿ�ʼ���� yymmdd10.;
format Ԥ����ý������� yymmdd10.;
��÷�������=datepart(ASSIGN_TIME);
Ԥ����ÿ�ʼ����=datepart(VISIT_START_TIME);
Ԥ����ý�������=datepart(VISIT_END_TIME);
��÷����·�=put(datepart(VISIT_START_TIME),yymmn6.);
if status=-2 then delete;
if id=18092520121104 then delete;
����=1;
if &db.<=��÷�������<=&dt. or contract_no="C2017042617334370619840";       *  or �Լ���������ݣ�4�³�ɾ��;
if contract_no="C2017042617334370619840" then do ��÷�������=&db.;Ԥ����ÿ�ʼ����=&db.;Ԥ����ý�������=&db.;end;       * 4�³�ɾ��;
run;

/*************�³�ע�͵�������������ȱ����ü�¼�����ֶ����*********/
/*data kanr_visit1_1;*/
/*contract_no='C2017112310472275352163';*/
/*status='3';*/
/*format ��÷������� yymmdd10.;*/
/*format Ԥ����ÿ�ʼ���� yymmdd10.;*/
/*format Ԥ����ý������� yymmdd10.;*/
/*��÷�������=mdy(01,03,2019);*/
/*Ԥ����ÿ�ʼ����=mdy(01,03,2019);*/
/*Ԥ����ý�������=mdy(01,07,2019);*/
/*userName="�����";*/
/*����=1;*/
/*run;*/

/**************�³�ע�͵�********************/

data kanr_visit1;
set kanr_visit1;
pre_��÷�������=intnx('day',��÷�������,-1);*�������ڵ���߻صĲ��ֻᵼ������������ת������ǰһ�������������Ա�;
run;
/*proc sort data=kanr_visit1 nodupkey;by contract_no;run;*/

proc sql;
create table kanr_visit2 as 
select a.*,b.od_days,b.�ͻ�����,b.Ӫҵ��,b.repay_date,c.clear_date,c.OVERDUE_DAYS,d.�������,d.od_days as od_days_yd,e.��ÿ�ʼ����,e.��ô�������,f.od_days as pre_od_days from kanr_visit1 as a
left join repayfin.payment_daily(where=(Ӫҵ��^="APP")) as b on a.contract_no=b.contract_no and b.cut_date=a.��÷�������
left join bill_main as c on a.contract_no=c.contract_no
left join repayfin.payment as d on a.contract_no=d.contract_no and d.cut_date=&dbpe.
left join ctl_vlist_1 as e on a.contract_no=e.contract_no
left join repayfin.payment_daily(where=(Ӫҵ��^="APP")) as f on a.contract_no=f.contract_no and a.pre_��÷�������=f.cut_date;
quit;
data kanr_visit3;
set kanr_visit2;
if Ӫҵ��='�����е�һӪҵ��' and username='�' then username='�1';
if Ԥ����ÿ�ʼ����<=��ô������� then ���=1;else ���=0;
/*if status=3 or (status^=3 and Ԥ����ÿ�ʼ����<=��ÿ�ʼ����<=Ԥ����ý�������) then ���=1;else ���=0;*/
/*if (Ԥ����ÿ�ʼ����<=��ÿ�ʼ����<=Ԥ����ý�������) then ���=1;else ���=0;*/
if Ԥ����ÿ�ʼ����<=clear_date<=Ԥ����ý������� then �߻�=1;else �߻�=0;
if contract_no in ("C2017052315221298717596","C2017062214570771385203") then �߻�=1;      *4�³�ɾ��;
if �߻�=1 then do;�������_�߻�=�������;���=1;end;else do; �������_�߻�=0;clear_date=.;end;
/*if od_days=31 and day(repay_date)=day(��÷�������) then od_days=30;*/
if od_days<=15 then od_days=od_days_yd+day(��÷�������);
/*if pre_od_days-od_days>0 then od_days=pre_od_days;*/
if clear_date=��÷������� then od_days=OVERDUE_DAYS;
if 30>=od_days>15 then �׶�="M1";
	else if 90>=od_days>30 then �׶�="M2";
if contract_no in ("","C2018020617444299528955") then �׶�="M2";
if contract_no in ("C152099880497603000004461","C2017120513471173010169","C152393625759002300010412") and �׶�="M1" then delete;*4�³�ɾ��;
if contract_no in ("","C2017050514565274208654") then delete;*4�³�ɾ��;
if contract_no in ("C2017062717214755572585","C2018042013341266055867","C2017042617334370619840","C2017062214570771385203") then �׶�="M1";   *4�³�ɾ��;
if contract_no in ("C2018030115565478584176","C2017052315221298717596") then �׶�="M2";      *4�³�ɾ��;
keep ID contract_no ��ÿ�ʼ���� Ԥ����ÿ�ʼ���� Ԥ����ý������� ��÷����·� od_days ������� od_days_yd �׶� userName status �߻� clear_date ��÷������� �ͻ����� Ӫҵ�� ��� �������_�߻�;
run;
proc sort data=kanr_visit3;by contract_no descending ��� descending �߻� descending ��÷�������;run;
proc sort data=kanr_visit3 out=kanr_visit4 nodupkey;by contract_no �׶�;run;
proc sql;
create table kanr_visit5 as 
select username,�׶�,count(contract_no) as nums,sum(���) as ���,sum(�������) as �������,sum(�߻�) as �߻�,sum(�������_�߻�) as �������_�߻� from kanr_visit4 group by username,�׶�;
quit;
proc sql;
create table kanr_visit5_ as 
select username,�׶�,sum(�߻�) as �߻�_week,sum(�������_�߻�) as �������_�߻�_week from kanr_visit4 where &weekf.<=clear_date<=&dt. group by username,�׶�;
quit;

proc sql;
create table kanr_visit7 as 
select a.*,b.*,c.* from kanr_visit6 as a
left join kanr_visit5 as b on a.username=b.username 
left join kanr_visit5_ as c on  a.username=c.username and b.�׶�=c.�׶�;
quit;
proc sort data=kanr_visit7;by ���;run;
proc sql;
create table kanr_visit7_1 as 
select a.*,b.* from kanr_visit6 as a
left join kanr_visit7 as b on a.username=b.username and b.�׶�="M1";
quit;
proc sort data=kanr_visit7_1;by ���;run;
proc sql;
create table kanr_visit7_2 as 
select a.*,b.* from kanr_visit6 as a
left join kanr_visit7 as b on a.username=b.username and b.�׶�="M2";
quit;
proc sort data=kanr_visit7_2;by ���;run;
data kanr_visit8_1;
set kanr_visit7_1;
if ���<=8;
run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c3:r10c6";
data _null_;set kanr_visit8_1;file DD;put nums ��� ������� �߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c8:r10c8";
data _null_;set kanr_visit8_1;file DD;put �������_�߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c10:r10c11";
data _null_;set kanr_visit8_1;file DD;put �߻�_week �������_�߻�_week;run;

data kanr_visit8_2;
set kanr_visit7_2;
if ���<=8;
run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c12:r10c15";
data _null_;set kanr_visit8_2;file DD;put nums ��� ������� �߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c17:r10c17";
data _null_;set kanr_visit8_2;file DD;put �������_�߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r3c19:r10c20";
data _null_;set kanr_visit8_2;file DD;put �߻�_week �������_�߻�_week;run;

data kanr_visit8_3;
set kanr_visit7_1;
if ���>=9;
run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c3:r22c6";
data _null_;set kanr_visit8_3;file DD;put nums ��� ������� �߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c8:r22c8";
data _null_;set kanr_visit8_3;file DD;put �������_�߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c10:r22c11";
data _null_;set kanr_visit8_3;file DD;put �߻�_week �������_�߻�_week;run;

data kanr_visit8_4;
set kanr_visit7_2;
if ���>=9;
run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c12:r22c15";
data _null_;set kanr_visit8_4;file DD;put nums ��� ������� �߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c17:r22c17";
data _null_;set kanr_visit8_4;file DD;put �������_�߻�;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]�ؿ�ռ��!r13c19:r22c20";
data _null_;set kanr_visit8_4;file DD;put �߻�_week �������_�߻�_week;run;

data kanr_visit4;
set kanr_visit4;
if �߻�=0 then clear_date=.;
run;
proc sort data=kanr_visit4;by descending �߻� descending ��� descending CLEAR_DATE ��÷�������;run;
filename DD DDE "EXCEL|[��ð������估�߻���.xlsx]��ϸ!r2c1:r500c10";
data _null_;set kanr_visit4;file DD;put contract_no �ͻ����� Ӫҵ�� �׶� ������� username ��÷������� ��� �߻� CLEAR_DATE;run;
