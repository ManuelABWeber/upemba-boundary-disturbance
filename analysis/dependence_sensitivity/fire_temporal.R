source("analysis/dependence_sensitivity/fire_core.R")
out<-dependence_output()
meta<-fread(file.path(out,"surface_columns.csv"))
info_lines<-readLines(file.path(out,"blocks_10km_shift0.json"))
nt<-as.integer(gsub("[^0-9]","",grep('"ntiles":',info_lines,value=TRUE,fixed=TRUE)))
N<-matrix(readBin(file.path(out,"fire_n_10km_shift0.bin"),integer(),n=nt*nrow(meta),size=4,endian="little"),nrow=nt)
Y<-matrix(readBin(file.path(out,"fire_y_10km_shift0.bin"),integer(),n=nt*nrow(meta),size=4,endian="little"),nrow=nt)
meta[,`:=`(n=colSums(N),y=colSums(Y))]
intervals<-list();influence<-list();diagnostics<-list();baselines<-list();annual_contributions<-list()
for(center_value in unique(meta$center)) {
  d<-copy(meta[center==center_value])
  m<-fit_fire(d,keep_scores=TRUE);stopifnot(m$valid)
  baselines[[as.character(center_value)]]<-m$estimate
  bread<-solve(m$H)
  annual<-rowsum(m$scores,d$year,reorder=TRUE)
  contribution<-annual%*%bread%*%t(m$L)
  annual_contributions[[as.character(center_value)]]<-contribution
  for(lag in 0:4) {
    V<-crossprod(contribution)
    if(lag>0)for(ll in seq_len(lag)) {
      C<-crossprod(contribution[(ll+1):22,,drop=FALSE],contribution[1:(22-ll),,drop=FALSE])
      V<-V+(1-ll/(lag+1))*(C+t(C))
    }
    V<-V*22/21
    se<-sqrt(pmax(0,diag(V)))
    intervals[[length(intervals)+1L]]<-data.table(center=center_value,method="calendar-year score HAC",lag_years=lag,
      profile=profiles,estimate=m$estimate,se=se,low=m$estimate-qt(.975,21)*se,high=m$estimate+qt(.975,21)*se)
  }
  if(center_value==0) {
    fwrite(cbind(d,data.table(fitted=as.numeric(predict(m$model,type="response")))),file.path(out,"fire_fitted_surface.csv"))
    for(yr in 2001:2022) {
      mm<-fit_fire(d[year!=yr]);stopifnot(mm$valid)
      influence[[length(influence)+1L]]<-data.table(omitted_year=yr,profile=profiles,estimate=mm$estimate,change=mm$estimate-m$estimate)
    }
    loo<-rbindlist(influence)
    loomat<-as.matrix(dcast(loo,omitted_year~profile,value.var="estimate")[,profiles,with=FALSE])
    centered<-scale(loomat,center=TRUE,scale=FALSE)
    Vj<-21/22*crossprod(centered);sej<-sqrt(diag(Vj))
    intervals[[length(intervals)+1L]]<-data.table(center=0,method="delete-year jackknife",lag_years=NA_integer_,
      profile=profiles,estimate=m$estimate,se=sej,low=m$estimate-qt(.975,21)*sej,high=m$estimate+qt(.975,21)*sej)
    for(p in seq_len(3))for(lag in 1:4)diagnostics[[length(diagnostics)+1L]]<-data.table(
      profile=profiles[p],lag_years=lag,annual_influence_correlation=cor(contribution[(lag+1):22,p],contribution[1:(22-lag),p]))
    fwrite(data.table(year=2001:2022,contribution),file.path(out,"fire_annual_influence.csv"))
  }
  cat("Fire temporal checks, boundary",center_value,"complete\n")
}
diffs<-list()
for(center_value in as.integer(names(annual_contributions))[-1]) {
  contribution<-annual_contributions[["0"]]-annual_contributions[[as.character(center_value)]]
  est<-baselines[["0"]]-baselines[[as.character(center_value)]]
  for(lag in 0:4) {
    V<-crossprod(contribution)
    if(lag>0)for(ll in seq_len(lag)) {
      C<-crossprod(contribution[(ll+1):22,,drop=FALSE],contribution[1:(22-ll),,drop=FALSE])
      V<-V+(1-ll/(lag+1))*(C+t(C))
    }
    se<-sqrt(pmax(0,diag(V*22/21)))
    diffs[[length(diffs)+1L]]<-data.table(outer_center=center_value,lag_years=lag,profile=profiles,
      estimate=est,low=est-qt(.975,21)*se,high=est+qt(.975,21)*se)
  }
}
fwrite(rbindlist(intervals),file.path(out,"fire_temporal_intervals.csv"))
fwrite(rbindlist(influence),file.path(out,"fire_leave_year_out.csv"))
fwrite(rbindlist(diagnostics),file.path(out,"fire_temporal_diagnostics.csv"))
fwrite(rbindlist(diffs),file.path(out,"fire_temporal_boundary_differences.csv"))
print(rbindlist(intervals)[center==0])
