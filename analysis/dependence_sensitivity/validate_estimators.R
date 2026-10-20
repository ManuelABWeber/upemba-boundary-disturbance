source("analysis/dependence_sensitivity/fire_core.R")
library(sandwich)
out<-dependence_output()
counts<-fread(file.path(out,"count_validation.csv"))
python<-fread(file.path(out,"tree_baseline_estimates.csv"))[population=="reported_all_cells"]
original<-fread("analysis_spatial_falsification_revised_dev/tables/sparse_boundary_profile_estimates.csv")[outcome=="tree_cover_loss"&threshold_tag=="tau025"]
chron<-fread("data/dependence_sensitivity/profile_chronology.csv")
checks<-list()
for(center_value in unique(counts$center)) {
  dd<-counts[outcome=="tree_cover_loss"&center==center_value]
  wide<-dcast(dd,group+year~side,value.var=c("n","y"))
  wide[,`:=`(D=log((y_1+.5)/(n_1-y_1+.5))-log((y_0+.5)/(n_0-y_0+.5)),
     w=1/(1/(y_1+.5)+1/(n_1-y_1+.5)+1/(y_0+.5)+1/(n_0-y_0+.5)))]
  wide<-merge(wide,chron[,.(group=SESU_ID,year,governance_profile)],by=c("group","year"))
  wide[,profile:=factor(governance_profile,levels=profiles)]
  wide[,plateau:=as.numeric(group==3)]
  m<-lm(D~0+profile+plateau,weights=w,data=wide)
  contrast<-cbind(diag(3),.5)
  estimate<-drop(contrast%*%coef(m))
  se<-sqrt(diag(contrast%*%vcovHC(m,type="HC3")%*%t(contrast)))
  ref<-original[boundary_center_km==center_value][match(profiles,governance_profile)]
  py<-python[center==center_value][match(profiles,profile)]
  checks[[length(checks)+1L]]<-data.table(center=center_value,profile=profiles,
    r_estimate=estimate,python_estimate=py$estimate,original_estimate=ref$estimate,
    original_se=ref$standard_error,r_hc3_se=se,
    estimate_delta=estimate-py$estimate,se_delta=se-ref$standard_error)
}
check<-rbindlist(checks)
stopifnot(max(abs(check$estimate_delta))<1e-10,max(abs(check$se_delta))<1e-10)
fwrite(check,file.path(out,"independent_tree_validation.csv"))
# Compare the newly polished fire estimator against every retained point estimate.
fire<-fread(file.path(out,"fire_outer_baseline.csv"))
fire_ref<-fread("analysis_spatial_falsification_revised_dev/tables/fire_boundary_profile_contrasts.csv")
ref<-fire_ref[,.(center=boundary_center_km,profile=governance_profile,reference_estimate=estimate)]
fire<-merge(fire,ref,by=c("center","profile"))
fire[,difference:=estimate-reference_estimate]
stopifnot(nrow(fire)==33,max(abs(fire$difference))<1e-5)
fwrite(fire,file.path(out,"independent_fire_validation.csv"))
cat("Independent R tree estimates and HC3 covariance match all retained boundaries.\n")
cat("Maximum fire contrast difference from retained results:",max(abs(fire$difference)),"\n")
