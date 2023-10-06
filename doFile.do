*|==============================================================================
*| TITLE
*| The Institutional Cost of Left-Leaning Populism in Latin America
*|
*| AUTHORS
*| Nicolas Cachanosky
*| University of Texas at El Paso | ncachanosky@utep.edu
*|
*| This version: dd-mmm-yyyy
*|==============================================================================

***|============================================================================
**#| INSTALL PACKAGES AND DEFINE SETTINGS
***|----------------------------------------------------------------------------

***| Directory

// Change to your file path
cd "\Users\ncachanosky\OneDrive\Research\Working Papers\populism-sca"

*| Packages
ssc install schemepack, replace		// Plot schemes

/*
set scheme tab1
set scheme tab2
set scheme tab3
set scheme white_tableau
set scheme myUTEP
*/

*| Plot settings
set scheme white_tableau
graph set window fontface "Times New Roman"



***| Synthetic Control / synth_runner / parallen
***|----------------------------------------------------------------------------
ssc install synth		, all replace

cap ado uninstall synth_runner //in-case already installed
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace

net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
mata mata mlib index



***|============================================================================
**#| DOWNLOAD DATA
***|----------------------------------------------------------------------------

*| Load and prepare data
global data = "https://github.com/ncachanosky/populism-sca/raw/main/data.xlsx"

import excel $data, sheet("Data") firstrow clear
tsset country_id year

rename country_name		country
rename country_text_id	country_code
rename country_id		id

rename efw					EFW
rename voiceaccount			WGI1
rename ruleoflaw			WGI2
rename controlofcorruption 	WGI3
rename icrgcorruption		ICRG

gen VDEMy 	= 100*v2x_libdem
gen VDEM1	= 100*v2x_polyarchy
gen VDEM2	= 100*v2x_freexp_altinf
gen VDEM3	= 25*v2excrptps_osp
gen VDEM4	= 25*v2jupoatck_osp
gen VDEM5	= 100*v2xnp_client
gen VDEM6	= 100*v2xnp_pres

drop v2x_libdem
drop v2x_polyarchy
drop v2x_freexp_altinf
drop v2excrptps
drop v2jupoatck
drop v2xnp_client
drop v2xnp_pres

label variable country		"Country"
label variable country_code	"text_id"
label variable id			"country id"
label variable populist		"Populist dummy"
label variable year			"Year"
label variable VDEMy		"V-Dem: Liberal Democracy Index"
label variable VDEM1		"V-Dem: Electoral Democracy Index"
label variable VDEM2		"V-Dem: Freedom of Expression"
label variable VDEM3		"V-Dem: Public Sector Corrupt Charges"
label variable VDEM4		"V-Dem: Government Attackson the Judiciary"
label variable VDEM5		"V-Dem: Clientelism Index"
label variable VDEM6		"V-Dem: Presidentialism Index"
label variable polity2		"Polity V"
label variable EFW			"Economic Freedom of the World Index"
label variable WGI1			"WGI: Voive and Accountability"
label variable WGI2			"WGI: Rule of Law"
label variable WGI3			"WGI: Control of Corruption"
label variable ICRG			"ICRG: Corruption"
label variable FH_PR		"Freedom House: Political Rights"
label variable FH_CL		"Freedom House: Civil Liberties"

save data, replace

		
***|============================================================================
**#| SCA ESTIMATIONS
***|----------------------------------------------------------------------------

**#| Argentina
***|----------------------------------------------------------------------------
use data.dta, clear

drop if country_code=="BOL"	
drop if country_code=="ECU"
drop if country_code=="NIC"
drop if country_code=="VEN"

drop if year < 1993
drop if year > 2012


parallel numprocessors	// 8 processors
parallel initialize 6

global convergence	 = "nested allopt technique(nr)"
global predictors	 = "VDEM2 VDEM3 VDEM5 WGI1 FH_PR FH_CL"
global pre_treatment = "VDEMy(1994) VDEMy(1997) VDEMy(1998) VDEMy(2002)"
global treat_y       = "2003"
global x_axis		 = "1993(1)2012"


/*
synth VDEMy $predictors $pre_treatment, trunit(2) trperiod($treat_y)		 ///
	  unitnames(country) resultsperiod($x_axis)
*/
    
synth_runner VDEMy $predictors $pre_treatment,								 ///
			 trunit(2) trperiod($treat_y)			 						 ///
			 gen_vars parallel				 								 ///
			 synthsettings(unitnames(country))								 ///
			 graphs

			 
rename 	VDEMy_synth	ARG_SCA
rename 	effect		ARG_effect
drop	pre_rmspe
drop	post_rmspe
drop 	lead

label variable	ARG_SCA "Argentina"


global title	= "V-Dem: Liberal Democracy Index in Argentina"
global ytitle1	= "V-Dem: Liberal Democracy Index (0-100)"
global ytitle2  = "Synthetic effect"
global label1	= "Argentina"
global label2	= "Synthetic Argentina"

twoway line VDEMy	   year if id==2, lpattern(solid) 						 ///
	|| line ARG_SCA    year if id==2, lpattern(dash)  xline(2002)			 ///
	   xlabel(1993(5)2012) 													 ///
	   ytitle($ytitle1) 				 									 ///
	   legend(label(1 $label1) label(2 $label2) position(6) rows(1)) nodraw
	   graph rename ARG_synth, replace

	   
twoway bar 	ARG_effect year if id==2, color(gray%50) xline(2002) 			 ///
	   yline(0, lpattern(solid)) 											 ///
	   xlabel(1993(5)2012)													 ///
	   ytitle($ytitle2) nodraw
	   graph rename ARG_effect, replace

 	
graph combine ARG_synth ARG_effect, xcommon rows(2)	ysize(8)
graph export Figures/Fig_ARG.png, replace
graph drop _all


keep if country_code == "ARG"
rename year		ARG_year
rename VDEMy	ARG_VDEMy
drop VDEM1 VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 WGI1 WGI2 WGI3
drop ICRG polity EFW populist id country country_code
generate t = _n - 11, before(ARG_year)

save data_avg, replace


**#| Bolivia
***|----------------------------------------------------------------------------
use data.dta, clear

drop if country_code=="ARG"	
drop if country_code=="ECU"
drop if country_code=="NIC"
drop if country_code=="VEN"

drop if year < 1995
drop if year > 2014


parallel numprocessors	// 8 processors
parallel initialize 6

global convergence	 = "nested allopt technique(nr)"
global predictors    = "VDEM2 VDEM5 WGI1 WGI3 ICRG FH_PR FH_CL"
global pre_treatment = "VDEMy(1998) VDEMy(2000) VDEMy(2002) VDEMy(2004)"
global treat_y       = "2005"
global x_axis		 = "1995(1)2014"

/*
synth VDEMy $predictors $pre_treatment, trunit(6) trperiod($treat_y)	 ///
	  unitnames(country) resultsperiod($x_axis)	
*/	
    

synth_runner VDEMy $predictors $pre_treatment,								 ///
			 trunit(6) trperiod($treat_y)			 						 ///
			 gen_vars parallel				 								 ///
			 synthsettings(unitnames(country))								 ///
			 graphs


rename 	VDEMy_synth	BOL_SCA
rename 	effect		BOL_effect
drop	pre_rmspe
drop	post_rmspe
drop 	lead
			 
label variable	BOL_SCA "Bolivia"


global title	= "V-Dem: Liberal Democracy Index in Bolivia"
global ytitle1	= "V-Dem: Liberal Democracy Index (0-100)"
global ytitle2  = "Synthetic effect"
global label1	= "Bolivia"
global label2	= "Synthetic Bolivia"

twoway line VDEMy	   year if id==6, lpattern(solid) 						 ///
	|| line BOL_SCA    year if id==6, lpattern(dash)  xline(2004)			 ///
	   xlabel(1995(5)2014) 													 ///
	   ytitle($ytitle1) 				 									 ///
	   legend(label(1 $label1) label(2 $label2) position(6) rows(1)) nodraw
	   graph rename BOL_synth, replace
	   
twoway bar 	BOL_effect year if id==6, color(gray%50) xline(2004) 			 ///
	   yline(0, lpattern(solid))											 ///
	   xlabel(1995(5)2014)													 ///
	   ytitle($ytitle2) nodraw
	   graph rename BOL_effect, replace
 
	
graph combine BOL_synth BOL_effect, xcommon rows(2)	ysize(8)
graph export Figures/Fig_BOL.png, replace
graph drop _all


keep if country_code == "BOL"
rename year		BOL_year
rename VDEMy	BOL_VDEMy
drop VDEM1 VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 WGI1 WGI2 WGI3
drop ICRG polity EFW populist id country country_code
generate t = _n - 11, before(BOL_year)


merge 1:1 t using data_avg
drop _merge
save data_avg, replace
			
			
**#| Ecuador
***|----------------------------------------------------------------------------
use data.dta, clear

drop if country_code=="ARG"	
drop if country_code=="BOL"
drop if country_code=="NIC"
drop if country_code=="VEN"

drop if year < 1997
drop if year > 2016


parallel numprocessors	// 8 processors
parallel initialize 6

global convergence	 = "nested allopt technique(nr)"
global predictors    = "VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 ICRG polity2 FH_PR"
global pre_treatment = "VDEMy(1997) VDEMy(2002) VDEMy(2003) VDEMy(2006)"
global treat_y       = "2007"
global x_axis		 = "1997(1)2016"

/*
synth VDEMy $predictors $pre_treatment, trunit(13) trperiod($treat_y)	 ///
	  unitnames(country) resultsperiod($x_axis)	
*/
    
synth_runner VDEMy $predictors $pre_treatment,								 ///
			 trunit(13) trperiod($treat_y)			 						 ///
			 gen_vars parallel				 								 ///
			 synthsettings(unitnames(country))								 ///
			 graphs


rename 	VDEMy_synth	ECU_SCA
rename 	effect		ECU_effect
drop	pre_rmspe
drop	post_rmspe
drop 	lead

label variable	ECU_SCA "Ecuador"


global title	= "V-Dem: Liberal Democracy Index in Ecuador"
global ytitle1	= "V-Dem: Liberal Democracy Index (0-100)"
global ytitle2  = "Synthetic effect"
global label1	= "Ecuador"
global label2	= "Synthetic Ecuador"

twoway line VDEMy	   year if id==13, lpattern(solid) 						 ///
	|| line ECU_SCA    year if id==13, lpattern(dash)  xline(2006)			 ///
	   xlabel(1997(5)2016) 													 ///
	   ytitle($ytitle1) 				 									 ///
	   legend(label(1 $label1) label(2 $label2) position(6) rows(1)) nodraw
	   graph rename ECU_synth, replace
	   
twoway bar 	ECU_effect year if id==13, color(gray%50) xline(2006)	 		 ///
	   yline(0, lpattern(solid))											 ///
	   xlabel(1997(5)2016)													 ///
	   ytitle($ytitle2) nodraw
	   graph rename ECU_effect, replace
 
	
graph combine ECU_synth ECU_effect, xcommon rows(2)	ysize(8)	 
graph export Figures/Fig_ECU.png, replace
graph drop _all


keep if country_code == "ECU"
drop if year > 2017
rename year		ECU_year
rename VDEMy	ECU_VDEMy
drop VDEM1 VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 WGI1 WGI2 WGI3
drop ICRG polity EFW populist id country country_code
generate t = _n - 11, before(ECU_year)

merge 1:1 t using data_avg
drop _merge
save data_avg, replace


**#| Nicaragua
***|----------------------------------------------------------------------------
use data.dta, clear

drop if country_code=="ARG"	
drop if country_code=="BOL"
drop if country_code=="ECU"
drop if country_code=="VEN"

drop if year < 1996
drop if year > 2015


parallel numprocessors	// 8 processors
parallel initialize 6

global convergence	 = "nested allopt technique(nr)"
global predictors    = "VDEM1 VDEM2 VDEM4 VDEM5 VDEM6 WGI1 ICRG FH_CL"
global pre_treatment = "VDEMy(1996) VDEMy(2001) VDEMy(2002) VDEMy(2004)"
global treat_y       = "2006"
global x_axis		 = "1996(1)2015"

/*
synth VDEMy $predictors $pre_treatment, trunit(21) trperiod($treat_y)	 ///
	  unitnames(country) resultsperiod($x_axis)	
*/
    
synth_runner VDEMy $predictors $pre_treatment,								 ///
			 trunit(21) trperiod($treat_y)			 						 ///
			 gen_vars parallel				 								 ///
			 synthsettings(unitnames(country))								 ///
			 graphs


rename 	VDEMy_synth	NIC_SCA
rename 	effect		NIC_effect
drop	pre_rmspe
drop	post_rmspe
drop 	lead

label variable	NIC_SCA "Nicaragua"


global title	= "V-Dem: Liberal Democracy Index in Nicaragua"
global ytitle1	= "V-Dem: Liberal Democracy Index (0-100)"
global ytitle2  = "Synthetic effect"
global label1	= "Nicaragua"
global label2	= "Synthetic Nicaragua"

twoway line VDEMy	   year if id==21, lpattern(solid) 						 ///
	|| line NIC_SCA    year if id==21, lpattern(dash)  xline(2005)			 ///
	   xlabel(1996(5)2015) 													 ///
	   ytitle($ytitle1) 				 									 ///
	   legend(label(1 $label1) label(2 $label2) position(6) rows(1)) nodraw
	   graph rename NIC_synth, replace
	   
twoway bar 	NIC_effect year if id==21, color(gray%50) xline(2005)	 		 ///
	   yline(0, lpattern(solid))											 ///
	   xlabel(1996(5)2015)													 ///
	   ytitle($ytitle2) nodraw
	   graph rename NIC_effect, replace
 
	
graph combine NIC_synth NIC_effect, xcommon rows(2)	ysize(8)
graph export Figures/Fig_NIC.png, replace	
graph drop _all


keep if country_code == "NIC"
rename year		NIC_year
rename VDEMy	NIC_VDEMy
drop VDEM1 VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 WGI1 WGI2 WGI3
drop ICRG polity EFW populist id country country_code
generate t = _n - 11, before(NIC_year)

merge 1:1 t using data_avg
drop _merge
save data_avg, replace


**#| Venezuela
***|----------------------------------------------------------------------------
use data.dta, clear

drop if country_code=="ARG"	
drop if country_code=="BOL"
drop if country_code=="ECU"
drop if country_code=="NIC"

drop if year < 1989
drop if year > 2007


parallel numprocessors	// 8 processors
parallel initialize 6

global convergence	 = "nested allopt technique(nr)"
global predictors    = "VDEM6 WGI1 WGI3 ICRG polity2 FH_PR FH_CL"
global pre_treatment = "VDEMy(1989) VDEMy(1991) VDEMy(1994) VDEMy(1998)"
global treat_y       = "1999"
global x_axis		 = "1989(1)2007"

/*
synth VDEMy $predictors $pre_treatment, trunit(32) trperiod($treat_y)	 ///
	  unitnames(country) resultsperiod($x_axis)
*/
    
synth_runner VDEMy $predictors $pre_treatment,								 ///
			 trunit(32) trperiod($treat_y)			 						 ///
			 gen_vars parallel				 								 ///
			 synthsettings(unitnames(country))								 ///
			 graphs


rename 	VDEMy_synth	VEN_SCA
rename 	effect		VEN_effect
drop	pre_rmspe
drop	post_rmspe
drop 	lead

label variable	VEN_SCA "Venezuela"


global title	= "V-Dem: Liberal Democracy Index in Venezuela"
global ytitle1	= "V-Dem: Liberal Democracy Index (0-100)"
global ytitle2  = "Synthetic effect"
global label1	= "Venezuela"
global label2	= "Synthetic Venezuela"

twoway line VDEMy	   year if id==32, lpattern(solid) 						 ///
	|| line VEN_SCA    year if id==32, lpattern(dash)  xline(1998)			 ///
	   xlabel(1988(5)2008) 													 ///
	   ytitle($ytitle1) 				 									 ///
	   legend(label(1 $label1) label(2 $label2) position(6) rows(1)) nodraw
	   graph rename VEN_synth, replace
	   
twoway bar 	VEN_effect year if id==32, color(gray%50) xline(1998)	 		 ///
	   yline(0, lpattern(solid))											 ///
	   xlabel(1988(5)2008)													 ///
	   ytitle($ytitle2) nodraw
	   graph rename VEN_effect, replace
 
	
graph combine VEN_synth VEN_effect, xcommon rows(2)	ysize(8)	
graph export Figures/Fig_VEN.png, replace
graph drop _all
			 

keep if country_code == "VEN"
rename year		VEN_year
rename VDEMy	VEN_VDEMy
drop VDEM1 VDEM2 VDEM3 VDEM4 VDEM5 VDEM6 WGI1 WGI2 WGI3
drop ICRG polity EFW populist id country country_code
generate t = _n - 11, before(VEN_year)

merge 1:1 t using data_avg
drop _merge
save data_avg, replace


***|============================================================================
**#| AVERAGE PLOTS
***|----------------------------------------------------------------------------
use data_avg, clear

gen VDEMy  = (ARG_VDEMy  + BOL_VDEMy  + ECU_VDEMy  + NIC_VDEMy  + VEN_VDEMy) /5
gen synth  = (ARG_SCA    + BOL_SCA    + ECU_SCA    + NIC_SCA    + VEN_SCA)   /5
gen EFFECT = VDEMy - synth


global ytitle = "Average V-DEM: Liberal Democracy Index (0-100)"
twoway line VDEMy t, lpattern(solid)										 ///
	|| line synth t, lpattern(dash)  										 ///
	   xline(-1) xlabel(-10(2)10) ylabel(30(5)60) legend(off)				 ///
	   ytitle($ytitle) nodraw
	   graph rename avg_synth, replace
	   
global ytitle = "Average synthetic effect"	   
twoway bar 	EFFECT t, color(gray%50) xline(-1) 								 ///
	   yline(0, lpattern(solid))											 ///
	   xlabel(-10(2)10)	ylabel(-30(5)10)									 ///
	   ytitle($ytitle) nodraw
	   graph rename avg_effect, replace
	   

graph combine avg_synth avg_effect, xcommon rows(2)	ysize(8)	
graph export Figures/Fig_average.png, replace
graph drop _all