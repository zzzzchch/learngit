option compress=yes validvarname=any;

libname credit odbc datasrc = credit_nf;
libname dta "D:\share\Datamart\�м��\daily";


/*data tme;*/
/*format t ld yymmdd10.;*/
/*t =today();*/


data credit_zx_detail;
set credit.credit_zx_detail;
if SUB_BIZ_TYPE="�޵�Ѻ����" then �޵�Ѻ���� =1;
run;

proc freq data = credit_zx_detail;
table ACCT_STATUS;
run;

proc sql;
create table zx_detail as select apply_code ,count(�޵�Ѻ����) as �����޵�Ѻ������,count(*) as ���Ŵ����� from credit_zx_detail(where=(ACCT_STATUS^="����")) group by apply_code;quit;

data customer_info ;
set dta.customer_info;
run;

/*data dianhuab;*/
/*set customer_info;*/
/*if third_refuse_code="R754";*/
/*run;*/


proc sql ;
create table all_info as select a.*,b.�����޵�Ѻ������,b.���Ŵ����� from customer_info as a left join zx_detail as b on a.apply_code = b.apply_code;
quit;





data all_info1;
set all_info(where=(����ʱ��>intnx("month",today(),-1,"b")));
�����·�=substr(compress(put(����ʱ��,yymmdd10.),"-"),1,6);
input_week =week(����ʱ��);

if weekday(today())>=2 then input_week_ds = week(today())-1;
else input_week_ds = week(today());
if input_week=input_week_ds;
/*if input_week = 51;*/

/*2018����dde ���λ��*/
/*call symput ("i",compress(put(week(today())-36,12.)));*/
/*call symput ("i",compress(put(52-36,12.)));*/
/*2019����dde ���λ��*/
if weekday(today())>=2 then call symput ("i",compress(put(week(today())+16,12.)));
else call symput ("i",compress(put(week(today())+17,12.)));



if approve_��Ʒ="" 
then do;
	if DESIRED_PRODUCT="Elite" then approve_��Ʒ="U��ͨ";

end;

if kindex(approve_��Ʒ,"E΢��") then approve_��Ʒ ="E΢��";
if kindex(approve_��Ʒ,"E��ͨ") then approve_��Ʒ ="E��ͨ";
if kindex(approve_��Ʒ,"Eլͨ") then approve_��Ʒ ="Eլͨ";

if  ��ر�ǩ="���"  then  nonlocal=0;
else if ��ر�ǩ="����"  then  nonlocal=1;

if IS_HAS_HOURSE="y" then IS_HAS_HOURSE1=1;
else if IS_HAS_HOURSE="n" then IS_HAS_HOURSE1=0;

if ͨ��=1 then �������="1ͨ���ͻ�" ;else �������="2�ܾ��ͻ�";

��3�²�ѯ���� =sum(��3���±��˲�ѯ����,��3���´����ѯ����);
��2���ѯ����=sum(��2������ѯ����,��2�����ÿ���ѯ����,��2����˲�ѯ����);

if ������ծ>0 then ������ծ����=1;
if ���������<1 then ���������=�籣����;
�޵�Ѻ�������ܼ� = sum(������ծ����,δ�����޵�Ѻ����);
δ��������ܼ� = sum(������ծ����,δ�������);
����δ�����޵�Ѻ����=sum(������ծ����,����δ�����޵�Ѻ����);

array numr _numeric_;
do over numr;
if numr=. then numr=0;
end;
run;

/*���� �߷� 31ge û���⡣ ������ 11��*/
data test;
set all_info1;
/*if apply_code="PL153925039126802300000699" ;*/
keep apply_code name ���Ŵ����� ������ծ���� δ������� ��6���±��˲�ѯ����;
if approve_��Ʒ="E��ͨ";
run ;


proc sql ;
create table report as select approve_��Ʒ,input_week,count(*)as �������,sum(ͨ��)/count(*) as ͨ����,sum(nonlocal)/count(*) as ��������ռ��,sum(IS_HAS_HOURSE1)/count(*) as �з�����ռ��
,mean(��ʵ����) as ƽ������,mean(���������) as ƽ���籣�򹫻���ɷѻ���,mean(�ⲿ��ծ��) as ƽ���ⲿ��ծ��
,mean(���ÿ�ʹ����) as ƽ�����ÿ�ʹ����,mean(�����ܸ�ծ�ܼ�) as ƽ���»����,mean(��3�²�ѯ����) as ƽ����3�²�ѯ���� ,mean(��6���±��˲�ѯ����) as ƽ����6���±��˲�ѯ����
,mean(��2���ѯ����) as ƽ����2���ѯ����,mean(δ��������ܼ�) as ƽ�����д������,mean(�޵�Ѻ�������ܼ�) as ƽ��ͬ�д������  
,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������ ,mean(���ѽ���δ�����޵�Ѻ����) as ƽ�����ѽ����޵�Ѻ������ ,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������
,mean(�����޵�Ѻ������) as ƽ�������޵�Ѻ������
 
from all_info1(where=(check_end =1 )) group by approve_��Ʒ,input_week;quit;

proc sql ;
create table report2 as select approve_��Ʒ,�������,input_week,count(*)as �������,sum(nonlocal)/count(*) as ��������ռ��,sum(IS_HAS_HOURSE1)/count(*) as �з�����ռ��,mean(�޵�Ѻ�������ܼ�) as ƽ��ͬ�д������  
,mean(��ʵ����) as ƽ������,mean(���������) as ƽ���籣�򹫻���ɷѻ���,mean(�ⲿ��ծ��) as ƽ���ⲿ��ծ��
,mean(���ÿ�ʹ����) as ƽ�����ÿ�ʹ����,mean(�����ܸ�ծ�ܼ�) as ƽ���»����,mean(��3�²�ѯ����) as ƽ����3�²�ѯ���� ,mean(��6���±��˲�ѯ����) as ƽ����6���±��˲�ѯ����
,mean(��2���ѯ����) as ƽ����2���ѯ����,mean(δ��������ܼ�) as ƽ�����д������
,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������ ,mean(���ѽ���δ�����޵�Ѻ����) as ƽ�����ѽ����޵�Ѻ������ ,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������
,mean(�����޵�Ѻ������) as ƽ�������޵�Ѻ������

from all_info1(where=(check_end =1 )) group by approve_��Ʒ,�������,input_week ;quit;

proc sql ;
create table report3 as select �������,input_week,count(*)as �������,sum(nonlocal)/count(*) as ��������ռ��,sum(IS_HAS_HOURSE1)/count(*) as �з�����ռ��,mean(�޵�Ѻ�������ܼ�) as ƽ��ͬ�д������  
,mean(��ʵ����) as ƽ������,mean(���������) as ƽ���籣�򹫻���ɷѻ���,mean(�ⲿ��ծ��) as ƽ���ⲿ��ծ��
,mean(���ÿ�ʹ����) as ƽ�����ÿ�ʹ����,mean(�����ܸ�ծ�ܼ�) as ƽ���»����,mean(��3�²�ѯ����) as ƽ����3�²�ѯ���� ,mean(��6���±��˲�ѯ����) as ƽ����6���±��˲�ѯ����
,mean(��2���ѯ����) as ƽ����2���ѯ����,mean(δ��������ܼ�) as ƽ�����д������
,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������ ,mean(���ѽ���δ�����޵�Ѻ����) as ƽ�����ѽ����޵�Ѻ������ ,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������
,mean(�����޵�Ѻ������) as ƽ�������޵�Ѻ������

from all_info1(where=(check_end =1 )) group by �������,input_week;quit;

proc sql ;
create table report4 as select input_week,count(*)as �������,sum(ͨ��)/count(*) as ͨ����,sum(nonlocal)/count(*) as ��������ռ��,sum(IS_HAS_HOURSE1)/count(*) as �з�����ռ��,mean(�޵�Ѻ�������ܼ�) as ƽ��ͬ�д������  
,mean(��ʵ����) as ƽ������,mean(���������) as ƽ���籣�򹫻���ɷѻ���,mean(�ⲿ��ծ��) as ƽ���ⲿ��ծ��
,mean(���ÿ�ʹ����) as ƽ�����ÿ�ʹ����,mean(�����ܸ�ծ�ܼ�) as ƽ���»����,mean(��3�²�ѯ����) as ƽ����3�²�ѯ���� ,mean(��6���±��˲�ѯ����) as ƽ����6���±��˲�ѯ����
,mean(��2���ѯ����) as ƽ����2���ѯ����,mean(δ��������ܼ�) as ƽ�����д������
,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������ ,mean(���ѽ���δ�����޵�Ѻ����) as ƽ�����ѽ����޵�Ѻ������ ,mean(����δ�����޵�Ѻ����) as ƽ�������޵�Ѻ������
,mean(�����޵�Ѻ������) as ƽ�������޵�Ѻ������

from all_info1(where=(check_end =1 )) group by input_week;quit;

data report_Com;
set report2 report report3 report4;
if �������="" then �������="3�����ͻ�";
if approve_��Ʒ="" then approve_��Ʒ="ALL";

/*if �����·�="201809";*/
run;

proc sort data = report_Com;by approve_��Ʒ �������;run;


/*PROC EXPORT DATA=report_Com*/
/*OUTFILE= "F:\share\�ܱ���\������Ʒ����\10�µڶ��ܽ�����Ʒ����.xlsx" DBMS=EXCEL REPLACE;SHEET="�����ͻ�"; RUN;*/

/*������Ҫ���ֶ� ��Ⱥ*/
PROC IMPORT OUT= title
            DATAFILE= "D:\share\�ܱ���\������Ʒ����\������Ʒ����.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="dde$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc sql;
create table report_Com_dde as select a.*,b.* from title as a left join report_Com as b on a.approve_��Ʒ=b.approve_��Ʒ and a.�������=b.�������;quit;


x  "D:\share\�ܱ���\������Ʒ����\������Ʒ����.xlsx"; 
/*filename DD DDE "EXCEL|[������Ʒ����.xlsx]�����ͻ�!r2c2:r19c3";*/
/*data _null_;set report_Com_dde;file dd;put ������� ͨ���� ;run;*/
/**/
/*filename DD DDE "EXCEL|[������Ʒ����.xlsx]�����ͻ�!r2c5:r19c16";*/
/*data _null_;set report_Com_dde;file dd;put ��������ռ�� �з�����ռ�� ƽ������ ƽ���籣�򹫻���ɷѻ��� ƽ���ⲿ��ծ�� ƽ�����ÿ�ʹ���� ƽ��ͬ�д������ ƽ�����д������*/
/* ƽ���»���� ƽ����3�²�ѯ���� ƽ����6���±��˲�ѯ���� ƽ����2���ѯ����;run;*/


PROC IMPORT OUT= title2
            DATAFILE= "D:\share\�ܱ���\������Ʒ����\������Ʒ����.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="dde2$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc transpose data =report_Com out=report_tran ;
by approve_��Ʒ �������;
run;

proc sql;
create table report_tran_dde as select a.*,b.* from title2 as a left join report_tran as b on
a.��Ʒ=b.approve_��Ʒ and a.ά��=b._name_ and a.�������=b.�������;quit;

proc sort data = report_tran_dde;by id;run;

filename DD DDE "EXCEL|[������Ʒ����.xlsx]������Ʒ�����ܱ�!r3c&i.:r314c&i.";
data _null_;set report_tran_dde;file dd;put col1;run;

