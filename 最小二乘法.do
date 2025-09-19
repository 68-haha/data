* 普通最小二乘法回归，以id为聚类变量计算标准误
regress AR SCS IC ROA Size Top1 FN list inventory big4 GDP industry_dum* year_dum*, cluster(id)

regress AR SCS IC ROA Size Top1 FN list inventory big4 GDP industry_dum* year_dum*, cluster(id)
个体固定效应模型
xtset id year  // 设定面板数据结构（id为个体标识，year为时间变量）
xtreg AR SCS IC ROA Size Top1 FN list inventory big4 GDP year_dum*, fe cluster(id)

xtreg AR SCS IC ROA Size Top1 FN list inventory big4 GDP industry_dum* year_dum*, re cluster(id)
