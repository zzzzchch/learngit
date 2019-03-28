option compress = yes validvarname = any;
libname account 'D:\share\Datamart\ԭ��\account';
libname csdata 'D:\share\Datamart\ԭ��\csdata';
libname res  'D:\share\Datamart\ԭ��\res';
libname repayfin "D:\share\Datamart\�м��\repayAnalysis";

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
*ֻ���OUTBOUND��INBOUND�Ŀͻ�����������˵�ɣ���Ȼȷʵ��һ������,����sms��ŵ�����;
/*data repayfin.cs_table1_tab_xx;*/
/*set repayfin.cs_table_ta_xx;*/
/*format ��ϵ���� yymmdd10.;*/
/*��ϵ����=datepart(CREATE_TIME);*/
/*��ϵ�·�=put(��ϵ����,yymmn6.);*/
/*ͨ��ʱ��_��=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);*/
/*if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����","����","�ۻԻ�","��Ⱥ","������","�Ż�",*/
/*			"�ۻԻ�111","��Ⱥ111","������111","�Ż�111",'��ɴ�','�ž�','��ɴ�111','�ž�111','�Ķ���111','�Ķ���');*/
/*if &db.<=��ϵ����<=&dt.;*/
/*if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�ۻԻ�","��Ⱥ","������","�Ż�",*/
/*			"�ۻԻ�111","��Ⱥ111","������111","�Ż�111",'��ɴ�','�ž�','��ï˼','��ɴ�111','�ž�111','��ï˼111') then do;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") then ����=1;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;*/
/*	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","��������")) then ��ϵ��=0;else ��ϵ��=1;*/
/*	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;*/
/*	if username="�ۻԻ�111" then username="�ۻԻ�";*/
/*	if username="��Ⱥ111" then username="��Ⱥ";*/
/*	if username="������111" then username="������";*/
/*	if username="�Ż�111" then username="�Ż�";*/
/*	if username="��ɴ�111" then username="��ɴ�";*/
/*	if username="�ž�111" then username="�ž�";*/
/*	if username="��ï˼111" then username="��ï˼";*/
/*	if username="��Ⱥ" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="��ɴ�" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="��ï˼" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͻ���ʾ") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="�Ż�" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*end;*/
/*else if username in ("�����","����",'�Ķ���111','�Ķ���') then do;*/
/*	if username="�Ķ���111" then username="�Ķ���";*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then ����=1;*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������",'�޷�ת��','���ѻ���') then ��ͨ=1;else ��ͨ=0;*/
/*	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","��������")) then ��ϵ��=0;else ��ϵ��=1;*/
/*	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;*/
/*end;*/
/*run;*/
data repayfin.cs_table1_tab_xx_;
set cs_table_ta_xx;
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ϵ�·�=put(��ϵ����,yymmn6.);
ͨ��ʱ��_��=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);
if &db.<=��ϵ����<=&dt.;
/*ȡ��������µ����к��м�¼*/
if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����","���","��٩","����ɭ","������","����Է","������") then do;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") then ����=1;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","��������")) then ��ϵ��=0;else ��ϵ��=1;
	if CALL_ACTION_ID in ("OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;
/*	if username="��Ⱥ" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="��ɴ�" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="��ï˼" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͻ���ʾ") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
/*	if username="�Ż�" and (kindex(REMARK,"����") or kindex(REMARK,"΢��") or kindex(REMARK,"�ͳ�") or kindex(REMARK,"����") or kindex(REMARK,"�ͻ���")) then ��ϵ��=0;*/
end;
else do;
	if username="�Ķ���111" then username="�Ķ���";
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") then ����=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������",'�޷�ת��','���ѻ���') then ��ͨ=1;else ��ͨ=0;
	if CUSTOMER_NAME=CONTACTS_NAME or (CUSTOMER_NAME="" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","��������")) then ��ϵ��=0;else ��ϵ��=1;
	if CALL_ACTION_ID in ("PRE-OUTBOUND","PRE-SMS","PRE-VIS","OUTBOUND","SMS") and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;
end;
run;
/*data repayfin.cs_table1_tab_xx;;*/
/*set repayfin.cs_table1_tab_xx_;*/
/*/*if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����","���","��٩","����ɭ",'����','�޿�','Ԭ����','�����','��ǨӢ','�����',"�Ž�","�����","��˪","���ﳾ");*/*/
/*/*if username in ("����","���λ�","�δ���","�����","������","����","����","���ǳ�","�����","���","��٩","����ɭ","������","����Է",'����','�޿�','Ԭ����','�����','��ǨӢ','�����');*/*/
/*run;*/

/*��Ϊ�������е�ͨ����¼�����ݴ����Ϊͨ����¼��Ӧ�ģ��Ƿ�ͨ���Ƿ���ϵ�ˡ��Ƿ��ŵ���ͨ��ʱ���ȣ�*/
