*--------------------------- 准备工作 ---------------------------*
clear all
set more off
set seed 123  // 设置随机种子（确保结果可复现）

* 加载面板数据（替换为你的数据路径）
use "your_panel_data.dta", clear

* 变量重命名（根据实际数据调整）
rename 供应链稳定性 scs       // 内生解释变量（当期）
rename 资产收益率 ar           // 被解释变量
rename 企业规模 size           // 控制变量（如总资产对数）
rename 资产负债率 lev           // 控制变量（资产负债率）
rename 行业代码 industry       // 行业变量（如两位数代码）
rename 年份 year               // 时间变量
rename 企业ID id               // 企业唯一标识（面板数据需声明）


*--------------------------- 步骤1：面板数据预处理 ---------------------------*
xtset id year  // 声明面板数据结构（个体ID和时间）


*--------------------------- 步骤2：生成工具变量 ---------------------------*
* 工具变量1：SCS滞后一期（scs_lag1）
gen scs_lag1 = L.SCS  // 生成滞后一期的SCS（L.表示前一期）
label variable scs_lag1 "供应链稳定性滞后一期（工具变量）"

* 工具变量2：行业SCS均值（ind_scs_mean）
egen ind_scs_mean = mean(SCS), by(industry year)  // 按行业和年份分组计算当期SCS均值
label variable ind_scs_mean "行业-年度供应链稳定性均值（工具变量）"

* 剔除缺失值（滞后一期导致的首年缺失+工具变量缺失）
drop if missing(scs_lag1, ind_scs_mean, ar, size, lev)


*--------------------------- 步骤3：两阶段最小二乘（2SLS）回归 ---------------------------*
* 模型设定：ar = β0 + β1*scs + β2*size + β3*lev + ε（scs为内生变量）
* 工具变量：scs_lag1（滞后一期）、ind_scs_mean（行业-年度均值）

* 使用ivreg2命令（支持高级检验）
ssc install ivreg2, replace  // 安装ivreg2（若未安装）
ivreg2 AR (SCS = scs_lag1 ind_scs_mean) IC ROA Size Top1 FN list inventory big4 GDP, robust  // robust：异方差稳健标准误

* 保存回归结果
eststo iv_model: ivreg2 AR (SCS = scs_lag1 ind_scs_mean) IC ROA Size Top1 FN list inventory big4 GDP, robust


*--------------------------- 步骤4：弱工具变量检验（关键！） ---------------------------*
* 输出第一阶段结果及弱工具检验统计量
estat firststage, all

/* 关键指标解读：
   - Cragg-Donald Wald F统计量：若F > 10（经验阈值），工具变量不弱；
   - Partial R²：工具变量对内生变量的解释力（排除控制变量后），越高越好；
   - 第一阶段系数：scs_lag1和ind_scs_mean的系数应显著（p<0.05）。
*/


*--------------------------- 步骤5：内生性检验（是否需要IV） ---------------------------*
* 执行Wu-Hausman检验（原假设：scs外生，无需IV）
estat endogenous

/* 关键指标解读：
   - F统计量或chi2统计量：若p值 < 0.05，拒绝原假设，说明存在内生性，必须用IV。
*/


*--------------------------- 步骤6：外生性检验（过度识别检验） ---------------------------*
* 由于使用了2个工具变量（scs_lag1、ind_scs_mean）估计1个内生变量（scs），属于过度识别，可检验外生性
estat overid  // Sargan检验（原假设：所有工具变量外生）

/* 关键指标解读：
   - Sargan chi2统计量：若p值 > 0.05，不拒绝原假设，工具变量外生。
*/


*--------------------------- 步骤7：结果输出与汇总 ---------------------------*
* 输出IV回归结果（系数、标准误、p值）
esttab iv_model using "iv_reg_result.rtf", replace ///
    cells(b(3) se(3) p(3)) star(* 0.1 ** 0.05 *** 0.01) ///
    title("双工具变量（滞后一期+行业均值）的2SLS回归结果") ///
    note("工具变量：scs_lag1、ind_scs_mean；*p<0.1, **p<0.05, ***p<0.01")

* 简化查看系数和显著性
est tab iv_model, b(a3) se(a3)

---------------------------------------------------------------------------------------
*--------------------------- 准备工作 ---------------------------*
clear all
set more off
set seed 123  // 确保结果可复现

* 加载面板数据（替换为你的数据路径）
use "your_panel_data.dta", clear

* 变量重命名（根据实际数据调整）
rename 供应链稳定性 scs          // 内生变量（企业层面）
rename 资产收益率 ar              // 结果变量（如企业绩效）
rename 企业规模 size              // 控制变量（总资产对数）
rename 资产负债率 lev             // 控制变量（负债/资产）
rename 行业代码 industry          // 行业变量（如两位数代码）
rename 年份 year                  // 时间变量
rename 企业ID id                  // 企业唯一标识


*--------------------------- 步骤1：生成工具变量（行业-年度SCS均值） ---------------------------*
* 按行业和年份分组，计算企业SCS的均值（工具变量）
egen ind_scs_mean = mean(scs), by(industry year)  
label variable ind_scs_mean "行业-年度供应链稳定性均值（工具变量）"

* 剔除缺失值（工具变量或核心变量缺失）
drop if missing(scs, ind_scs_mean, ar, size, lev)


*--------------------------- 步骤2：两阶段最小二乘（2SLS）回归 ---------------------------*
* 使用ivreg2命令（支持高级检验，优于内置的ivregress）
ssc install ivreg2, replace  // 安装ivreg2（若未安装）

* 执行2SLS回归（恰好识别：1个工具变量，1个内生变量）
ivreg2 ar (scs = ind_scs_mean) size lev, robust  // robust：异方差稳健标准误

* 保存回归结果
eststo iv_model: ivreg2 ar (scs = ind_scs_mean) size lev, robust


*--------------------------- 步骤3：关键检验 ---------------------------*
* 1. 弱工具检验（Cragg-Donald F统计量）
estat firststage, all  // 输出第一阶段结果及F统计量

* 2. 内生性检验（Wu-Hausman检验）
estat endogenous  // 原假设：scs外生（无需IV）

* 3. 外生性检验（恰好识别时无法检验，需理论论证）
* 注：本例工具变量数=1，内生变量数=1（恰好识别），无过度识别约束，无法用Hansen J检验


*--------------------------- 步骤4：结果输出 ---------------------------*
* 输出2SLS回归结果（系数、标准误、p值）
esttab iv_model using "iv_result.rtf", replace ///
    cells(b(3) se(3) p(3)) star(* 0.1 ** 0.05 *** 0.01) ///
    title("行业SCS均值作为IV的2SLS回归结果") ///
    note("工具变量：行业-年度SCS均值；*p<0.1, **p<0.05, ***p<0.01")

* 简化查看系数和显著性
est tab iv_model, b(a3) se(a3)
————————————————————————————————————————————————————————————————————————————————————

*--------------------------- 步骤1：声明面板结构并生成工具变量 ---------------------------*
xtset id year  // 声明面板数据（个体ID和时间变量）

* 步骤1.1：生成行业t期SCS均值（用于后续滞后）
egen ind_scs_current = mean(scs), by(industry year)  // 行业j在t期的SCS均值
label variable ind_scs_current "行业-年度SCS均值（t期）"

* 步骤1.2：生成行业SCS滞后一期（t-1期）
gen ind_scs_lag1 = L.ind_scs_current  // 行业j在t-1期的SCS均值（L.表示前一期）
label variable ind_scs_lag1 "行业-年度SCS滞后一期（t-1期，工具变量）"

* 步骤1.3：剔除缺失值（滞后导致的首年缺失+核心变量缺失）
drop if missing(scs, ind_scs_lag1, ar, size, lev)  // 确保t≥2期有数据


*--------------------------- 步骤2：两阶段最小二乘（2SLS）回归 ---------------------------*
* 使用ivreg2命令（支持高级检验）
ssc install ivreg2, replace  // 安装ivreg2（若未安装）

* 执行2SLS回归（恰好识别：1个工具变量，1个内生变量）
ivreg2 AR (SCS = ind_scs_lag1) IC ROA Size Top1 FN list inventory big4 GDP, robust  // robust：异方差稳健标准误

* 保存回归结果
eststo iv_model: ivreg2 AR (SCS = ind_scs_lag1) IC ROA Size Top1 FN list inventory big4 GDP, robust


*--------------------------- 步骤3：关键检验 ---------------------------*
* 3.1 弱工具检验（判断工具变量与内生变量的相关性）
estat firststage, all  // 输出第一阶段结果及Cragg-Donald F统计量

* 3.2 内生性检验（判断是否需要IV）
estat endogenous  // Wu-Hausman检验（原假设：scs外生，无需IV）


*--------------------------- 步骤4：结果输出 ---------------------------*
* 输出2SLS回归结果（系数、标准误、p值）
esttab iv_model using "iv_result.rtf", replace ///
    cells(b(3) se(3) p(3)) star(* 0.1 ** 0.05 *** 0.01) ///
    title("行业SCS滞后一期作为IV的2SLS回归结果") ///
    note("工具变量：行业t-1期SCS均值；*p<0.1, **p<0.05, ***p<0.01")

——————————————————————————————————————————————————————————————————————————————————————

* 安装必要命令
ssc install ivreg2, replace   // 安装增强版2SLS命令
ssc install ranktest, replace  // 安装工具变量检验命令

* 步骤1: 准备工具变量
* 生成行业平均SCS
bysort industry year: egen ind_avg_scs = mean(SCS)

* 生成滞后一期的行业SCS作为工具变量
sort id year
by id: gen L1_ind_scs = ind_avg_scs[_n-1]  // 滞后一期

* 确保工具变量外生性：行业层面变量不直接影响企业层面AR
label var L1_ind_scs "行业滞后SCS(工具变量)"

* 步骤2: 工具变量相关性检验
reg SCS L1_ind_scs IC ROA Size Top1 FN list inventory big4 GDP 
estat firststage  // 第一阶段检验

* 步骤3: 两阶段最小二乘估计(2SLS)
ivreg2 AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
   first         // 显示第一阶段结果 ///
   vce(robust)        // 稳健标准误 ///
   partial(IC ROA Size Top1 FN list inventory big4 GDP) // 控制变量 ///
   endog(SCS)    // 明确内生变量

* 步骤4: 工具变量有效性检验
* (a) 弱工具变量检验
estat firststage  // Cragg-Donald Wald F统计量应>10(理想>16.38)

* (b) 过度识别检验(因模型恰好识别，无法进行Sargan检验)
di "工具变量数=内生变量数，模型恰好识别"

* 步骤5: 控制固定效应(使用ivreghdfe)
ssc install ivreghdfe, replace
ivreghdfe AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
   absorb(year industry)   // 控制年度和行业固定效应 ///
   robust                   // 聚类稳健标准误 ///
   first                   // 显示第一阶段结果

* 步骤6: 结果输出
estimates store IV_Result
esttab IV_Result, b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
   keep(SCS) stats(N F, fmt(0 2)) title("2SLS估计结果: SCS对AR的影响")

* 步骤7: 对比OLS结果(作为参照)
reghdfe AR SCS IC ROA Size Top1 FN list inventory big4 GDP, ///
   absorb(year industry) vce(robust)
estimates store OLS_Result
esttab OLS_Result IV_Result, ///
   b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
   keep(SCS) stats(N F, fmt(0 2)) ///
   mtitles("OLS" "2SLS") title("SCS对AR的影响: OLS与2SLS对比")





* 工具变量法(IV)分析完整代码
* 适用于处理内生性问题的两阶段最小二乘估计(2SLS)

*******************************************************************************
* 1. 准备工作
*******************************************************************************
* 清除内存数据
clear all
* 清除屏幕
cls
* 设置种子确保结果可重复
set seed 12345

* 安装必要命令（首次运行时需要）
ssc install ivreg2, replace      // 增强版2SLS估计命令
ssc install ivreghdfe, replace   // 支持高维固定效应的IV命令
ssc install ftools, replace      // ivreghdfe依赖包
ssc install reghdfe, replace     // 高维固定效应基础命令
ssc install esttab, replace      // 结果输出命令

*******************************************************************************
* 2. 数据准备与工具变量构建
*******************************************************************************
* 假设已加载数据，如有需要可使用use命令加载
* use "你的数据路径.dta", clear

* 2.1 检查内生变量和工具变量相关变量是否存在
describe SCS AR L1_ind_scs industry year id  // 替换为你的变量名

* 2.2 构建工具变量（以滞后一期行业均值为例）
* 生成排除自身的行业平均SCS
bysort industry year: egen ind_avg_scs = mean(SCS)
bysort industry year: gen N = _N  // 行业内企业数量
gen ind_avg_scs_excl = (ind_avg_scs * N - SCS) / (N - 1)  // 排除自身影响

* 生成滞后一期的行业平均作为工具变量
sort industry year
bysort industry: gen L1_ind_scs = ind_avg_scs_excl[_n-1]  // 行业层面滞后一期

* 处理滞后项缺失值
bysort industry: replace L1_ind_scs = . if _n == 1  // 每个行业第一年无滞后值

* 标签工具变量
label var L1_ind_scs "滞后一期行业平均SCS(排除自身)"

*******************************************************************************
* 3. 工具变量相关性检验（第一阶段回归）
*******************************************************************************
* 3.1 第一阶段回归：内生变量对工具变量和控制变量
reg SCS L1_ind_scs IC ROA Size Top1 FN list inventory big4 GDP
* 查看结果中工具变量L1_ind_scs的系数显著性
* 关键：系数应显著，表明工具变量与内生变量相关

* 3.2 计算第一阶段F统计量（判断是否为弱工具变量）
test L1_ind_scs  // 检验工具变量系数是否为0
* 结果中F统计量应>10，越大说明工具变量越强

*******************************************************************************
* 4. 两阶段最小二乘估计(2SLS)
*******************************************************************************
* 4.1 基础2SLS模型（无固定效应）
ivreg2 AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
    first           // 显示第一阶段结果
    cluster(id)     // 按个体聚类的稳健标准误
    endog(SCS)      // 明确指定内生变量

ivreg2 AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
    first cluster(id) endog(SCS) 
	
* 5.1 含固定效应的2SLS估计
ivreg2 d_AR (d_SCS = d_L1_ind_scs) d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, ///
    first savefirst  cluster(id) endog(d_SCS)     // 明确内生变量	
	
* 4.2 含固定效应的2SLS模型（推荐用于面板数据）
ivreghdfe AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
    absorb(industry year)  // 控制行业和年份固定效应
    first                  // 显示第一阶段结果
    cluster(id)            // 按个体聚类的稳健标准误
    verbose                // 显示详细运行信息

ivreghdfe AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
    absorb(industry year) first cluster(id)
	
	)*******************************************************************************
* 5. 工具变量有效性检验
*******************************************************************************
* 5.1 弱工具变量检验
estat firststage, all forcenonrobust
* 关键指标：Cragg-Donald Wald F统计量>10（拒绝弱工具变量假设）

* 5.2 过度识别检验（仅当工具变量数量>内生变量数量时可用）
* 若有多个工具变量，可运行：
* estat overid   // 原假设：所有工具变量均为外生

* 5.3 内生性检验（比较OLS和IV结果差异）
* 先估计OLS模型
reghdfe AR SCS IC ROA Size Top1 FN list inventory big4 GDP, ///
    absorb(industry year) cluster(id)
    
* 存储结果并比较
estimates store OLS_Result
ivreghdfe AR (SCS = L1_ind_scs) IC ROA Size Top1 FN list inventory big4 GDP, ///
    absorb(industry year) cluster(id)
estimates store IV_Result

* 输出对比结果
esttab OLS_Result IV_Result, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    keep(SCS) stats(N r2_a, fmt(0 3)) ///
    mtitles("OLS" "2SLS") ///
    title("OLS与2SLS估计结果对比") ///
    note("标准误：按id聚类稳健标准误")

*******************************************************************************
* 6. 结果导出
*******************************************************************************
* 导出到Excel
esttab OLS_Result IV_Result using iv_results.csv, ///
    replace b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    keep(SCS) stats(N r2_a, fmt(0 3)) ///
    mtitles("OLS" "2SLS")


* 完整工具变量法(IV)分析代码
* 方法：离差法控制固定效应 + ivreg2估计（规避ivreghdfe问题）

*******************************************************************************
* 1. 准备工作与命令安装
*******************************************************************************
clear all
cls
set seed 12345

* 安装必要命令
ssc install ivreg2, replace
ssc install esttab, replace

*******************************************************************************
* 2. 数据准备与工具变量构建
*******************************************************************************
* 假设数据已加载，若未加载请使用：
* use "你的数据路径.dta", clear

* 2.1 检查面板数据结构
duplicates drop id year, force  // 确保id-year唯一
xtset id year  // 设定面板数据（个体id，时间year）

* 2.2 构建工具变量：滞后一期行业平均SCS（排除自身）
* 生成行业-年份平均值
bysort industry year: egen ind_avg_scs = mean(SCS)
bysort industry year: gen N = _N  // 行业内企业数量
gen ind_avg_scs_excl = (ind_avg_scs * N - SCS) / (N - 1)  // 排除自身影响

* 生成滞后一期行业平均值（工具变量）
sort industry year
bysort industry: gen L1_ind_scs = ind_avg_scs_excl[_n-1]
bysort industry: replace L1_ind_scs = . if _n == 1  // 行业第一年无滞后值

* 2.3 剔除关键变量缺失值
drop if missing(AR, SCS, L1_ind_scs, industry, year, id)
drop if missing(IC, ROA, Size, Top1, FN, list, inventory, big4, GDP)

*******************************************************************************
* 3. 离差法处理固定效应（消除个体固定效应）
*******************************************************************************
* 3.1 对所有变量进行离差化（原始值 - 个体内均值）
foreach var in AR SCS L1_ind_scs IC ROA Size Top1 FN list inventory big4 GDP {
    bysort id: egen mean_`var' = mean(`var')  // 计算个体时间平均值
    gen d_`var' = `var' - mean_`var'  // 离差化变量（消除个体固定效应）
}

* 3.2 生成年份虚拟变量（控制年份固定效应）
tabulate year, gen(year_dum_)  // 生成year_dum_1, year_dum_2...

*******************************************************************************
* 4. 第一阶段检验（工具变量相关性）
*******************************************************************************
* 4.1 第一阶段回归：内生变量对工具变量+控制变量
reg d_SCS d_L1_ind_scs d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, ///
    cluster(id)
estimates store FirstStage_Result

* 4.2 关键统计量计算
* (1) 工具变量系数t值
display "工具变量t值: " _b[d_L1_ind_scs]/_se[d_L1_ind_scs]

* (2) 第一阶段F统计量（检验工具变量显著性）
test d_L1_ind_scs
display "第一阶段F统计量: " r(F)

* (3) 偏R²（工具变量解释力）
quietly reg d_SCS d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, cluster(id)
scalar r2_restricted = e(r2)
quietly reg d_SCS d_L1_ind_scs d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, cluster(id)
scalar r2_unrestricted = e(r2)
scalar partial_r2 = (r2_unrestricted - r2_restricted)/(1 - r2_unrestricted)
display "工具变量偏R²: " partial_r2

*******************************************************************************
* 5. 第二阶段估计（2SLS）
*******************************************************************************
* 5.1 含固定效应的2SLS估计
ivreg2 d_AR (d_SCS = d_L1_ind_scs) d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, ///
    first savefirst  // first显示第一阶段结果，savefirst保存第一阶段
    cluster(id)      // 聚类稳健标准误
    endog(d_SCS)     // 明确内生变量
estimates store IV_Result

* 5.2 OLS估计（对比用）
reg d_AR d_SCS d_IC d_ROA d_Size d_Top1 d_FN d_list d_inventory d_big4 d_GDP year_dum_*, ///
    cluster(id)
estimates store OLS_Result

*******************************************************************************
* 6. 结果输出与对比
*******************************************************************************
* 6.1 第一阶段结果输出
esttab FirstStage_Result, b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    keep(d_L1_ind_scs) stats(N r2, fmt(0 3)) ///
    title("第一阶段回归结果（d_SCS对工具变量）")

* 6.2 OLS与2SLS对比
esttab OLS_Result IV_Result, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    keep(d_SCS) stats(N r2, fmt(0 3)) ///
    mtitles("OLS(固定效应)" "2SLS(固定效应)") ///
    title("OLS与2SLS估计结果对比") ///
    note("标准误：按id聚类稳健标准误；控制变量：IC、ROA等（未显示）")

* 6.3 导出结果到Excel
esttab OLS_Result IV_Result using iv_vs_ols_results.csv, ///
    replace b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    keep(d_SCS) stats(N r2, fmt(0 3)) ///
    mtitles("OLS(固定效应)" "2SLS(固定效应)")

