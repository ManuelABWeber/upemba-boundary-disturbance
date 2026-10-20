source("analysis/dependence_sensitivity/paths.R")
library(data.table)
library(clubSandwich)
out<-dependence_output()
counts<-fread(file.path(out,"count_validation.csv"))
chron<-fread("data/dependence_sensitivity/profile_chronology.csv")
profiles<-c("Neither actor dominant","Militia dominant","Park dominant")
res<-list()
for(population in c("reported_all_cells","baseline_forest_only")) {
if(population=="baseline_forest_only")counts<-fread(file.path(out,"tree_forest_only_counts.csv"))
dd<-counts[outcome=="tree_cover_loss"&center==0]
wide<-dcast(dd,group+year~side,value.var=c("n","y"))
wide[,`:=`(D=log((y_1+.5)/(n_1-y_1+.5))-log((y_0+.5)/(n_0-y_0+.5)),
     w=1/(1/(y_1+.5)+1/(n_1-y_1+.5)+1/(y_0+.5)+1/(n_0-y_0+.5)))]
wide<-merge(wide,chron[,.(group=SESU_ID,year,governance_profile)],by=c("group","year"))
wide[,profile:=factor(governance_profile,levels=profiles)]
# Centering the group indicator makes each profile coefficient the same
# equally weighted two-landscape contrast as the approved model.
wide[,plateau_centered:=as.numeric(group==3)-.5]
m<-lm(D~0+profile+plateau_centered,weights=w,data=wide)
ref<-fread(file.path(out,"tree_baseline_estimates.csv"))[center==0]
pop_value<-population
ref<-ref[population==pop_value][match(profiles,profile)]
stopifnot(max(abs(coef(m)[1:3]-ref$estimate))<1e-10)
for(years_per_cluster in 1:3) {
  for(offset in 0:(years_per_cluster-1)) {
    cluster<-floor((wide$year-2001+offset)/years_per_cluster)
    V<-vcovCR(m,cluster=cluster,type="CR2",inverse_var=TRUE)
    result<-as.data.table(conf_int(m,vcov=V,coefs=1:3,test="Satterthwaite"))
    result[,`:=`(population=pop_value,profile=profiles,years_per_cluster=years_per_cluster,origin_offset=offset,nclusters=length(unique(cluster)))]
    res[[length(res)+1L]]<-result
  }
}
}
fwrite(rbindlist(res,fill=TRUE),file.path(out,"tree_small_sample_temporal.csv"))
print(rbindlist(res,fill=TRUE))
capture.output(sessionInfo(),file=file.path(out,"small_sample_sessionInfo.txt"))
