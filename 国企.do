* 步骤1：准备数据
* 确保已安装reghdfe：ssc install reghdfe, replace
use "your_dataset.dta", clear  // 加载数据集

* 步骤2：定义分组
gen is_SOE = (FN == 1) if !missing(FN)  // 国企虚拟变量
label var is_SOE "国有企业"
gen is_nonSOE = (FN != 1) if !missing(FN)  // 非国企虚拟变量
label var is_nonSOE "非国有企业"

* 步骤3：国企样本回归
reghdfe AR SCS IC ROA Size Top1 list big4 inventory  big4  GDP if is_SOE == 1, ///
    absorb(industry_dum* year_dum*) ///
    cluster(id)
est store a1  // 存储结果

* 步骤4：非国企样本回归
reghdfe AR SCS IC ROA Size Top1 list inventory  big4  GDP if is_nonSOE == 1, ///
    absorb(industry_dum* year_dum*) ///
    cluster(id)
est store a2  // 存储结果

* 步骤5：结果输出与比较
* 显示国企结果
estimates restore SOE_reg
estimates title: 国有企业回归结果
estimates display

* 显示非国企结果
estimates restore nonSOE_reg
estimates title: 非国有企业回归结果
estimates display

* 使用esttab输出专业表格
esttab SOE_reg nonSOE_reg, ///
    b(%9.4f) se(%9.4f) star(* 0.1 ** 0.05 *** 0.01) ///
    title("国企与非国企回归结果对比") ///
    mtitles("国有企业" "非国有企业") ///
    scalars(N r2) ///
    label

* 步骤6：系数差异检验（使用suest）
suest SOE_reg nonSOE_reg

* 检验关键变量系数是否显著不同
test [SOE_reg_mean]SCS = [nonSOE_reg_mean]SCS  // 检验SCS系数差异
test [SOE_reg_mean]IC = [nonSOE_reg_mean]IC    // 检验IC系数差异
test [SOE_reg_mean]ROA = [nonSOE_reg_mean]ROA  // 检验ROA系数差异


gen is_SOE = (FN == 1) if !missing(FN)  // 国企虚拟变量
label var is_SOE "国有企业"
gen is_nonSOE = (FN != 1) if !missing(FN)  // 非国企虚拟变量
label var is_nonSOE "非国有企业"

* 步骤3：国企样本回归
reghdfe AR SCS IC ROA Size Top1 list big4 inventory  big4 FN GDP if is_Pollute == 1, ///
    absorb(industry_dum* year_dum*) ///
    cluster(id)
est store a1  // 存储结果

* 步骤4：非国企样本回归
reghdfe AR SCS IC ROA Size Top1 list inventory  big4 FN GDP if is_nonPollute == 1, ///
    absorb(industry_dum* year_dum*) ///
    cluster(id)
est store a2  // 存储结果

reg2docx a1 a2 using 重污染非重污染.docx,replace b(%9.3f) t(%9.3f) scalars(N r2 F) title(表1重污染非重污染表) note(***p<0.01, **p<0.05, *p<0.10)
———————————————————————————————————————————————————————————————————————————————————————
reghdfe AR SCS IC ROA Size Top1 list inventory big4 GDP FN if pollute ==1, absorb(industry year) vce(cluster id)
est store a1
reghdfe AR SCS IC ROA Size Top1 list inventory big4 GDP FN if pollute!=1, absorb(industry year) vce(cluster id)
est store a2
reg2docx a1 a2 using 污染程度分组.docx,replace b(%9.3f) t(%9.3f) scalars(N r2 F) title(表1产权性质表) note(***p<0.01, **p<0.05, *p<0.10)
————————————————————————————————————————————————————————————————————————————————————————--
describe industry
encode industry, gen(industry_num)
gen FN_1 = (FN == 1)

gen FN_not_1 = (FN != 1)

gen pollute_1 = (pollute == 1)

gen pollute_not_1 = (pollute != 1)



* 2. 按Size年度中位数分组
*******************************************************************************
* 2.1 计算每年的Size中位数（按年度分组计算）
bysort year: egen size_median = median(Size)

* 2.2 定义分组变量
gen size_group = .
* 大规模组：Size大于等于年度中位数
replace size_group = 1 if Size >= size_median
* 小规模组：Size小于年度中位数
replace size_group = 0 if Size < size_median

reghdfe AR SCS IC ROA Size Top1 list inventory big4 GDP FN if size_group ==1, absorb(industry year) vce(cluster id)
est store a1
reghdfe AR SCS IC ROA Size Top1 list inventory big4 GDP FN if size_group!=1, absorb(industry year) vce(cluster id)
est store a2
reg2docx a1 a2 using 规模分组.docx,replace b(%9.3f) t(%9.3f) scalars(N r2 F) title(表1产权性质表) note(***p<0.01, **p<0.05, *p<0.10)











