# Raisa Rubio coding working sample - STATA

This work is part of the data analyis for my second-year master thesis at Lund University. The thesis is aimed at estimating the effects of both growth and income inequality on poverty in Peru. For that I used data from the National Household Survey spanning from 2007-2019. Unlike previous research for the country, it focuses on regional poverty dynamics highlighting the implications of regional idiosyncrasies and how they interplayed with the variables studied. It further looks at how growth and inequality affected the poor from a spatial dimension, that is, considering the differences between rural and urban poverty within regions.

The research-output can be found [here](https://lup.lub.lu.se/student-papers/search/publication/9056984)

## Sample work
Below some stata-tasks are shown, but the complete do.file on this stage of the study is available on this repository.

After cleaning and analysing the data, more work is needed. This includes:

#### i. Preparing the panel
```stata
clear 
set more off
import excel "C:\Users\raisa\OneDrive\Documents\Lund\Thesis 2\Data\INEI_sectoral panel.xlsx", ///
sheet("Panel variables") firstrow
preserve

drop Region
label variable regioncode "Region - Includes Callao & Lima Metropolitana"
label define regioncode 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 27 "Lima Metropolitana"
label values regioncode regioncode

label var income2pit "Disposable income of the poor"
label variable G2it "Disposable inequality"
label variable infrlit "Informality by region"
label variable Prit "Rural poverty"

xtset regioncode year
```
#### ii. Creating main variables
```stata
 quietly forvalues i = 1/2 {
	gen lnincome`i'it = ln(income`i'it) lnincome2it 
	label var lnincome`i'it "Log of average regional income"
}

quietly forvalues i = 1/2 {
	gen dlnincome`i'it = d.lnincome`i'it
	label var dlnincome`i'it "First difference log of average regional income"
}
```
#### iii. Creating auxiliary variables
When estimating the model, the sample (regions) is resctriced by quintiles (based both on income and poverty levels) & income status
. 
```stata
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
```
#### iv. Estimating the model & producing journal-like tables and graphs
- The approach. Fixed effects vs Random Effects
```stata
xtreg lnPit lnincome2it lnG2it, fe
estimates store FE
xtreg lnPit lnincome2it lnG2it, re
estimates store RE
hausaman FE RE

bysort regioncode: egen y_mean=mean(Pit)
twoway scatter Pit regioncode, msymbol(circle_hollow) || connected y_mean regioncode, msymbol(diamond) ||
, xlabel(1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 "Cusco" scheme(sj)
```
- Estimating model by specifications. For example, by quintiles (income level).       
```stata
forvalues q = 1/5 {
	xtreg lnPit lnincome2it lnG2it $control i.year#c.regioncode if qt==`q', fe
  outreg2 using FEmodel_quintiles.doc, ///
  `replace' title (Economic growth & inequality for poverty reduction, Fixed Effect Model) nonotes nocons noni///
  addnote ("Dependent variable is natural log of regional poverty. ///
  Standard errors in brackets. ***, **, and * indicate significance at the 1%, 5%, and 10% levels. ///
  Growth rates are calculated as average natural log of disposable  over the studied period. ///
  Inequality refers to within disposable regional inequality.") ctitle (Quintile, `q') ///
  keep (lnincome2it lnG2it) label bdec (2) sdec(3) rdec (2) addtext(Time fixed effects, Yes, Regional controls, Yes)
}
 ```     
- Providing addtional information. 
 Using `sumdist` the change in the labour income share accruing to the poorest halves of 
 the population (Table 7) is provided. 
 ```stata
quietly forvalues t = 2007/2019 { 
quietly forvalues q = 1/5 { 
	sumdist incomeit if year== `t' & area==1, ng(5)
	qui gen incomeit`q'q = r(q`q')
	qui gen shincomeit`q' = r(sh`q')
	label var incomeit`q'q "Mean labour income of q quintile - urban"
    label var shincomeit`q'q "Income share of q quintile - urban"
}
}
 ```
