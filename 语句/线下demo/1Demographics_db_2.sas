/*Demographics*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/
/*resource*/
libname appFin "\\data_computer\A_offline\daily\Daily_MTD_Acquisition\dta";
libname appRaw "D:\share\Datamart\ԭ��\approval";
libname resRaw odbc  datasrc=res_nf;
libname urule odbc  datasrc=urule_nf;
libname DemoFin "D:\share\����demo\����";
libname repayfin "D:\share\Datamart\�м��\repayAnalysis";


/*libname resRaw odbc user=sz_readuser password="xEUp9IDdDcgdorlr" datasrc=TSRes;*/
/*approval*/
/*libname appRaw odbc user=sz_readuser password="xEUp9IDdDcgdorlr" datasrc=tsapp;*/
/*credit*/
/*libname creRaw odbc user=sz_readuser password="xEUp9IDdDcgdorlr" datasrc=tscred;*/

data _null_;
format work_date yymmdd10.;
nowdate=today();

work_date=intnx("month",nowdate,-1,"end");
call symput("work_date",work_date);
call symput("work_day",compress(put(work_date,yymmdd10.),"-"));
call symput("work_month",compress(put(work_date,yymmn6.),"-"));

run;
%put &work_date. &work_day. &work_month.;




/*�˿�ѧ������� base_use*/
data base_use;
set appraw.apply_base;
run;
/*��Ӷ��Ϣ emp_use*/
data emp_use;
set appRaw.apply_emp;
run;

/*��ҵ��Ϣ industry_use*/
data industry_use;
set appRaw.apply_ext_data;
format industry_CN $50.;
industry_CN=CATX('-',put(industry_CODE,$20.),compress(industry_NAME,'/')) ;
keep apply_code industry_cn;
run;
/*�ʲ���Ϣ assets_use*/
data assets_use;
set appRaw.apply_assets;
run;
/*����/��ծ  dsr_use*/
data dsr_use;
set appRaw.liability_ratio;
rename apply_no=apply_code;
run;

/*���� score_use*/
libname DEMO "D:\share\����demo\����demo";
data score_use;
set DEMO.credit_score;
/*keep apply_code score group_level  risk_level; */
keep apply_code  group_level  risk_level; 
run;

proc sort data=base_use;by apply_code;run;
proc sort data=emp_use;by apply_code;run;
proc sort data=industry_use;by apply_code;run;
proc sort data=assets_use;by apply_code;run;
proc sort data=dsr_use;by apply_code;run;
proc sort data=score_use;by apply_code;run;
/*��������*/
data app_use(drop =LOCAL_RESCONDITION LOCAL_RES_YEARS);
set appFin.daily_acquisition_;
run;

data apply_base;
set appRaw.apply_base(keep = apply_code LOCAL_RESCONDITION LOCAL_RES_YEARS );
/*RESIDENCE-��סַ PERMANENT-������ַ*/

run;
data apply_balance;
set appRaw.apply_balance;
keep apply_code SOCIAL_SECURITY;
run;


/*�������*/
proc sort data=app_use;by apply_code;run;
proc sort data=apply_base;by apply_code;run;
proc sort data=apply_balance;by apply_code;run;


data demo_use0;
merge app_use(in=a) base_use(in=b) emp_use(in=c) industry_use(in=d) assets_use(in=e)
	  dsr_use(in=f) score_use(in=g) apply_base apply_balance;
by apply_code;
if a;
/*����סլ����-�������ݴ洢��apply_base�����ִ洢��apply_asstes����*/
if LOCAL_RESCONDITION="" then LOCAL_RESCONDITION=HOUSING_PROPERTY;
run;

/*��ծ��֮ǰ����debt_ratio�������*/
data debt_ratio;
set appRaw.debt_ratio;
keep apply_no debt_ratio id ;
rename apply_no=apply_code;
run;
/*����������Դ�ڻƵǷ��ṩ*/
/*libname DEMO "D:\songts\workteam\������\������\to zhipei\Demographics\sas code\adjust����";*/

data credit_use;
set demo.model_var;
run;
/*apply_info*/
data apply_info;
set appraw.apply_info;
keep apply_code DESIRED_PRODUCT desired_loan_life;
run;

proc sort data=demo_use0;by apply_code;run;
proc sort data=debt_ratio;by apply_code decending id;run;
proc sort data=debt_ratio nodupkey;by apply_code ;run;
proc sort data=credit_use;by apply_code;run;
proc sort data=apply_info;by apply_code;run;

/*credit_use(in=c) debt_ratio(in=b) */
data use0;
merge demo_use0(in=a)credit_use(in=b) debt_ratio(in=c) apply_info(in=d);
by apply_code;
if a;
run;


/*�����֡���������������360�����������¹����غ���Ϣ��*/
data apply_identity_match;
set appmid.apply_identity_match;
YM=cats(year(datepart(created_time)),put(month(datepart(created_time)),z2.));
run;

proc sql;
create table TQJA as
select a.YM as apply_month , a.apply_code ,b.value as TQ_score ,c.value as TQ_b ,d.value as r360_b ,e.value as JA_w ,f.value as JA_r
	from (select distinct YM ,apply_code from apply_identity_match) as a
	left join apply_identity_match(where=(channel="TQ" and type="FRACTION")) as b on a.apply_code=b.apply_code and a.YM=b.YM
	left join apply_identity_match(where=(channel="TQ" and type="BLACK")) as c on a.apply_code=c.apply_code and a.YM=c.YM
	left join apply_identity_match(where=(channel="TJ" and type="RESULT")) as d on a.apply_code=d.apply_code and a.YM=d.YM
	left join apply_identity_match(where=(channel="JA" and type="B18_CODE")) as e on a.apply_code=e.apply_code and a.YM=e.YM
	left join apply_identity_match(where=(channel="JA" and type="B19_CODE")) as f on a.apply_code=f.apply_code and a.YM=f.YM;
quit;


/*��ģ�ͷ�*/
data rule011param;
set urule.rule011param;
keep apply_code created_date model_score_level;
run;

proc sort data=rule011param ; by apply_code  desending created_date;run;
proc sort data=rule011param out=new_model nodupkey; by apply_code ;run;
proc sort data=TQJA ; by apply_code  desending apply_month;run;
proc sort data=TQJA nodupkey; by apply_code ;run;



data use1;
merge use0(in=a) TQJA(in=b) new_model(in=c);
by apply_code;
if a;
drop YM created_date;
run;
/*�����֡���������������360�����������¹����غ���Ϣ�أ���ģ�ͷ�*/


/*������������*/
data use;
set use1;
if APPLY_CODE="" then ���˽��_����=20000;
if branch_code = "6" then Ӫҵ�� = "�Ϻ�����·Ӫҵ��";
else if branch_code = "13" then Ӫҵ�� = "�Ϻ��ڶ�Ӫҵ��";
else if branch_code = "16" then Ӫҵ�� = "�������ֺ���·Ӫҵ��";
else if branch_code = "14" then Ӫҵ�� = "�Ϸ�վǰ·Ӫҵ��";
else if branch_code = "15" then Ӫҵ�� = "��������·Ӫҵ��";
else if branch_code = "17" then Ӫҵ�� = "�ɶ��츮����Ӫҵ��";
else if branch_code = "50" then Ӫҵ�� = "���ݵ�һӪҵ��";
else if branch_code = "55" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "57" then Ӫҵ�� = "���ݽ�����·Ӫҵ��";
else if branch_code = "56" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "114" then Ӫҵ�� = "��ɽ�е�һӪҵ��";
else if branch_code = "90" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "63" then Ӫҵ�� = "����е�һӪҵ��";
else if branch_code = "120" then Ӫҵ�� = "����е�һӪҵ��";
else if branch_code = "60" then Ӫҵ�� = "���ͺ����е�һӪҵ��";
else if branch_code = "71" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "50" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "113" then Ӫҵ�� = "�����е�һӪҵ��";
else if branch_code = "119" then Ӫҵ�� = "�人�е�һӪҵ��";
else if branch_code = "117" then Ӫҵ�� = "�γ��е�һӪҵ��";
else if branch_code = "116" then Ӫҵ�� = "��ͨ��ҵ������";
else if branch_code = "115" then Ӫҵ�� = "������ҵ������";
/*�ڴ���Ʒ����*/
format DESIRED_product_name $20.;
	if DESIRED_PRODUCT="Ebaotong" then DESIRED_product_name="E��ͨ";
	else if DESIRED_PRODUCT="Efangtong" then DESIRED_product_name="E��ͨ";
	else if DESIRED_PRODUCT in ("Elite","TYElite") then DESIRED_product_name="U��ͨ";
	else if DESIRED_PRODUCT="Eshetong" then DESIRED_product_name="E��ͨ";
	else if DESIRED_PRODUCT="Ewangtong" then DESIRED_product_name="E��ͨ";
	else if DESIRED_PRODUCT in ("Salariat","TYSalariat") then DESIRED_product_name="E��ͨ";
         if DESIRED_PRODUCT="RFEbaotong" then DESIRED_product_name="RFE��ͨ";
	else if DESIRED_PRODUCT="RFElite" then DESIRED_product_name="RFU��ͨ";
	else if DESIRED_PRODUCT="RFEwangtong" then DESIRED_product_name="RFE��ͨ";
	else if DESIRED_PRODUCT="RFSalariat" then DESIRED_product_name="RFE��ͨ";
	else if DESIRED_PRODUCT="Eweidai" then DESIRED_product_name="E΢��";
	else if DESIRED_PRODUCT="Ebaotong-zigu" then DESIRED_product_name="E��ͨ-�Թ�";
	else if DESIRED_PRODUCT="Ezhaitong" then DESIRED_product_name="Eլͨ";
	else if DESIRED_PRODUCT="Ezhaitong-zigu" then DESIRED_product_name="Eլͨ-�Թ�";
	else if DESIRED_PRODUCT="Eweidai-zigu" then DESIRED_product_name="E΢��-�Թ�";
	else if DESIRED_PRODUCT="Eweidai-NoSecurity" then DESIRED_product_name="E΢��-���籣";
	else if DESIRED_PRODUCT="Easy-CreditCard" then DESIRED_product_name="E�״�-���ÿ�";
	else if DESIRED_PRODUCT="Easy-ZhiMa" then DESIRED_product_name="E�״�-֥���";

/*���˲�Ʒ����*/
format product_code $20.;
if ͨ��=1 then do;
	if ���˲�Ʒ����_����="ͬҵ��U��ͨ" then product_code="U��ͨ";
	else product_code=���˲�Ʒ����_����;
	end;
else do;
	ͨ��=0;
	if DESIRED_PRODUCT in ("Elite","TYElite") then product_code="U��ͨ" ;
	else if DESIRED_PRODUCT in ("Salariat","TYSalariat") then product_code="E��ͨ";
	else if DESIRED_PRODUCT="Ebaotong" then product_code="E��ͨ";
	else if DESIRED_PRODUCT="Efangtong" then product_code="E��ͨ";
	else if DESIRED_PRODUCT="Eshetong" then product_code="E��ͨ";
	else if DESIRED_PRODUCT="Ewangtong" then product_code="E��ͨ";
	     if DESIRED_PRODUCT="RFEbaotong" then product_code="RFE��ͨ";
	else if DESIRED_PRODUCT="RFElite" then product_code="RFU��ͨ";
	else if DESIRED_PRODUCT="RFEwangtong" then product_code="RFE��ͨ";
	else if DESIRED_PRODUCT="RFSalariat" then product_code="RFE��ͨ";
	else if DESIRED_PRODUCT="Eweidai" then product_code="E΢��";
	else if DESIRED_PRODUCT="Ebaotong-zigu" then product_code="E��ͨ-�Թ�";
	else if DESIRED_PRODUCT="Ezhaitong" then product_code="Eլͨ";
	else if DESIRED_PRODUCT="Ezhaitong-zigu" then product_code="Eլͨ-�Թ�";
	else if DESIRED_PRODUCT="Eweidai-zigu" then product_code="E΢��-�Թ�";
	else if DESIRED_PRODUCT="Eweidai-NoSecurity" then product_code="E΢��-���籣";
	else if DESIRED_PRODUCT="Easy-CreditCard" then product_code="E�״�-���ÿ�";
	else if DESIRED_PRODUCT="Easy-ZhiMa" then product_code="E�״�-֥���";
end;
/*������Ʒ����*/
format desired_tenor $20.;
if desired_loan_life="341" then desired_tenor="06��";
else if desired_loan_life="342" then desired_tenor="12��";
else if desired_loan_life="343" then desired_tenor="18��";
else if desired_loan_life="344" then desired_tenor="24��";
else if desired_loan_life="345" then desired_tenor="36��";
/*���˲�Ʒ����*/
format approval_tenor $20.;
if ��������_����=. then approval_tenor=desired_tenor;
else if ��������_����=6 then approval_tenor="06��";
else if ��������_����=12 then approval_tenor="12��";
else if ��������_����=18 then approval_tenor="18��";
else if ��������_����=24 then approval_tenor="24��";
else if ��������_����=36 then approval_tenor="36��";

/*������� ID_CARD_NO ȡ���������ռ���-ʵ������*/
format age 10.;
format birthdate yymmdd10.;
birth_year=substr(ID_CARD_NO,7,4)+0;
birth_mon=substr(ID_CARD_NO,11,2)+0;
birth_day=substr(ID_CARD_NO,13,2)+0;
birthdate=mdy(birth_mon,birth_day,birth_year);
age=Intck('year',birthdate,datepart(apply_time));
drop birth_mon birth_day birth_year;

/*���� age*/
format age_g $20.;
if age<18 then age_g="0.<18��";
else if age>=18 and age<=25 then age_g="1.18-25��";
else if age>25 and age<=30 then age_g="2.26-30��";
else if age>30 and age<=35 then age_g="3.31-35��";
else if age>35 and age<=40 then age_g="4.36-40��";
else if age>40 and age<=45 then age_g="5.41-45��";
else if age>45 and age<=55 then age_g="6.46-55��";
else if age>55 and age<=60 then age_g="7.55-60��";
else if age>60  then age_g="8.>60��";
count=1;
/*��Ů���� CHILD_COUNT*/
format CHILD_COUNT_G $20.;
if CHILD_COUNT=0 then CHILD_COUNT_G="0.����Ů";
else if CHILD_COUNT=1 then CHILD_COUNT_G="1.1����Ů";
else if CHILD_COUNT=2 then CHILD_COUNT_G="2.2����Ů";
else if CHILD_COUNT>2 then CHILD_COUNT_G="3.2��������Ů";
/*��������ʱ�� LOCAL_RES_YEARS*/
format LOCAL_RES_YEARS_G $20.;
if LOCAL_RES_YEARS>=0 and LOCAL_RES_YEARS<1 then LOCAL_RES_YEARS_G="0.����1��";
else if LOCAL_RES_YEARS>=1 and LOCAL_RES_YEARS<3 then LOCAL_RES_YEARS_G="1.1-<3��";
else if LOCAL_RES_YEARS>=3 and LOCAL_RES_YEARS<5 then LOCAL_RES_YEARS_G="2.3-<5��";
else if LOCAL_RES_YEARS>=5 and LOCAL_RES_YEARS<10 then LOCAL_RES_YEARS_G="3.5-<10��";
else if LOCAL_RES_YEARS>=10 and LOCAL_RES_YEARS<20 then LOCAL_RES_YEARS_G="4.10-<20��";
else if LOCAL_RES_YEARS>=20 then LOCAL_RES_YEARS_G="5.20+��";
/*�����䶯���� WORK_CHANGE_TIMES*/
format  WORK_CHANGE_TIMES_G $20.;
if WORK_CHANGE_TIMES=0 then WORK_CHANGE_TIMES_G="0.�ޱ䶯";
else if WORK_CHANGE_TIMES=1 then WORK_CHANGE_TIMES_G="1.1�α䶯";
else if WORK_CHANGE_TIMES=2 then WORK_CHANGE_TIMES_G="2.2�α䶯";
else if WORK_CHANGE_TIMES>=3 then WORK_CHANGE_TIMES_G="3.3�μ����ϱ䶯";
/*�������� work_years*/
format work_years_g $20.;
if work_years=0  then work_years_g="0.�޲μӹ���";
else if work_years<1 then work_years_g="1.��������1��";
else if work_years<3 then work_years_g="2.����1-<3��";
else if work_years<5 then work_years_g="3.����3-<5��";
else if work_years<10 then work_years_g="4.����5-<10��";
else if work_years<20 then work_years_g="5.����10-<20��";
else if work_years>=20 then work_years_g="6.����20������";
/*�������� HOURSE_COUNT*/
format HOURSE_COUNT_G $20.;
if HOURSE_COUNT=0 then HOURSE_COUNT_G="0.�޷���";
else if HOURSE_COUNT=1 then HOURSE_COUNT_G="1.1�׷���";
else if HOURSE_COUNT=2 then HOURSE_COUNT_G="2.2�׷���";
else if HOURSE_COUNT>=3 then HOURSE_COUNT_G="3.3�����Ϸ���";
/*�������� CAR_COUNT*/;
format CAR_COUNT_G $20.;
if CAR_COUNT=0 then CAR_COUNT_G="0.������";
else if CAR_COUNT=1 then CAR_COUNT_G="1.1������";
else if CAR_COUNT>=2 then CAR_COUNT_G="2.2������������";
/*�ܱ��� INSURANCE_INSURED_PRICE*/
format INSURANCE_INSURED_PRICE_G $20.;
if INSURANCE_INSURED_PRICE=0 or INSURANCE_INSURED_PRICE=. then INSURANCE_INSURED_PRICE_G="0.�޲α�";
else if INSURANCE_INSURED_PRICE<=50000 then INSURANCE_INSURED_PRICE_G="1.�ܱ���1-5��";
else if INSURANCE_INSURED_PRICE<=100000 then INSURANCE_INSURED_PRICE_G="2.�ܱ���6-10��";
else if INSURANCE_INSURED_PRICE<=500000 then INSURANCE_INSURED_PRICE_G="3.�ܱ���11-50��";
else if INSURANCE_INSURED_PRICE<=1000000 then INSURANCE_INSURED_PRICE_G="4.�ܱ���51-100��";
else if INSURANCE_INSURED_PRICE<=2000000 then INSURANCE_INSURED_PRICE_G="5.�ܱ���101-200��";
else if INSURANCE_INSURED_PRICE<=5000000 then INSURANCE_INSURED_PRICE_G="6.�ܱ���201-500��";
else if INSURANCE_INSURED_PRICE>5000000 then INSURANCE_INSURED_PRICE_G="7.�ܱ���>500��";
/*���� VERIFY_INCOME*/
format VERIFY_INCOME_G $20.;
if VERIFY_INCOME<=0 or VERIFY_INCOME=. then VERIFY_INCOME_G="0.�޺�ʵ����";
else if VERIFY_INCOME<3000 then VERIFY_INCOME_G="1.<3000Ԫ";
else if VERIFY_INCOME<5000 then VERIFY_INCOME_G="2.3000-<5000Ԫ";
else if VERIFY_INCOME<8000 then VERIFY_INCOME_G="3.5000-<8000Ԫ";
else if VERIFY_INCOME<10000 then VERIFY_INCOME_G="4.8000-<10000Ԫ";
else if VERIFY_INCOME<20000 then VERIFY_INCOME_G="5.10000-<20000Ԫ";
else if VERIFY_INCOME<30000 then VERIFY_INCOME_G="6.20000-<30000Ԫ";
else if VERIFY_INCOME<50000 then VERIFY_INCOME_G="7.30000-<50000Ԫ";
else if VERIFY_INCOME<100000 then VERIFY_INCOME_G="8.50000-<100000Ԫ";
else if VERIFY_INCOME>=100000 then VERIFY_INCOME_G="9.>=100000Ԫ";
/*��ծ�� RATIO*/
format RATIO_G $20.;
if RATIO=. THEN RATIO=debt_ratio/100;
if RATIO=0 then RATIO_G="0.DSR=0";
else if RATIO<0.1 then RATIO_G="1.DSR 0-<10%";
else if RATIO<0.3 then RATIO_G="2.DSR 10-<30%";
else if RATIO<0.5 then RATIO_G="3.DSR 30-<50%";
else if RATIO<0.6 then RATIO_G="4.DSR 50-<60%";
else if RATIO<0.7 then RATIO_G="5.DSR 60-<70%";
else if RATIO<0.8 then RATIO_G="6.DSR 70-<80%";
else if RATIO<0.9 then RATIO_G="7.DSR 80-<90%";
else if RATIO<1 then RATIO_G="8.DSR 90-<100%";
else if RATIO<2 then RATIO_G="91.DSR 100-<200%";
else if RATIO<3 then RATIO_G="92.DSR 200-<300%";
else if RATIO<4 then RATIO_G="93.DSR 300-<400%";
else if RATIO<5 then RATIO_G="94.DSR 400-<500%";
else if RATIO>=5 then RATIO_G="95.DSR >=500%";

/*��ס���뻧����ϵ*/
format RES_Type $20.;
if RESIDENCE_CITY=PERMANENT_ADDR_CITY then Res_Type="1.��ס��Ϊ��������";
else if RESIDENCE_PROVINCE=PERMANENT_ADDR_PROVINCE then Res_Type="2.��ס��Ϊ������ʡ";
else if RESIDENCE_PROVINCE ne PERMANENT_ADDR_PROVINCE then Res_Type="3.��ס��Ϊ�ǻ���ʡ";
/*���ÿ����� δ�������ÿ��˻���*/
format credit_card_g $20.;
if δ�������ÿ��˻���=0 then credit_card_g="0.��";
else if δ�������ÿ��˻���=. then credit_card_g="Missing";
else if δ�������ÿ��˻���=1 then credit_card_g="1.1��";
else if δ�������ÿ��˻���=2 then credit_card_g="2.2��";
else if δ�������ÿ��˻���=3 then credit_card_g="3.3��";
else if δ�������ÿ��˻���<=5 then credit_card_g="4.4-5��";
else if δ�������ÿ��˻���<=10 then credit_card_g="5.6-10��";
else if δ�������ÿ��˻���<=20 then credit_card_g="6.11-20��";
else if δ�������ÿ��˻���>20 then credit_card_g="7.20��";
/*δ�����Ѻ��������*/
format secured_cnt_g $20.;
if δ�����Ѻ��������=0 then secured_cnt_g="0.�޵�Ѻ����";
else if δ�����Ѻ��������=. then secured_cnt_g="Missing";
else if δ�����Ѻ��������=1 then secured_cnt_g="1.1����Ѻ����";
else if δ�����Ѻ��������=2 then secured_cnt_g="2.2����Ѻ����";
else if δ�����Ѻ��������>=3 then secured_cnt_g="3.3�������ϵ�Ѻ����";
/*δ�������Ѵ�������*/
format unsecured_cnt_g $20.;
if δ�������Ѵ�������=0 then unsecured_cnt_g="0.�����Ѵ���";
else if δ�������Ѵ�������=. then unsecured_cnt_g="Missing";
else if δ�������Ѵ�������=1 then unsecured_cnt_g="1.1�����Ѵ���";
else if δ�������Ѵ�������=2 then unsecured_cnt_g="2.2�����Ѵ���";
else if δ�������Ѵ�������=3 then unsecured_cnt_g="3.3�����Ѵ���";
else if δ�������Ѵ�������>3 and δ�������Ѵ�������<=5 then unsecured_cnt_g="4.4-5�����Ѵ���";
else if δ�������Ѵ�������>5 and δ�������Ѵ�������<=10 then unsecured_cnt_g="5.5-10�����Ѵ���";
else if δ�������Ѵ�������>10 then unsecured_cnt_g="6.10���������Ѵ���";
/*δ����������������*/
format otherloan_cnt_g $20.;
if δ����������������=0 then otherloan_cnt_g="0.����������";
else if δ����������������=. then otherloan_cnt_g="Missing";
else if δ����������������=1 then otherloan_cnt_g="1.1����������";
else if δ����������������=2 then otherloan_cnt_g="2.2����������";
else if δ����������������=3 then otherloan_cnt_g="3.3����������";
else if δ����������������>3 and δ����������������<=5 then otherloan_cnt_g="4.4-5����������";
else if δ����������������>5 and δ����������������<=10 then otherloan_cnt_g="5.5-10����������";
else if δ����������������>10 then otherloan_cnt_g="6.10��������������";
/*��3���²�ѯ����*/
format querry_L3M_g $20.;
if ��3���²�ѯ����=0 then querry_L3M_g="0.�޲�ѯ";
else if ��3���²�ѯ����=. then querry_L3M_g="Missing";
else if ��3���²�ѯ����=1 then querry_L3M_g="1.1�β�ѯ";
else if ��3���²�ѯ����=2 then querry_L3M_g="2.2�β�ѯ";
else if ��3���²�ѯ����=3 then querry_L3M_g="3.3�β�ѯ";
else if ��3���²�ѯ����>3  and ��3���²�ѯ����<=5 then querry_L3M_g="4.4-5�β�ѯ";
else if ��3���²�ѯ����>5  and ��3���²�ѯ����<=10 then querry_L3M_g="5.6-10�β�ѯ";
else if ��3���²�ѯ����>10  and ��3���²�ѯ����<=20 then querry_L3M_g="6.11-20�β�ѯ";
else if ��3���²�ѯ����>20  then querry_L3M_g="7.20�����ϲ�ѯ";
/*��6�������ÿ����뱻�ܴ���*/
format CReject_L6M_g $20.;
if ��6�������ÿ����뱻�ܴ���=. then CReject_L6M_g="Missing";
else if ��6�������ÿ����뱻�ܴ���<=0 then CReject_L6M_g="0.�ޱ���";
else if ��6�������ÿ����뱻�ܴ���=1 then CReject_L6M_g="1.1�α���";
else if ��6�������ÿ����뱻�ܴ���=2 then CReject_L6M_g="2.2�α���";
else if ��6�������ÿ����뱻�ܴ���=3 then CReject_L6M_g="3.3�α���";
else if ��6�������ÿ����뱻�ܴ���=4 then CReject_L6M_g="4.4�α���";
else if ��6�������ÿ����뱻�ܴ���>4 and ��6�������ÿ����뱻�ܴ���<=10 then CReject_L6M_g="5.5-10�α���";
else if ��6�������ÿ����뱻�ܴ���>10 then CReject_L6M_g="6.10�����ϱ���";
/*���ÿ�ʹ����*/
format cc_useage_g $20.;
if ���ÿ�ʹ����=0 then cc_useage_g="0.0%";
else if ���ÿ�ʹ����=. then cc_useage_g="Missing";
else if ���ÿ�ʹ����<0.3 then cc_useage_g="1.<30%";
else if ���ÿ�ʹ����<0.5 then cc_useage_g="2.30-<50%";
else if ���ÿ�ʹ����<0.6 then cc_useage_g="3.50-<60%";
else if ���ÿ�ʹ����<0.7 then cc_useage_g="4.60-<70%";
else if ���ÿ�ʹ����<0.8 then cc_useage_g="5.70-<80%";
else if ���ÿ�ʹ����<0.9 then cc_useage_g="6.80-<90%";
else if ���ÿ�ʹ����<1 then cc_useage_g="7.90-<100%";
else if ���ÿ�ʹ����>=1 then cc_useage_g="8.100%+";
/*��2���ѯ����*/
format querry_L2Y_g $20.;
if ��2���ѯ����=0 then querry_L2Y_g="0.�޲�ѯ";
else if ��2���ѯ����=. then querry_L2Y_g="Missing";
else if ��2���ѯ����<12 then querry_L2Y_g="1.1-<12�β�ѯ";
else if ��2���ѯ����<24 then querry_L2Y_g="2.12-<24�β�ѯ";
else if ��2���ѯ����<36 then querry_L2Y_g="3.24-<36�β�ѯ";
else if ��2���ѯ����<48 then querry_L2Y_g="4.37-<48�β�ѯ";
else if ��2���ѯ����<60 then querry_L2Y_g="5.49-<60�β�ѯ";
else if ��2���ѯ����>=60 then querry_L2Y_g="6.60�����ϲ�ѯ";
format ���˽��_����_G $20.;
if ���˽��_����<=0 or ���˽��_����=. then ���˽��_����_G="���˲�ͨ��";
else if ���˽��_����<20000 then ���˽��_����_G="1.<20000Ԫ";
else if ���˽��_����<30000 then ���˽��_����_G="2.20000-<30000Ԫ";
else if ���˽��_����<40000 then ���˽��_����_G="3.30000-<40000Ԫ";
else if ���˽��_����<50000 then ���˽��_����_G="4.40000-<50000Ԫ";
else if ���˽��_����<80000 then ���˽��_����_G="5.50000-<80000Ԫ";
else if ���˽��_����>=80000 then ���˽��_����_G="6.>=80000Ԫ";

format ְҵ $20.;
if COMP_TYPE in ("160","161") then ְҵ="����Ա/��ҵ��λ";
else  ְҵ="��˾ְԱ";
/*���������¡���360*/
format TQ_code $20.;
if TQ_score=. then TQ_code="z-Missing";
else if TQ_score<=467 then TQ_code="E";
else if TQ_score<=543 then TQ_code="D";
else if TQ_score<=619 then TQ_code="C";
else if TQ_score<=714 then TQ_code="B";
else if TQ_score>=715 then TQ_code="A";

format TQ_BLACK $20.;
if TQ_B=. then TQ_black="z-Missing";
else if TQ_B=0 then TQ_black="��";
else if TQ_B=1 then TQ_black="��";

format r360_black $20.;
if r360_B=. then r360_black="z-Missing";
else if r360_B=0 then r360_black="��";
else if r360_B=1 then r360_black="��";

format JA_work $20.;
     if JA_w="01"  then JA_work="1.<-2km";
else if JA_w="02"  then JA_work="2.2<-5km";
else if JA_w="03"  then JA_work="3.5<-10km";
else if JA_w="04"  then JA_work="4.ͬ���У�10km����";
else if JA_w="05"  then JA_work="5.��ͬ����";
else if JA_w="99"  then JA_work="6.�ֻ�������";
else JA_work="z-Missing";

format JA_rest $20.;
     if JA_r="01"  then JA_rest="1.<-2km";
else if JA_r="02"  then JA_rest="2.2<-5km";
else if JA_r="03"  then JA_rest="3.5<-10km";
else if JA_r="04"  then JA_rest="4.ͬ���У�10km����";
else if JA_r="05"  then JA_rest="5.��ͬ����";
else if JA_r="99"  then JA_rest="6.�ֻ�������";
else JA_rest="z-Missing";
run;




/*��Ҫ�������Ľ��͵Ĳ���*/

%macro demo_use_cn(i);
%do n=1 %to &i.;
data var;
set CN_name;
where id=&n.;
/*format var_name $45.;*/
call symput("var_name",var_name);
call symput("opt_name",option_group);
run;
%put &var_name. &opt_name.;

data  &opt_name.;
set resRaw.optionitem;
where upcase(groupCode)="&opt_name.";
keep groupCode itemCode	parentId itemName_zh;
rename itemCode=&var_name.;
run;
proc sort data=&opt_name. nodupkey;by &var_name.;run;
proc sort data=use;by &var_name.;run;

data use_&var_name.;
merge use(in=a) &opt_name.;
by  &var_name.;
if a;
CN_&var_name.=CATX('-',&var_name.,itemName_zh) ;
/*keep apply_code CN_&var_name.;*/
run;

proc sort data= use_&var_name. nodupkey;by apply_code;run;

%if &n.=1 %then %do ;
	data demo_use_cn;
	set  use_&var_name.;
	run;
	
	%end;
%else  %do;
	proc sort data=demo_use_cn;by apply_code;run;
	data demo_use_cn;
	merge demo_use_cn use_&var_name.;
	by apply_code;
	run;
	%end;
%end;
%mend;
proc import
  datafile='D:\share\����demo\input\CN_variable.csv'
  out=CN_name
  dbms=csv
  replace;
  datarow=2;
  GUESSINGROWS=500;
  GETNAMES=YES;
run;
%demo_use_cn(i=14);



data DemoFin.use_&work_day.;
set demo_use_cn;
/*risk_level*/
format risk_level_2 $20.;
if kindex(risk_level,"��") then risk_level_2="01.��";
else if kindex(risk_level,"��") then risk_level_2="02.��";
else if kindex(risk_level,"��") then risk_level_2="03.��";

format product_code  pproduct_code $20.;
if approve_��Ʒ in ("E��ͨ","Ebaotong") then product_code="E��ͨ";
	else if approve_��Ʒ in ("E��ͨ","Efangtong") then product_code="E��ͨ";
	else if approve_��Ʒ in ("E��ͨ","Eshetong") then product_code="E��ͨ";
	else if approve_��Ʒ in ("E��ͨ","Ewangtong") then product_code="E��ͨ";
	else if approve_��Ʒ in ("Elite","U��ͨ","TYElite","ͬҵ��U��ͨ") then product_code="U��ͨ";
	else if approve_��Ʒ in ("Salariat","E��ͨ","TYSalariat","ͬҵ��E��ͨ") then product_code="E��ͨ";
	else if approve_��Ʒ in ("RFEbaotong","RFE��ͨ") then product_code="E��ͨ����";
	else if approve_��Ʒ in ("RFEwangtong","RFE��ͨ") then product_code="E��ͨ����";
	else if approve_��Ʒ in ("RFEshetong","RFE��ͨ") then product_code="E��ͨ����";
	else if approve_��Ʒ in ("RFSalariat","RFE��ͨ") then product_code="E��ͨ����";
	else if approve_��Ʒ in ("RFElite","RFU��ͨ") then product_code="U��ͨ����";
	else if approve_��Ʒ in ("Eweidai","E΢��") then product_code="E΢��";
	else if approve_��Ʒ in ("Ezhaitong","Eլͨ") then product_code="Eլͨ";
	else if approve_��Ʒ in ("Ebaotong-zigu","E��ͨ-�Թ�") then product_code="E��ͨ-�Թ�";
	else if approve_��Ʒ in ("Ezhaitong-zigu","Eլͨ-�Թ�") then product_code = "Eլͨ-�Թ�";
	else if approve_��Ʒ in ("Easy-CreditCard","Easy�����ÿ�") then product_code = "Easy�����ÿ�";
	else if approve_��Ʒ in ("Easy-ZhiMa","Easy��֥���") then product_code = "Easy��֥���";

if ��������>=mdy(3,1,2018) then do;
if hire=1 then do;
if product_code="E��ͨ" then product_code1="E��ͨ-�Թ�";
else if product_code="E��ͨ" then product_code1="E��ͨ-�Թ�";
else if product_code="E��ͨ" then product_code1="E��ͨ-�Թ�";
else if product_code in ("E΢��","") then product_code1="E΢��-�Թ�";
else if product_code="Eլͨ" then product_code1="Eլͨ-�Թ�";
end;
else if SOCIAL_SECURITY=0 then do;
if product_code="E��ͨ" then product_code1="E��ͨ-���籣";
else if product_code="E��ͨ" then product_code1="E��ͨ-���籣";
else if product_code="E��ͨ" then product_code1="E��ͨ-���籣";
else if product_code="E΢��" then product_code1="E΢��-���籣";
else if product_code="Eլͨ" then product_code1="Eլͨ-���籣";
end;
end;

if kindex(DESIRED_PRODUCT,"RF") and not kindex(product_code,"����") then pproduct_code=compress(product_code||"����") ;
if pproduct_code^="" then product_code=pproduct_code;


run;

data use;
set DemoFin.use_&work_day.;
run;

option noxwait;
/*x md "D:\songts\workteam\������\������\to zhipei\Demographics\output\&work_Day.";*/
