
xtset id year
destring AR SCS , replace ignore("N/A" "Missing")
local winsor_vars AR SCS ESG AnaAttention IC ROA Size Top1 list inventory GDP 
winsor2 `winsor_vars', replace cuts(1 99)
foreach var in AR SCS ESG AnaAttention IC ROA Size Top1 list inventory GDP {
	egen std_`var' = std(`var'), mean(0) std(1)
}
drop if missing(AR, SCS ,ESG ,AnaAttention ,IC, ROA ,Size ,Top1 ,list ,inventory ,GDP ,FN, big4) 
tab industry, gen(industry_dum)  
tab year, gen(year_dum) 
asdoc summarize AR SCS ESG AnaAttention IC ROA Size Top1 FN list inventory big4 GDP
asdoc pwcorr AR SCS ESG AnaAttention IC ROA Size Top1 FN list inventory big4 GDP, sig star(.05)
多重共线性检验
reg AR SCS ESG AnaAttention IC ROA Size Top1 FN list inventory big4 GDP 
vif
模型检验
F检验
asdoc xtreg AR SCS ESG AnaAttention IC ROA Size Top1 FN list inventory big4 GDP, fe 
Hausman检验
* Run fixed effects model
xtreg AR SCS ESG IC C ROA Size CusCon, fe
estimates store fe

* Run random effects model
xtreg AR SCS ESG IC C ROA Size CusCon, re
estimates store re

* Perform Hausman test
hausman fe re
多元回归
reghdfe std_AR std_SCS std_IC std_ROA std_Size std_Top1 std_list std_inventory std_GDP FN big4  industry_dum* year_dum*, cluster(id)
est store a1
reghdfe std_ESG std_SCS std_IC std_ROA std_Size std_Top1 std_list std_inventory std_GDP FN big4 industry_dum* year_dum*, cluster(id)
est store a2
reghdfe std_AR std_SCS std_ESG std_IC std_ROA std_Size std_Top1 std_list std_inventory std_GDP FN big4 industry_dum* year_dum*, cluster(id)
est store a3
reghdfe std_AR std_SCS std_AnaAttention std_IC std_ROA std_Size std_Top1 std_list std_inventory std_GDP FN big4  industry_dum* year_dum*, cluster(id)
est store a4
gen m1=std_SCS*std_AnaAttention
reghdfe std_AR std_SCS std_AnaAttention m1 std_IC std_ROA std_Size std_Top1 std_list std_inventory std_GDP FN big4  industry_dum* year_dum*, cluster(id)
est store a5
reg2docx a1 a2 a3 a4 a5 using Myfile555.docx,replace b(%9.3f) t(%9.3f) scalars(N r2 F) title(表1多元回归表) note(***p<0.01, **p<0.05, *p<0.10)

xtreg AR SCS IC ROA Size Top1 list inventory big4 GDP if FN_not_1 == 1,fe vce(cluster id)
est store a1
xtreg AR SCS IC ROA Size Top1 list inventory big4 GDP if FN_1 == 1,fe vce(cluster id)
est store a2




