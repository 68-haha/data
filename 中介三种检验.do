* 步骤1：进行回归分析（替换 y, m, x 为实际变量名）
regress AR SCS          // 总效应模型
regress ESG SCS          // 路径a：X→M
regress AR ESG SCS        // 路径b：M→Y（控制X）

* 步骤2：提取系数和标准误（检查变量名）
* 确认第二个回归中的自变量名（通常是x）
local a = _b[SCS]      // 路径a系数
local sa = _se[SCS]    // 路径a标准误

* 确认第三个回归中的中介变量名（通常是m）
local b = _b[ESG]      // 路径b系数
local sb = _se[ESG]    // 路径b标准误

* 步骤3：检查是否成功获取值
di "a = `a', sa = `sa'"
di "b = `b', sb = `sb'"

* 第一步：X 对 M 的回归（计算 a 路径系数）
reg M X
local a = _b[X]       // X 对 M 的系数（a）
local se_a = _se[X]   // a 的标准误

* 第二步：X 和 M 对 Y 的回归（计算 b 路径系数）
reg Y X M
local b = _b[M]       // M 对 Y 的系数（b）
local se_b = _se[M]   // b 的标准误

* 计算间接效应（a*b）
local indirect = `a' * `b'





* 步骤4：计算中介效应（确保括号匹配）
if "`a'" != "" & "`b'" != "" {
    local ind_eff = `a' * `b'
    di "中介效应 = " %6.4f `ind_eff'
    
    // Sobel检验
    local se_sobel = sqrt((`a'^2 * `sb'^2) + (`b'^2 * `sa'^2))
    local z_sobel = `ind_eff'/`se_sobel'
    local p_sobel = 2*(1 - normal(abs(`z_sobel')))
    
    // Aroian检验
    local se_arorian = sqrt((`a'^2 * `sb'^2) + (`b'^2 * `sa'^2) + (`sa'^2 * `sb'^2))
    local z_arorian = `ind_eff'/`se_arorian'
    local p_arorian = 2*(1 - normal(abs(`z_arorian')))
    
    // Goodman检验
    local se_goodman = sqrt((`a'^2 * `sb'^2) + (`b'^2 * `sa'^2) - (`sa'^2 * `sb'^2))
    
    // 避免负方差错误
    if `se_goodman' > 0 {
        local z_goodman = `ind_eff'/`se_goodman'
        local p_goodman = 2*(1 - normal(abs(`z_goodman')))
    }
    else {
        local z_goodman = .
        local p_goodman = .
    }
    
    // 步骤5：显示结果
    di _n "==== 中介效应检验结果 ===="
    di "Sobel检验:   Z = " %6.3f `z_sobel'   ", p = " %6.4f `p_sobel'
    di "Aroian检验:  Z = " %6.3f `z_arorian' ", p = " %6.4f `p_arorian'
    di "Goodman检验: Z = " %6.3f `z_goodman' ", p = " %6.4f `p_goodman'
}
else {
    di "错误：未能获取系数值，请检查变量名"
}
--------------------------------------------------------------------------------
* 中介效应检验：SCS → ESG → AR
* 确保变量存在且无缺失值
capture confirm variable SCS ESG AR
if _rc {
    di as error "变量 SCS, ESG 或 AR 不存在"
    exit
}

* 创建完整样本数据集
preserve
keep if !missing(SCS, ESG, AR)
qui count
di "分析样本量: " r(N)

* 步骤1：进行回归分析
qui regress AR SCS IC ROA Size Top1 FN list inventory big4 GDP        // 总效应模型
scalar c = _b[SCS]         // 总效应
qui regress ESG SCS IC ROA Size Top1 FN list inventory big4 GDP   // 路径a: SCS → ESG
scalar a = _b[SCS]         // 路径a系数
scalar sa = _se[SCS]       // 路径a标准误
qui regress AR ESG SCS IC ROA Size Top1 FN list inventory big4 GDP    // 路径b: ESG → AR (控制SCS)
scalar b = _b[ESG]         // 路径b系数
scalar sb = _se[ESG]       // 路径b标准误
scalar c_prime = _b[SCS]   // 直接效应

* 步骤2：计算中介效应
scalar ind_eff = a * b
di _n "==== 中介效应分析结果 ===="
di "总效应 (c): " %9.4f c
di "直接效应 (c'): " %9.4f c_prime
di "中介效应 (a*b): " %9.4f ind_eff
di "效应占比: " %9.4f (ind_eff/c)

* 步骤3：计算三种检验统计量
* Sobel检验
scalar se_sobel = sqrt((a^2 * sb^2) + (b^2 * sa^2))
scalar z_sobel = ind_eff / se_sobel
scalar p_sobel = 2 * (1 - normal(abs(z_sobel)))

* Aroian检验
scalar se_arorian = sqrt((a^2 * sb^2) + (b^2 * sa^2) + (sa^2 * sb^2))
scalar z_arorian = ind_eff / se_arorian
scalar p_arorian = 2 * (1 - normal(abs(z_arorian)))

* Goodman检验
scalar se_goodman = sqrt((a^2 * sb^2) + (b^2 * sa^2) - (sa^2 * sb^2))
if se_goodman > 0 {
    scalar z_goodman = ind_eff / se_goodman
    scalar p_goodman = 2 * (1 - normal(abs(z_goodman)))
}
else {
    scalar z_goodman = .
    scalar p_goodman = .
}

* 步骤4：显示结果表格
di _n "==== 中介效应检验结果 ===="
di "Test         | 统计量   | SE        | p值"
di "--------------------------------------------"
di "Sobel test   | " %7.3f z_sobel   " | " %8.6f se_sobel   " | " %6.4f p_sobel
di "Aroian test  | " %7.3f z_arorian " | " %8.6f se_arorian " | " %6.4f p_arorian
di "Goodman test | " %7.3f z_goodman " | " %8.6f se_goodman " | " %6.4f p_goodman

* 步骤5：添加星号标记显著性
foreach test in sobel aroian goodman {
    scalar star_`test' = ""
    if !missing(p_`test') {
        if p_`test' < 0.01 scalar star_`test' = "***"
        else if p_`test' < 0.05 scalar star_`test' = "**"
        else if p_`test' < 0.1 scalar star_`test' = "*"
    }
}

* 步骤6：格式化输出（带星号）
di _n "==== 格式化检验结果 ===="
di "Test         | 统计量     | SE        | p值"
di "--------------------------------------------"
di "Sobel test   | " %7.3f z_sobel star_sobel " | " %8.6f se_sobel   " | " %6.4f p_sobel
di "Aroian test  | " %7.3f z_arorian star_arorian " | " %8.6f se_arorian " | " %6.4f p_arorian
di "Goodman test | " %7.3f z_goodman star_goodman " | " %8.6f se_goodman " | " %6.4f p_goodman

* 步骤7：Bootstrap法验证（推荐）
di _n "正在执行Bootstrap检验（5000次重复）..."
bootstrap r(ind_eff) r(se_sobel) r(z_sobel) r(p_sobel), reps(5000) saving(mediation_results, replace): ///
{
    preserve
    keep if !missing(SCS, ESG, AR)
    qui regress ESG SCS
    scalar a = _b[SCS]
    qui regress AR ESG SCS
    scalar b = _b[ESG]
    scalar ind_eff = a * b
    scalar se_sobel = sqrt((a^2 * _se[ESG]^2) + (b^2 * _se[SCS]^2))
    scalar z_sobel = ind_eff / se_sobel
    return scalar ind_eff = ind_eff
    return scalar se_sobel = se_sobel
    return scalar z_sobel = z_sobel
    return scalar p_sobel = 2 * (1 - normal(abs(z_sobel)))
    restore
}

* 显示Bootstrap结果
di _n "==== Bootstrap 检验结果 ===="
estat bootstrap, all

* 保存结果
restore
use mediation_results, clear
save mediation_results, replace


*--------------------------- Bootstrap中介效应检验（5000次重复） *--------------------------- Bootstrap中介效应检验（5000次重复） ---------------------------
di _n "正在执行Bootstrap检验（5000次重复）..."
bootstrap ind_eff = r(ind_eff) se_sobel = r(se_sobel) z_sobel = r(z_sobel) p_sobel = r(p_sobel), ///
    reps(5000) saving(mediation_bootstrap, replace) seed(12345): ///
{
    * 子样本重抽样时保留完整数据（避免缺失值干扰）
    preserve
    keep if !missing(SCS, ESG, AR)  // 过滤缺失值
    
    * 第一步：SCS对中介变量ESG的回归（计算a路径，含控制变量）
    qui regress ESG SCS IC ROA Size Top1 FN list inventory big4 GDP
    scalar a = _b[SCS]       // a系数：SCS→ESG
    scalar se_a = _se[SCS]   // a的标准误
    
    * 第二步：ESG和SCS对因变量AR的回归（计算b路径，含控制变量）
    qui reg AR ESG SCS IC ROA Size Top1 FN list inventory big4 GDP
    scalar b = _b[ESG]       // b系数：ESG→AR
    scalar se_b = _se[ESG]   // b的标准误
    
    * 计算间接效应及相关统计量
    scalar ind_eff = a * b                  // 间接效应（a×b）
    scalar se_sobel = sqrt(a^2 * se_b^2 + b^2 * se_a^2)  // Sobel标准误
    scalar z_sobel = ind_eff / se_sobel     // Sobel Z值
    scalar p_sobel = 2 * (1 - normal(abs(z_sobel)))  // 双侧p值
    
    * 返回结果给Bootstrap
    return scalar ind_eff = ind_eff
    return scalar se_sobel = se_sobel
    return scalar z_sobel = z_sobel
    return scalar p_sobel = p_sobel
    
    restore  // 恢复原始数据
}






















