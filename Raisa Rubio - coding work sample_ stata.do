*Second-year master thesis*

/*3. Estimation (source: ENAHO 2007-2018) */

*After merging, cleaning and creating variables of interest, now I estimate the Model & do robustness checks*

clear 
set more off
import excel "C:\Users\raisa\OneDrive\Documents\Lund\Thesis\Thesis 2\Data\ENAHO\INEI_sectoral panel.xlsx", sheet("Panel variables") firstrow

preserve

drop Region
label variable regioncode "Region - Includes Callao & Lima Metropolitana"
label define regioncode 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco" 11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martin" 23 "Tacna" 24 "Tumbes" 25 "Ucayali" 26 "Lima Provincias" 27 "Lima Metropolitana"
label values regioncode regioncode

label var income1it "Gross income"
label var income2it "Disposable income"
label var incomeit "Net labour income"
label var income2pit "Disposable income of the poor"
label var incomepit "Labour income of the poor"

label variable G1it "Market inequality"
label variable G2it "Disposable inequality"

label variable infrlit "Informality by region"
label variable unit "Unemployment rate"
label variable urempit "Urban employment"
label variable edu1it "%pop with primary education"
label variable ethn1it "% native pop"
label variable ethn2it "% Afroperuvian pop"
label variable ethn3it "% white by pop"
label variable ethn4it "% Mixed by pop"

label variable Pt "Peru Poverty"
label variable Pit "Poverty by region"
label variable Prit "Rural poverty"
label variable Puit "Urban poverty"

xtset regioncode year

**  3.1/ Creating (annual average) growth rates **

   /* income by region as measure of economic growth*/
quietly forvalues i = 1/2 {
	gen lnincome`i'it = ln(income`i'it) lnincome2it 
	label var lnincome`i'it "Log of average regional income"
}

quietly forvalues i = 1/2 {
	gen dlnincome`i'it = d.lnincome`i'it
	label var dlnincome`i'it "First difference log of average regional income"
}
   /*Poverty*/
gen lnPit = ln(Pit)
label var lnPit "Log of poverty"

gen dlnPit = d.lnPit
label var dlnPit "First difference of log poverty"

gen lnPrit = ln(Prit)
label var lnPrit "Log of rural poverty"

gen dlnPrit = d.lnPrit
label var dlnPrit "First difference of log rural poverty"

gen lnPuit = ln(Puit)
label var lnPuit "Log of urban poverty"

gen dlnPuit = d.lnPuit
label var dlnPuit "First difference of log urban poverty"

   /*Inequality*/
gen lnG1it = ln(G1it)
gen lnG2it = ln(G2it)

label var lnG1it "Log of market inequality"
label var lnG2it "Log of disposable inequality"

gen dlnG1it = d.lnG1it
gen dlnG2it = d.lnG2it

label var dlnG1it "Inequality"
label var dlnG2it "Inequality"

**  3.2/ Creating quintiles (by income and poverty levels) & income status  **

tempvar flag4
gen int qt=.
quietly forvalues t = 2007/2019 {  
	xtile `flag4' = income2it if year==`t' , nq (5)
	replace qt = `flag4' if year==`t'
	drop `flag4'
}
label variable qt "Distributional regional disposable income (quintiles)"
label define qt 1 "I quintile" 2 "II quintile" 3 "III quintile" 4 "IV quintile" 5 "V quintile"
label values qt qt

tempvar flag3
gen int qt3=.
quietly forvalues t = 2007/2019 {  
	xtile `flag3' = income2it if year==`t' , nq (3)
	replace qt3 = `flag3' if year==`t'
	drop `flag3'
}
label variable qt3 "Distributional regional disposable income  (status)"
label define qt3 1 "Lower income" 2 "middle income" 3 "top income" 
label values qt3 qt3

tempvar flag7
gen int qt7=.
quietly forvalues t = 2007/2019 {  
	xtile `flag7' = Pit if year==`t' , nq (5)
	replace qt7 = `flag7' if year==`t'
	drop `flag7'
}
label variable qt7 "Regional levels of poverty (quintiles)"
label define qt7 1 "I quintile" 2 "II quintile" 3 "III quintile" 4 "IV quintile" 5 "V quintile"
label values qt7 qt7

**  3.3/ Control variables: infrlit unit urempit edu1it edu ethn1it ethn2it ethn3it ethn4it **

gen infrlitlg = infrlit[_n-1]
gen unitlg = unit[_n-1]
gen urempitlg = urempit[_n-1]
gen edu1itlg = edu1it[_n-1]
gen ethn1itlg = ethn1it[_n-1]
gen ethn2itlg = ethn2it[_n-1]
gen ethn3itlg = ethn3it[_n-1]
gen ethn4itlg = ethn4it[_n-1] 

label var infrlitlg "Informality lagged"
label var unitlg "Unemployment lagged"
label var urempitlg "Urban employment lagged"
label var edu1itlg "Share pop with primary education lagged"


********************************************************************
                  ** 3.4/ ESTIMATING the MODEL **
********************************************************************

global control infrlitlg unitlg urempitlg edu1itlg ethn1itlg ethn2itlg ethn3itlg ethn4itlg

    /* a. Fixed effects vs Random Effects*/
xtreg lnPit lnincome2it lnG2it, fe
estimates store FE
xtreg lnPit lnincome2it lnG2it, re
estimates store RE
hausaman FE RE
outreg2 using hausman1.doc, replace title (Fixed Effects vs Random Effects model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. F-test reports the p-value of the Hausman test.") ctitle (Baseline Model) adds (F-test, `r(p) ') label bdec (2) sdec(3) rdec (2)

           *Nota. Resultados above indicate Model is a FE model*
	   
            * FE model supporting info (Figure 4)*

               * FEPoverty heterogenity across regions *
bysort regioncode: egen y_mean=mean(Pit)
twoway scatter Pit regioncode, msymbol(circle_hollow) || connected y_mean regioncode, msymbol(diamond) || , xlabel(1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco" 11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" 21 "Puno" 22 "San Martin" 23 "Tacna" 24 "Tumbes" 25 "Ucayali" 26 "Lima Provincias" 27 "Lima Metropolitana") scheme(sj)
               * Poverty heterogenity across years *
bysort year: egen y_mean1=mean(Pit)
twoway scatter Pit year, msymbol(circle_hollow) || connected y_mean1 year, msymbol(diamond) || , xlabel(2007(1)2019) scheme(sj)


	/* b. Model estimation: income by region as measure of economic growth*/
	
	*b.1: disposable income - inequality for all regions
	
	 xtreg lnPit lnincome2it lnG2it, fe r
 outreg2 using FEmodel.doc, replace title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log of disposable income over the studied period. Inequality refers to within disposable regional inequality.") ctitle (Peru, baseline) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, No, Regional controls, No)
  
     xtreg lnPit lnincome2it lnG2it i.year#c.regioncode, fe r
 outreg2 using FEmodel.doc, append keep (lnincome2it lnG2it) nonotes nocons noni ctitle (Peru, baseline) label bdec (2) sdec(3)  rdec (2) addtext(Time fixed effects, Yes, Regional controls, No)

     xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode, fe r
 outreg2 using FEmodel.doc, append keep (lnincome2it lnG2it) nonotes nocons noni ctitle (Peru, Full model) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
 

    *b.2: disposable income - inequality by quintiles; regional income status; for the bottom 20% & poverty by area
	
	 *Quintiles*
forvalues q = 1/5 {
	xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode if qt==`q', fe
  outreg2 using FEmodel_quintiles.doc, `replace' title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average natural log of disposable over the studied period. Inequality refers to within disposable regional inequality.") ctitle (Quintile, `q') keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
}

     *Income status: lower, middle and upper income regions*
forvalues q = 1/3 {
	xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode if qt3==`q', fe
  outreg2 using FEmodel_incomestatus.doc, `replace' title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average natural log of disposable over the studied period. Inequality refers to within disposable regional inequality") ctitle (`label', income) keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
}

     *20% and 40% bottom*
	xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode if qt==1 | qt==2 , fe
  outreg2 using FEmodel_povertylevelb40.doc, replace title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log of disposable income over the studied period. Inequality refers to within disposable regional inequality.") ctitle (Bottom 40%, Income level) keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
      
  	xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode if qt7==4 | qt7==5, fe
  outreg2 using FEmodel_povertylevelb40.doc, append nonotes nocons noni ctitle (Bottom 40%, Poverty level) keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
  

  *Rural & rural poverty*
    xtreg lnPrit lnincome2it lnG2it $control i.year#c.regioncode, fe r
 outreg2 using FEmodel_ruralurban.doc, replace title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log of disposable income over the studied period. Inequality refers to within disposable regional inequality.") ctitle (Rural poverty) keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes) 

   xtreg lnPuit lnincome2it lnG2it $control i.year#c.regioncode, fe r
  outreg2 using FEmodel_ruralurban.doc, append nonotes nocons noni ctitle (Urban poverty) keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes) 
  
  
   xtreg lnPrit lnincomeit lnG2it $control i.year#c.regioncode, fe r
 outreg2 using modelB2_FErural.doc, replace title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the indicated period. Inequality refers to within disposable regional inequality.") ctitle (Rural poverty) keep (lnincomeit lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes) 

    xtreg lnPuit lnincomeit lnG2it $control i.year#c.regioncode, fe r
  outreg2 using modelB2_FErural.doc, append nonotes nocons noni ctitle (Urban poverty) keep (lnincomeit lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
  
    *b.3: Regional patterns (ADDITIONAL INFO)*

 * Systematic change in the labour income share accruing to the poorest halves of the population (Table7)*
quietly forvalues t = 2007/2019 { 
quietly forvalues q = 1/5 { 
	sumdist incomeit if year== `t' & area==1, ng(5)
	qui gen incomeit`q'q = r(q`q')
	qui gen shincomeit`q' = r(sh`q')
	label var incomeit`q'q "Mean labour income of q quintile - urban"
    label var shincomeit`q'q "Income share of q quintile - urban"
}
}

quietly forvalues t = 2007/2019 { 
quietly forvalues q = 1/5 { 
	sumdist incomeit if year== `t' & area==0, ng(5)
	qui gen incomeit`q'q = r(q`q')
	qui gen shincomeit`q' = r(sh`q')
	label var incomeit`q'q "Mean labour income of q quintile - rural"
    label var shincomeit`q'q "Income share of q quintile - rural"
}
}
    
  ******************************************************************
                     *3.4 ROBUSTNESS CHECK*
  ******************************************************************
  /* Model b: First difference*/
 reg dlnPit dlnincome2it dlnG2it, r
outreg2 using modelB_noFE.doc, replace title (Economic growth & inequality for poverty reduction, F.Difference Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the indicated period. Inequality refers to within disposable regional inequality.") ctitle (Peru, baseline) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, No, Regional controls, No)
 
reg dlnPit dlnincome2it dlnG2it i.year, r
 outreg2 using modelB_noFE.doc, append keep (dlnincome2it dlnG2it) nonotes nocons noni ctitle (Peru, baseline) label bdec (2) sdec(3)  rdec (2) addtext(Time trend, Yes, Regional controls, No)

reg dlnPit dlnincome2it dlnG2it $control i.year#c.regioncode , r
 outreg2 using modelB_noFE.doc, append keep (dlnincome2it dlnG2it) nonotes nocons noni ctitle (Peru, Full model) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)
 

 	 *Quintiles*
forvalues q = 1/5 {
	reg dlnPit dlnincome2it $control i.year#c.regioncode if qt==`q', r
  outreg2 using modelB_noFEqt2.doc, `replace' title (Economic growth & inequality for poverty reduction, F.Difference Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the studied period. Inequality refers to within disposable regional inequality.") ctitle (Quintile, `q') keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)
}

     *Income status: lower, middle and upper income regions*
forvalues q = 1/3 {
	reg dlnPit dlnincome2it dlnG2it $control i.year#c.regioncode if qt3==`q', r
  outreg2 using modelB_noFEqt32.doc, `replace' title (Economic growth & inequality for poverty reduction, F.Difference Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the studied period. Inequality refers to within disposable regional inequality") ctitle (`label', income) keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)
}

     *20% and 40% bottom*
reg dlnPit dlnincome2it dlnG2it $control i.year#c.regioncode if qt==1 | qt==2 , r
  outreg2 using modelB_noFEb402.doc, replace title (Economic growth & inequality for poverty reduction, F.Difference Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the studied period. Inequality refers to within disposable regional inequality") ctitle (Bottom 40%, Income level) keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)
  
  
reg dlnPit dlnincome2it dlnG2it $control i.year#c.regioncode if qt7==4 | qt7==5, r
  outreg2 using modelB_noFEb402.doc, append nonotes nocons noni ctitle (Bottom 40%, Poverty level) keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)

  *Rural & rural poverty*
reg dlnPrit dlnincome2it dlnG2it $control i.year#c.regioncode , r
 outreg2 using modelB_noFErural2.doc, replace title (Economic growth & inequality for poverty reduction, F.Difference Model) nonotes nocons noni addnote ("Dependent variable is natural log of regional poverty. Robust standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. Growth rates are calculated as average annual of natural log differences over the studied period. Inequality refers to within disposable regional inequality") ctitle (Rural poverty) keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes) 

 reg dlnPuit dlnincome2it dlnG2it $control i.year#c.regioncode , r
  outreg2 using modelB_noFErural2.doc, append nonotes nocons noni ctitle (Urban poverty) keep (dlnincome2it dlnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time trend, Yes, Regional controls, Yes)
  
  **** 

 
 
 
  