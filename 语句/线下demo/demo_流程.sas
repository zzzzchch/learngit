/*各种个人信息的处理表格，包括征信、贷记卡、贷款、查询等*/
%include "D:\share\语句\线下demo\Aaa_generate_credit_variable.sas";

/*1、部分个人信息的处理表格
2、信息进行预处理、汇总等*/
%include "D:\share\语句\线下demo\1Demographics_db_2.sas";

/*产出TTD数据，输出表为demo_res_ttd_dde*/
%include "D:\share\语句\线下demo\2Demographics_TTD.sas";

/*产出NB的数量部分，输出表为demo_res_loan_dde*/
%include "D:\share\语句\线下demo\3Demographics_Loan.sas";


%include "D:\share\语句\线下demo\4Demographics_Approval_rate.sas";
%include "D:\share\语句\线下demo\5Demographics_active.sas";
%include "D:\share\语句\线下demo\6Demographics_ever15+.sas";
%include "D:\share\语句\线下demo\7Demographics_ever90+.sas";
;

