* 加载数据
use "/Users/hanhan/Desktop/汽车企业数据/data.dta", clear


* 数据标准化
egen min_idr = min(independent_director_ratio)
egen max_idr = max(independent_director_ratio)
gen z_idr = (independent_director_ratio - min_idr) / (max_idr - min_idr)

egen min_dr = min(debt_ratio)
egen max_dr = max(debt_ratio)
gen z_dr = (debt_ratio - min_dr) / (max_dr - min_dr)

egen min_rt = min(receivables_turnover)
egen max_rt = max(receivables_turnover)
gen z_rt = (receivables_turnover - min_rt) / (max_rt - min_rt)

egen min_li = min(lerner_index)
egen max_li = max(lerner_index)
gen z_li = (lerner_index - min_li) / (max_li - min_li)

* 计算比例矩阵
egen total_z_idr = total(z_idr)
gen proportion_z_idr = z_idr / total_z_idr

egen total_z_dr = total(z_dr)
gen proportion_z_dr = z_dr / total_z_dr

egen total_z_rt = total(z_rt)
gen proportion_z_rt = z_rt / total_z_rt

egen total_z_li = total(z_li)
gen proportion_z_li = z_li / total_z_li

* 计算熵值
gen entropy_z_idr = -proportion_z_idr * ln(proportion_z_idr + 1e-9)
egen total_entropy_z_idr = total(entropy_z_idr)
scalar entropy_z_idr = total_entropy_z_idr / _N

gen entropy_z_dr = -proportion_z_dr * ln(proportion_z_dr + 1e-9)
egen total_entropy_z_dr = total(entropy_z_dr)
scalar entropy_z_dr = total_entropy_z_dr / _N

gen entropy_z_rt = -proportion_z_rt * ln(proportion_z_rt + 1e-9)
egen total_entropy_z_rt = total(entropy_z_rt)
scalar entropy_z_rt = total_entropy_z_rt / _N

gen entropy_z_li = -proportion_z_li * ln(proportion_z_li + 1e-9)
egen total_entropy_z_li = total(entropy_z_li)
scalar entropy_z_li = total_entropy_z_li / _N

* 计算差异系数
scalar diff_z_idr = 1 - entropy_z_idr
scalar diff_z_dr = 1 - entropy_z_dr
scalar diff_z_rt = 1 - entropy_z_rt
scalar diff_z_li = 1 - entropy_z_li

* 计算权重
scalar total_diff = diff_z_idr + diff_z_dr + diff_z_rt + diff_z_li

scalar weight_z_idr = diff_z_idr / total_diff
scalar weight_z_dr = diff_z_dr / total_diff
scalar weight_z_rt = diff_z_rt / total_diff
scalar weight_z_li = diff_z_li / total_diff

* 计算综合风险评分
gen comp_risk_score = z_idr * weight_z_idr + z_dr * weight_z_dr + z_rt * weight_z_rt + z_li * weight_z_li

* 替换零值
replace comp_risk_score = 1e-9 if comp_risk_score == 0

* 导出综合风险评分
export delimited using "composite_risk_scores.csv", replace




*- 导入数据

  import 重新财报错报风险计算表.xlsx, first clear
  
*- 设定指标

// 正向指标
global positiveVar X1 X2 X3

// 负向指标
global negativeVar big4 audit_fee

*- 以下不用修改
global allVar $positiveVar $negativeVar

// 标准化正向指标
foreach v in $positiveVar {
    qui sum `v'
    gen z_`v' = (`v'-r(min))/(r(max)-r(min))
    replace z_`v' = 0.0001 if z_`v' == 0
}

// 标准化负向指标
foreach v in $negativeVar {
    qui sum `v'
    gen z_`v' = (r(max)-`v')/(r(max)-r(min))
    replace z_`v' = 0.0001 if z_`v' == 0
}

// 计算各指标比重
foreach v in $allVar {
    egen sum_`v' = sum(z_`v')
    gen p_`v' = z_`v' / sum_`v'
}

// 计算熵值
foreach v in $allVar {
    egen sump_`v' = sum(p_`v'*ln(p_`v'))
    gen e_`v' = -1 / ln(_N) * sump_`v'
}

// 计算信息效用值
foreach v in $allVar {
    gen d_`v' = 1 - e_`v'
}

// 计算各指标权重
egen sumd = rowtotal(d_*)
foreach v in $allVar {
    gen w_`v' = d_`v' / sumd
}

// 计算各样本的综合得分
foreach v in $allVar {
    gen score_`v' = w_`v' * z_`v'
}
egen score = rowtotal(score*)

drop z_* p_* e_* d_* sum*

