* 假设数据结构：
* - scs: 供应链稳定性指标
* - size: 企业规模
* - roa: 资产收益率
* - ownership: 股权集中度
* - [其他协变量]

* 安装必要命令（首次运行需安装）
ssc install psmatch2, replace
ssc install pstest, replace
ssc install estout, replace  // 输出结果到表格

* Step 1: 生成处理组变量
sum SCS, meanonly
gen treat = (SCS >= r(mean)) if !missing(SCS)
label var treat "处理组(SCS≥均值)"

* Step 2: 检查分组样本量
tab treat, missing

* Step 3: 倾向得分匹配(1:1最近邻)
psmatch2 treat IC ROA Size Top1 FN list inventory big4 GDP, ///
   n(1)                   /// 一对一匹配
   caliper(0.05)          /// 卡尺限制(建议值为倾向得分标准差的0.2倍)
   common                 /// 仅共同支持域
   ties                   /// 处理得分相同情况
   ate                    /// 估计ATE/ATT
   logit                  /// 使用logit模型
   outcome(SCS)           // 结果变量(此处用scs，实际可替换为其他结果变量)

* Step 4: 保存匹配结果
gen matched = _weight != .
tab matched treat, row col

* Step 5: 平衡性检验
pstest IC ROA Size Top1 FN list inventory big4 GDP, both graph

* 可视化平衡性
twoway (kdensity _pscore if treat==1, lcolor(blue)) ///
       (kdensity _pscore if treat==0, lcolor(red)), ///
       legend(order(1 "处理组" 2 "控制组")) ///
       title("倾向得分分布") xtitle("倾向得分")

* Step 6: 共同支持域检查
psgraph

* Step 7: 处理效应估计(ATT)
teffects psmatch (SCS) (treat IC ROA Size Top1 FN list inventory big4 GDP, logit), atet


* 步骤4: 创建匹配样本标识
gen matched = _weight != .

* 步骤5: 使用匹配样本进行reghdfe回归
reghdfe AR treat IC ROA Size Top1 FN list inventory big4 GDP if matched, ///
   absorb(year industry)    /// 控制年度和行业固定效应
   vce(cluster id)              // 稳健标准误

* 步骤6: 结果输出
estimates store PSM_Result
esttab PSM_Result, b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
   keep(treat) title("PSM匹配后SCS对AR的影响") 

* 步骤7: 敏感性分析（可选）
rbounds AR if _support == 1, gamma(1.5 2 2.5)

























