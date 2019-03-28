option compress = yes validvarname = any;
option missing = 0;
libname account odbc datasrc=account_nf;
libname csdata odbc  datasrc=csdata_nf;
libname res odbc  datasrc=res_nf;


data _null_;
format nt yymmdd10.;
 nt = today() ;
call symput("nt",nt);
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
*����ȫ��¼;
/*���԰���¥�Ĵ�����Ա���ݽ������*/
proc sql;
create table cs_table1 as
select a.id,a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,
       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME
from csdata.Ctl_call_record as a 
left join csdata.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id
/*a.TASK_ASSIGN_ID=b.id�ǹ̶��ģ�a���е�TASK_ASSIGN_ID����b�е�id*/
left join ca_staff as c on b.emp_id=c.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sql;
create table cs_table_ta as
select a.*,b.itemName_zh as RESULT from cs_table1 as a
left join res.optionitem(where=(groupCode="CSJL" or groupCode="YCJG")) as b on a.CALL_RESULT_ID=b.itemCode;
quit;

*ֻ���OUTBOUND��INBOUND�Ŀͻ�����������˵�ɣ���Ȼȷʵ��һ������;
data cs_table1_tab;
set cs_table_ta;
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ϵ�·�=put(��ϵ����,yymmn6.);
ͨ��ʱ��_��=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID in ("OUTBOUND","SMS") then ����=1;

if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;

if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;

if username not in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����","���","��٩","����ɭ",'������','������') then do;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then ����=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������",'�޷�ת��','���ѻ���') then ��ͨ=1;else ��ͨ=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","��������")) then ��ϵ��=0;else ��ϵ��=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;
end;
run;
proc sort data=cs_table1_tab;by ��ϵ����;run;
data a;
set cs_table1_tab;
if ��ϵ����=&nt.;
/*if hour(CREATE_TIME)<10;*/
run;
proc import datafile="D:\share\������\MTD\�����������ñ�.xls"
out=list dbms=excel replace;
SHEET="������Ա";
scantext=no;
getnames=yes;
run;
*����;
proc sort data=a   out=dail;by contract_no username  descending ����;run;
proc sql;
create table person_dail as
select username,sum(����) as dail_sum from dail group by username;quit;

*��ͨ;*��������;
proc sort data=a   out=dail;by contract_no username  descending ��ͨ;run;
proc sql;
create table person_dail_su as
select username,sum(��ͨ) as dail_susum from dail group by username;quit;

proc sql;
create table cs_all_d as
select a.���,a.����,b.dail_sum,c.dail_susum from list as a
left join person_dail as b  on a.����=b.username
left join person_dail_su as c on a.����=c.username;
quit;
proc sort data=cs_all_d;by ���;run;
/*DDE;*/
x  "D:\share\���յ���ͨ��\mili_collection.xlsx"; 
data tt;
 format y hhmm.;
 y=time();
run;
filename DD DDE 'EXCEL|[mili_collection.xlsx]collect_r!r1c6:r1c6';
data _null_;set tt;file DD;put y  ;run;
filename DD DDE 'EXCEL|[mili_collection.xlsx]collect_r!r5c5:r200c6';
data _null_;
set cs_all_d;
file DD;
put dail_sum dail_susum;
run;


data aaa;
set a;
if userName in("���λ�");
run;

PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="���λ�"; RUN;

data aaa;
set a;
if userName in("�����");
run;

PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="�����"; RUN;

data aaa;
set a;
if userName in("������");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="������"; RUN;

data aaa;
set a;
if userName in("����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="����"; RUN;

data aaa;
set a;
if userName in("����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="����"; RUN;

data aaa;
set a;
if userName in("���ǳ�");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="���ǳ�"; RUN;

data aaa;
set a;
if userName in("�����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="�����"; RUN;

data aaa;
set a;
if userName in("���");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="���"; RUN;

data aaa;
set a;
if userName in("��٩");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="��٩"; RUN;

data aaa;
set a;
if userName in("����ɭ");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="����ɭ"; RUN;

data aaa;
set a;
if userName in("������");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="������"; RUN;

data aaa;
set a;
if userName in("����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="����"; RUN;

data aaa;
set a;
if userName in("�����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="�����"; RUN;

data aaa;
set a;
if userName in("��ǨӢ");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="��ǨӢ"; RUN;

data aaa;
set a;
if userName in("Ԭ����");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="Ԭ����"; RUN;

data aaa;
set a;
if userName in("�ߺ�");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="�ߺ�"; RUN;

data aaa;
set a;
if userName in("������");
run;
PROC EXPORT DATA=aaa
OUTFILE= "D:\share\���յ���ͨ��\������ϸ.xls" DBMS=EXCEL REPLACE;SHEET="������"; RUN;

