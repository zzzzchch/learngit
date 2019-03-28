/*Demographics*/
option compress=yes validvarname=any;
/*libname appRaw "D:\WORK\Database\approval";*/
/*resource*/
libname appFin "\\data_computer\A_offline\daily\Daily_MTD_Acquisition\dta";
libname appRaw "D:\share\Datamart\原表\approval";
libname resRaw odbc  datasrc=res_nf;
libname urule odbc  datasrc=urule_nf;
libname DemoFin "D:\share\线下demo\数据";
libname repayfin "D:\share\Datamart\中间表\repayAnalysis";


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




/*人口学相关资料 base_use*/
data base_use;
set appraw.apply_base;
run;
/*雇佣信息 emp_use*/
data emp_use;
set appRaw.apply_emp;
run;

/*行业信息 industry_use*/
data industry_use;
set appRaw.apply_ext_data;
format industry_CN $50.;
industry_CN=CATX('-',put(industry_CODE,$20.),compress(industry_NAME,'/')) ;
keep apply_code industry_cn;
run;
/*资产信息 assets_use*/
data assets_use;
set appRaw.apply_assets;
run;
/*收入/负债  dsr_use*/
data dsr_use;
set appRaw.liability_ratio;
rename apply_no=apply_code;
run;

/*评分 score_use*/
libname DEMO "D:\share\线下demo\线下demo";
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
/*所有申请*/
data app_use(drop =LOCAL_RESCONDITION LOCAL_RES_YEARS);
set appFin.daily_acquisition_;
run;

data apply_base;
set appRaw.apply_base(keep = apply_code LOCAL_RESCONDITION LOCAL_RES_YEARS );
/*RESIDENCE-现住址 PERMANENT-户籍地址*/

run;
data apply_balance;
set appRaw.apply_balance;
keep apply_code SOCIAL_SECURITY;
run;


/*排序汇总*/
proc sort data=app_use;by apply_code;run;
proc sort data=apply_base;by apply_code;run;
proc sort data=apply_balance;by apply_code;run;


data demo_use0;
merge app_use(in=a) base_use(in=b) emp_use(in=c) industry_use(in=d) assets_use(in=e)
	  dsr_use(in=f) score_use(in=g) apply_base apply_balance;
by apply_code;
if a;
/*本地住宅性质-部分数据存储于apply_base，部分存储于apply_asstes表中*/
if LOCAL_RESCONDITION="" then LOCAL_RESCONDITION=HOUSING_PROPERTY;
run;

/*负债率之前存在debt_ratio这个表里*/
data debt_ratio;
set appRaw.debt_ratio;
keep apply_no debt_ratio id ;
rename apply_no=apply_code;
run;
/*征信数据来源于黄登峰提供*/
/*libname DEMO "D:\songts\workteam\黄玉州\报表交接\to zhipei\Demographics\sas code\adjust代码";*/

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


/*天启分、天启黑名单、融360黑名单、集奥工作地和休息地*/
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


/*新模型分*/
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
/*天启分、天启黑名单、融360黑名单、集奥工作地和休息地，新模型分*/


/*连续变量分组*/
data use;
set use1;
if APPLY_CODE="" then 批核金额_终审=20000;
if branch_code = "6" then 营业部 = "上海福州路营业部";
else if branch_code = "13" then 营业部 = "上海第二营业部";
else if branch_code = "16" then 营业部 = "广州市林和西路营业部";
else if branch_code = "14" then 营业部 = "合肥站前路营业部";
else if branch_code = "15" then 营业部 = "福州五四路营业部";
else if branch_code = "17" then 营业部 = "成都天府国际营业部";
else if branch_code = "50" then 营业部 = "惠州第一营业部";
else if branch_code = "55" then 营业部 = "海口市第一营业部";
else if branch_code = "57" then 营业部 = "杭州建国北路营业部";
else if branch_code = "56" then 营业部 = "厦门市第一营业部";
else if branch_code = "114" then 营业部 = "佛山市第一营业部";
else if branch_code = "90" then 营业部 = "北京市第一营业部";
else if branch_code = "63" then 营业部 = "赤峰市第一营业部";
else if branch_code = "120" then 营业部 = "红河市第一营业部";
else if branch_code = "60" then 营业部 = "呼和浩特市第一营业部";
else if branch_code = "71" then 营业部 = "怀化市第一营业部";
else if branch_code = "50" then 营业部 = "惠州市第一营业部";
else if branch_code = "113" then 营业部 = "深圳市第一营业部";
else if branch_code = "119" then 营业部 = "武汉市第一营业部";
else if branch_code = "117" then 营业部 = "盐城市第一营业部";
else if branch_code = "116" then 营业部 = "南通市业务中心";
else if branch_code = "115" then 营业部 = "江门市业务中心";
/*期待产品类型*/
format DESIRED_product_name $20.;
	if DESIRED_PRODUCT="Ebaotong" then DESIRED_product_name="E保通";
	else if DESIRED_PRODUCT="Efangtong" then DESIRED_product_name="E房通";
	else if DESIRED_PRODUCT in ("Elite","TYElite") then DESIRED_product_name="U贷通";
	else if DESIRED_PRODUCT="Eshetong" then DESIRED_product_name="E社通";
	else if DESIRED_PRODUCT="Ewangtong" then DESIRED_product_name="E网通";
	else if DESIRED_PRODUCT in ("Salariat","TYSalariat") then DESIRED_product_name="E贷通";
         if DESIRED_PRODUCT="RFEbaotong" then DESIRED_product_name="RFE保通";
	else if DESIRED_PRODUCT="RFElite" then DESIRED_product_name="RFU贷通";
	else if DESIRED_PRODUCT="RFEwangtong" then DESIRED_product_name="RFE网通";
	else if DESIRED_PRODUCT="RFSalariat" then DESIRED_product_name="RFE贷通";
	else if DESIRED_PRODUCT="Eweidai" then DESIRED_product_name="E微贷";
	else if DESIRED_PRODUCT="Ebaotong-zigu" then DESIRED_product_name="E保通-自雇";
	else if DESIRED_PRODUCT="Ezhaitong" then DESIRED_product_name="E宅通";
	else if DESIRED_PRODUCT="Ezhaitong-zigu" then DESIRED_product_name="E宅通-自雇";
	else if DESIRED_PRODUCT="Eweidai-zigu" then DESIRED_product_name="E微贷-自雇";
	else if DESIRED_PRODUCT="Eweidai-NoSecurity" then DESIRED_product_name="E微贷-无社保";
	else if DESIRED_PRODUCT="Easy-CreditCard" then DESIRED_product_name="E易贷-信用卡";
	else if DESIRED_PRODUCT="Easy-ZhiMa" then DESIRED_product_name="E易贷-芝麻分";

/*批核产品类型*/
format product_code $20.;
if 通过=1 then do;
	if 批核产品大类_终审="同业贷U贷通" then product_code="U贷通";
	else product_code=批核产品大类_终审;
	end;
else do;
	通过=0;
	if DESIRED_PRODUCT in ("Elite","TYElite") then product_code="U贷通" ;
	else if DESIRED_PRODUCT in ("Salariat","TYSalariat") then product_code="E贷通";
	else if DESIRED_PRODUCT="Ebaotong" then product_code="E保通";
	else if DESIRED_PRODUCT="Efangtong" then product_code="E房通";
	else if DESIRED_PRODUCT="Eshetong" then product_code="E社通";
	else if DESIRED_PRODUCT="Ewangtong" then product_code="E网通";
	     if DESIRED_PRODUCT="RFEbaotong" then product_code="RFE保通";
	else if DESIRED_PRODUCT="RFElite" then product_code="RFU贷通";
	else if DESIRED_PRODUCT="RFEwangtong" then product_code="RFE网通";
	else if DESIRED_PRODUCT="RFSalariat" then product_code="RFE贷通";
	else if DESIRED_PRODUCT="Eweidai" then product_code="E微贷";
	else if DESIRED_PRODUCT="Ebaotong-zigu" then product_code="E保通-自雇";
	else if DESIRED_PRODUCT="Ezhaitong" then product_code="E宅通";
	else if DESIRED_PRODUCT="Ezhaitong-zigu" then product_code="E宅通-自雇";
	else if DESIRED_PRODUCT="Eweidai-zigu" then product_code="E微贷-自雇";
	else if DESIRED_PRODUCT="Eweidai-NoSecurity" then product_code="E微贷-无社保";
	else if DESIRED_PRODUCT="Easy-CreditCard" then product_code="E易贷-信用卡";
	else if DESIRED_PRODUCT="Easy-ZhiMa" then product_code="E易贷-芝麻分";
end;
/*期望产品期限*/
format desired_tenor $20.;
if desired_loan_life="341" then desired_tenor="06期";
else if desired_loan_life="342" then desired_tenor="12期";
else if desired_loan_life="343" then desired_tenor="18期";
else if desired_loan_life="344" then desired_tenor="24期";
else if desired_loan_life="345" then desired_tenor="36期";
/*批核产品期限*/
format approval_tenor $20.;
if 批核期限_终审=. then approval_tenor=desired_tenor;
else if 批核期限_终审=6 then approval_tenor="06期";
else if 批核期限_终审=12 then approval_tenor="12期";
else if 批核期限_终审=18 then approval_tenor="18期";
else if 批核期限_终审=24 then approval_tenor="24期";
else if 批核期限_终审=36 then approval_tenor="36期";

/*年龄计算 ID_CARD_NO 取出生年月日计算-实足年龄*/
format age 10.;
format birthdate yymmdd10.;
birth_year=substr(ID_CARD_NO,7,4)+0;
birth_mon=substr(ID_CARD_NO,11,2)+0;
birth_day=substr(ID_CARD_NO,13,2)+0;
birthdate=mdy(birth_mon,birth_day,birth_year);
age=Intck('year',birthdate,datepart(apply_time));
drop birth_mon birth_day birth_year;

/*年龄 age*/
format age_g $20.;
if age<18 then age_g="0.<18岁";
else if age>=18 and age<=25 then age_g="1.18-25岁";
else if age>25 and age<=30 then age_g="2.26-30岁";
else if age>30 and age<=35 then age_g="3.31-35岁";
else if age>35 and age<=40 then age_g="4.36-40岁";
else if age>40 and age<=45 then age_g="5.41-45岁";
else if age>45 and age<=55 then age_g="6.46-55岁";
else if age>55 and age<=60 then age_g="7.55-60岁";
else if age>60  then age_g="8.>60岁";
count=1;
/*子女个数 CHILD_COUNT*/
format CHILD_COUNT_G $20.;
if CHILD_COUNT=0 then CHILD_COUNT_G="0.无子女";
else if CHILD_COUNT=1 then CHILD_COUNT_G="1.1个子女";
else if CHILD_COUNT=2 then CHILD_COUNT_G="2.2个子女";
else if CHILD_COUNT>2 then CHILD_COUNT_G="3.2个以上子女";
/*本市生活时长 LOCAL_RES_YEARS*/
format LOCAL_RES_YEARS_G $20.;
if LOCAL_RES_YEARS>=0 and LOCAL_RES_YEARS<1 then LOCAL_RES_YEARS_G="0.不满1年";
else if LOCAL_RES_YEARS>=1 and LOCAL_RES_YEARS<3 then LOCAL_RES_YEARS_G="1.1-<3年";
else if LOCAL_RES_YEARS>=3 and LOCAL_RES_YEARS<5 then LOCAL_RES_YEARS_G="2.3-<5年";
else if LOCAL_RES_YEARS>=5 and LOCAL_RES_YEARS<10 then LOCAL_RES_YEARS_G="3.5-<10年";
else if LOCAL_RES_YEARS>=10 and LOCAL_RES_YEARS<20 then LOCAL_RES_YEARS_G="4.10-<20年";
else if LOCAL_RES_YEARS>=20 then LOCAL_RES_YEARS_G="5.20+年";
/*工作变动次数 WORK_CHANGE_TIMES*/
format  WORK_CHANGE_TIMES_G $20.;
if WORK_CHANGE_TIMES=0 then WORK_CHANGE_TIMES_G="0.无变动";
else if WORK_CHANGE_TIMES=1 then WORK_CHANGE_TIMES_G="1.1次变动";
else if WORK_CHANGE_TIMES=2 then WORK_CHANGE_TIMES_G="2.2次变动";
else if WORK_CHANGE_TIMES>=3 then WORK_CHANGE_TIMES_G="3.3次及以上变动";
/*工作年限 work_years*/
format work_years_g $20.;
if work_years=0  then work_years_g="0.无参加工作";
else if work_years<1 then work_years_g="1.工作不满1年";
else if work_years<3 then work_years_g="2.工作1-<3年";
else if work_years<5 then work_years_g="3.工作3-<5年";
else if work_years<10 then work_years_g="4.工作5-<10年";
else if work_years<20 then work_years_g="5.工作10-<20年";
else if work_years>=20 then work_years_g="6.工作20年以上";
/*房产套数 HOURSE_COUNT*/
format HOURSE_COUNT_G $20.;
if HOURSE_COUNT=0 then HOURSE_COUNT_G="0.无房产";
else if HOURSE_COUNT=1 then HOURSE_COUNT_G="1.1套房产";
else if HOURSE_COUNT=2 then HOURSE_COUNT_G="2.2套房产";
else if HOURSE_COUNT>=3 then HOURSE_COUNT_G="3.3套以上房产";
/*汽车数量 CAR_COUNT*/;
format CAR_COUNT_G $20.;
if CAR_COUNT=0 then CAR_COUNT_G="0.无汽车";
else if CAR_COUNT=1 then CAR_COUNT_G="1.1辆汽车";
else if CAR_COUNT>=2 then CAR_COUNT_G="2.2辆及以上汽车";
/*总保额 INSURANCE_INSURED_PRICE*/
format INSURANCE_INSURED_PRICE_G $20.;
if INSURANCE_INSURED_PRICE=0 or INSURANCE_INSURED_PRICE=. then INSURANCE_INSURED_PRICE_G="0.无参保";
else if INSURANCE_INSURED_PRICE<=50000 then INSURANCE_INSURED_PRICE_G="1.总保额1-5万";
else if INSURANCE_INSURED_PRICE<=100000 then INSURANCE_INSURED_PRICE_G="2.总保额6-10万";
else if INSURANCE_INSURED_PRICE<=500000 then INSURANCE_INSURED_PRICE_G="3.总保额11-50万";
else if INSURANCE_INSURED_PRICE<=1000000 then INSURANCE_INSURED_PRICE_G="4.总保额51-100万";
else if INSURANCE_INSURED_PRICE<=2000000 then INSURANCE_INSURED_PRICE_G="5.总保额101-200万";
else if INSURANCE_INSURED_PRICE<=5000000 then INSURANCE_INSURED_PRICE_G="6.总保额201-500万";
else if INSURANCE_INSURED_PRICE>5000000 then INSURANCE_INSURED_PRICE_G="7.总保额>500万";
/*收入 VERIFY_INCOME*/
format VERIFY_INCOME_G $20.;
if VERIFY_INCOME<=0 or VERIFY_INCOME=. then VERIFY_INCOME_G="0.无核实收入";
else if VERIFY_INCOME<3000 then VERIFY_INCOME_G="1.<3000元";
else if VERIFY_INCOME<5000 then VERIFY_INCOME_G="2.3000-<5000元";
else if VERIFY_INCOME<8000 then VERIFY_INCOME_G="3.5000-<8000元";
else if VERIFY_INCOME<10000 then VERIFY_INCOME_G="4.8000-<10000元";
else if VERIFY_INCOME<20000 then VERIFY_INCOME_G="5.10000-<20000元";
else if VERIFY_INCOME<30000 then VERIFY_INCOME_G="6.20000-<30000元";
else if VERIFY_INCOME<50000 then VERIFY_INCOME_G="7.30000-<50000元";
else if VERIFY_INCOME<100000 then VERIFY_INCOME_G="8.50000-<100000元";
else if VERIFY_INCOME>=100000 then VERIFY_INCOME_G="9.>=100000元";
/*负债率 RATIO*/
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

/*居住地与户籍关系*/
format RES_Type $20.;
if RESIDENCE_CITY=PERMANENT_ADDR_CITY then Res_Type="1.居住地为户籍本市";
else if RESIDENCE_PROVINCE=PERMANENT_ADDR_PROVINCE then Res_Type="2.居住地为户籍本省";
else if RESIDENCE_PROVINCE ne PERMANENT_ADDR_PROVINCE then Res_Type="3.居住地为非户籍省";
/*信用卡张数 未结清信用卡账户数*/
format credit_card_g $20.;
if 未结清信用卡账户数=0 then credit_card_g="0.无";
else if 未结清信用卡账户数=. then credit_card_g="Missing";
else if 未结清信用卡账户数=1 then credit_card_g="1.1个";
else if 未结清信用卡账户数=2 then credit_card_g="2.2个";
else if 未结清信用卡账户数=3 then credit_card_g="3.3个";
else if 未结清信用卡账户数<=5 then credit_card_g="4.4-5个";
else if 未结清信用卡账户数<=10 then credit_card_g="5.6-10个";
else if 未结清信用卡账户数<=20 then credit_card_g="6.11-20个";
else if 未结清信用卡账户数>20 then credit_card_g="7.20个";
/*未结清抵押贷款数量*/
format secured_cnt_g $20.;
if 未结清抵押贷款数量=0 then secured_cnt_g="0.无抵押贷款";
else if 未结清抵押贷款数量=. then secured_cnt_g="Missing";
else if 未结清抵押贷款数量=1 then secured_cnt_g="1.1个抵押贷款";
else if 未结清抵押贷款数量=2 then secured_cnt_g="2.2个抵押贷款";
else if 未结清抵押贷款数量>=3 then secured_cnt_g="3.3个及以上抵押贷款";
/*未结清消费贷款数量*/
format unsecured_cnt_g $20.;
if 未结清消费贷款数量=0 then unsecured_cnt_g="0.无消费贷款";
else if 未结清消费贷款数量=. then unsecured_cnt_g="Missing";
else if 未结清消费贷款数量=1 then unsecured_cnt_g="1.1个消费贷款";
else if 未结清消费贷款数量=2 then unsecured_cnt_g="2.2个消费贷款";
else if 未结清消费贷款数量=3 then unsecured_cnt_g="3.3个消费贷款";
else if 未结清消费贷款数量>3 and 未结清消费贷款数量<=5 then unsecured_cnt_g="4.4-5个消费贷款";
else if 未结清消费贷款数量>5 and 未结清消费贷款数量<=10 then unsecured_cnt_g="5.5-10个消费贷款";
else if 未结清消费贷款数量>10 then unsecured_cnt_g="6.10个以上消费贷款";
/*未结清其他贷款数量*/
format otherloan_cnt_g $20.;
if 未结清其他贷款数量=0 then otherloan_cnt_g="0.无其他贷款";
else if 未结清其他贷款数量=. then otherloan_cnt_g="Missing";
else if 未结清其他贷款数量=1 then otherloan_cnt_g="1.1个其他贷款";
else if 未结清其他贷款数量=2 then otherloan_cnt_g="2.2个其他贷款";
else if 未结清其他贷款数量=3 then otherloan_cnt_g="3.3个其他贷款";
else if 未结清其他贷款数量>3 and 未结清其他贷款数量<=5 then otherloan_cnt_g="4.4-5个其他贷款";
else if 未结清其他贷款数量>5 and 未结清其他贷款数量<=10 then otherloan_cnt_g="5.5-10个其他贷款";
else if 未结清其他贷款数量>10 then otherloan_cnt_g="6.10个以上其他贷款";
/*近3个月查询次数*/
format querry_L3M_g $20.;
if 近3个月查询次数=0 then querry_L3M_g="0.无查询";
else if 近3个月查询次数=. then querry_L3M_g="Missing";
else if 近3个月查询次数=1 then querry_L3M_g="1.1次查询";
else if 近3个月查询次数=2 then querry_L3M_g="2.2次查询";
else if 近3个月查询次数=3 then querry_L3M_g="3.3次查询";
else if 近3个月查询次数>3  and 近3个月查询次数<=5 then querry_L3M_g="4.4-5次查询";
else if 近3个月查询次数>5  and 近3个月查询次数<=10 then querry_L3M_g="5.6-10次查询";
else if 近3个月查询次数>10  and 近3个月查询次数<=20 then querry_L3M_g="6.11-20次查询";
else if 近3个月查询次数>20  then querry_L3M_g="7.20次以上查询";
/*近6个月信用卡申请被拒次数*/
format CReject_L6M_g $20.;
if 近6个月信用卡申请被拒次数=. then CReject_L6M_g="Missing";
else if 近6个月信用卡申请被拒次数<=0 then CReject_L6M_g="0.无被拒";
else if 近6个月信用卡申请被拒次数=1 then CReject_L6M_g="1.1次被拒";
else if 近6个月信用卡申请被拒次数=2 then CReject_L6M_g="2.2次被拒";
else if 近6个月信用卡申请被拒次数=3 then CReject_L6M_g="3.3次被拒";
else if 近6个月信用卡申请被拒次数=4 then CReject_L6M_g="4.4次被拒";
else if 近6个月信用卡申请被拒次数>4 and 近6个月信用卡申请被拒次数<=10 then CReject_L6M_g="5.5-10次被拒";
else if 近6个月信用卡申请被拒次数>10 then CReject_L6M_g="6.10次以上被拒";
/*信用卡使用率*/
format cc_useage_g $20.;
if 信用卡使用率=0 then cc_useage_g="0.0%";
else if 信用卡使用率=. then cc_useage_g="Missing";
else if 信用卡使用率<0.3 then cc_useage_g="1.<30%";
else if 信用卡使用率<0.5 then cc_useage_g="2.30-<50%";
else if 信用卡使用率<0.6 then cc_useage_g="3.50-<60%";
else if 信用卡使用率<0.7 then cc_useage_g="4.60-<70%";
else if 信用卡使用率<0.8 then cc_useage_g="5.70-<80%";
else if 信用卡使用率<0.9 then cc_useage_g="6.80-<90%";
else if 信用卡使用率<1 then cc_useage_g="7.90-<100%";
else if 信用卡使用率>=1 then cc_useage_g="8.100%+";
/*近2年查询次数*/
format querry_L2Y_g $20.;
if 近2年查询次数=0 then querry_L2Y_g="0.无查询";
else if 近2年查询次数=. then querry_L2Y_g="Missing";
else if 近2年查询次数<12 then querry_L2Y_g="1.1-<12次查询";
else if 近2年查询次数<24 then querry_L2Y_g="2.12-<24次查询";
else if 近2年查询次数<36 then querry_L2Y_g="3.24-<36次查询";
else if 近2年查询次数<48 then querry_L2Y_g="4.37-<48次查询";
else if 近2年查询次数<60 then querry_L2Y_g="5.49-<60次查询";
else if 近2年查询次数>=60 then querry_L2Y_g="6.60次以上查询";
format 批核金额_终审_G $20.;
if 批核金额_终审<=0 or 批核金额_终审=. then 批核金额_终审_G="批核不通过";
else if 批核金额_终审<20000 then 批核金额_终审_G="1.<20000元";
else if 批核金额_终审<30000 then 批核金额_终审_G="2.20000-<30000元";
else if 批核金额_终审<40000 then 批核金额_终审_G="3.30000-<40000元";
else if 批核金额_终审<50000 then 批核金额_终审_G="4.40000-<50000元";
else if 批核金额_终审<80000 then 批核金额_终审_G="5.50000-<80000元";
else if 批核金额_终审>=80000 then 批核金额_终审_G="6.>=80000元";

format 职业 $20.;
if COMP_TYPE in ("160","161") then 职业="公务员/事业单位";
else  职业="公司职员";
/*天启、集奥、融360*/
format TQ_code $20.;
if TQ_score=. then TQ_code="z-Missing";
else if TQ_score<=467 then TQ_code="E";
else if TQ_score<=543 then TQ_code="D";
else if TQ_score<=619 then TQ_code="C";
else if TQ_score<=714 then TQ_code="B";
else if TQ_score>=715 then TQ_code="A";

format TQ_BLACK $20.;
if TQ_B=. then TQ_black="z-Missing";
else if TQ_B=0 then TQ_black="否";
else if TQ_B=1 then TQ_black="是";

format r360_black $20.;
if r360_B=. then r360_black="z-Missing";
else if r360_B=0 then r360_black="否";
else if r360_B=1 then r360_black="是";

format JA_work $20.;
     if JA_w="01"  then JA_work="1.<-2km";
else if JA_w="02"  then JA_work="2.2<-5km";
else if JA_w="03"  then JA_work="3.5<-10km";
else if JA_w="04"  then JA_work="4.同城市，10km以上";
else if JA_w="05"  then JA_work="5.不同城市";
else if JA_w="99"  then JA_work="6.手机已离网";
else JA_work="z-Missing";

format JA_rest $20.;
     if JA_r="01"  then JA_rest="1.<-2km";
else if JA_r="02"  then JA_rest="2.2<-5km";
else if JA_r="03"  then JA_rest="3.5<-10km";
else if JA_r="04"  then JA_rest="4.同城市，10km以上";
else if JA_r="05"  then JA_rest="5.不同城市";
else if JA_r="99"  then JA_rest="6.手机已离网";
else JA_rest="z-Missing";
run;




/*需要增加中文解释的参数*/

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
  datafile='D:\share\线下demo\input\CN_variable.csv'
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
if kindex(risk_level,"低") then risk_level_2="01.低";
else if kindex(risk_level,"中") then risk_level_2="02.中";
else if kindex(risk_level,"高") then risk_level_2="03.高";

format product_code  pproduct_code $20.;
if approve_产品 in ("E保通","Ebaotong") then product_code="E保通";
	else if approve_产品 in ("E房通","Efangtong") then product_code="E房通";
	else if approve_产品 in ("E社通","Eshetong") then product_code="E社通";
	else if approve_产品 in ("E网通","Ewangtong") then product_code="E网通";
	else if approve_产品 in ("Elite","U贷通","TYElite","同业贷U贷通") then product_code="U贷通";
	else if approve_产品 in ("Salariat","E贷通","TYSalariat","同业贷E贷通") then product_code="E贷通";
	else if approve_产品 in ("RFEbaotong","RFE保通") then product_code="E保通续贷";
	else if approve_产品 in ("RFEwangtong","RFE网通") then product_code="E网通续贷";
	else if approve_产品 in ("RFEshetong","RFE社通") then product_code="E社通续贷";
	else if approve_产品 in ("RFSalariat","RFE贷通") then product_code="E贷通续贷";
	else if approve_产品 in ("RFElite","RFU贷通") then product_code="U贷通续贷";
	else if approve_产品 in ("Eweidai","E微贷") then product_code="E微贷";
	else if approve_产品 in ("Ezhaitong","E宅通") then product_code="E宅通";
	else if approve_产品 in ("Ebaotong-zigu","E保通-自雇") then product_code="E保通-自雇";
	else if approve_产品 in ("Ezhaitong-zigu","E宅通-自雇") then product_code = "E宅通-自雇";
	else if approve_产品 in ("Easy-CreditCard","Easy贷信用卡") then product_code = "Easy贷信用卡";
	else if approve_产品 in ("Easy-ZhiMa","Easy贷芝麻分") then product_code = "Easy贷芝麻分";

if 进件日期>=mdy(3,1,2018) then do;
if hire=1 then do;
if product_code="E保通" then product_code1="E保通-自雇";
else if product_code="E房通" then product_code1="E房通-自雇";
else if product_code="E社通" then product_code1="E社通-自雇";
else if product_code in ("E微贷","") then product_code1="E微贷-自雇";
else if product_code="E宅通" then product_code1="E宅通-自雇";
end;
else if SOCIAL_SECURITY=0 then do;
if product_code="E保通" then product_code1="E保通-无社保";
else if product_code="E房通" then product_code1="E房通-无社保";
else if product_code="E社通" then product_code1="E社通-无社保";
else if product_code="E微贷" then product_code1="E微贷-无社保";
else if product_code="E宅通" then product_code1="E宅通-无社保";
end;
end;

if kindex(DESIRED_PRODUCT,"RF") and not kindex(product_code,"续贷") then pproduct_code=compress(product_code||"续贷") ;
if pproduct_code^="" then product_code=pproduct_code;


run;

data use;
set DemoFin.use_&work_day.;
run;

option noxwait;
/*x md "D:\songts\workteam\黄玉州\报表交接\to zhipei\Demographics\output\&work_Day.";*/
