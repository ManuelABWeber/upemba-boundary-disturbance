source("analysis/dependence_sensitivity/fire_core.R")
read_block_info<-function(path) {
  lines<-readLines(path)
  getnum<-function(key)as.numeric(gsub("[^0-9.\\-]","",grep(paste0('"',key,'":'),lines,value=TRUE,fixed=TRUE)))
  setNames(lapply(c("ntiles","ncolumns","block_km","origin_fraction"),getnum),c("ntiles","ncolumns","block_km","origin_fraction"))
}
args<-commandArgs(TRUE)
mode<-if(length(args))args[1] else "pilot"
B<-if(length(args)>1)as.integer(args[2]) else if(mode=="pilot")50L else 999L
stopifnot(mode %in% c("pilot","main","outer","longrange"), B>=1L)
out<-dependence_output()
metadata<-fread(file.path(out,"surface_columns.csv"))
configs<-if(mode=="pilot")"5km_shift0" else if(mode=="outer")"10km_shift0" else if(mode=="longrange")c("40km_shift0","40km_shift50") else c("5km_shift0","10km_shift0","20km_shift0","5km_shift50","10km_shift50","20km_shift50")
baseline_results<-list()
for(tag in configs) {
  info<-read_block_info(file.path(out,paste0("blocks_",tag,".json")))
  N<-matrix(readBin(file.path(out,paste0("fire_n_",tag,".bin")),integer(),n=info$ntiles*info$ncolumns,size=4,endian="little"),nrow=info$ntiles)
  Y<-matrix(readBin(file.path(out,paste0("fire_y_",tag,".bin")),integer(),n=info$ntiles*info$ncolumns,size=4,endian="little"),nrow=info$ntiles)
  if(mode!="outer") {N<-N[,1:88];Y<-Y[,1:88];meta<-metadata[1:88]} else meta<-copy(metadata)
  active<-rowSums(N)>0;N<-N[active,,drop=FALSE];Y<-Y[active,,drop=FALSE]
  centers<-unique(meta$center)
  baseline<-list()
  for(center in centers) {
    sel<-which(meta$center==center)
    d<-copy(meta[sel]);d[,`:=`(n=colSums(N[,sel,drop=FALSE]),y=colSums(Y[,sel,drop=FALSE]))]
    ff<-fit_fire(d,keep_scores=TRUE)
    stopifnot(ff$valid)
    baseline[[as.character(center)]]<-ff
    baseline_results[[length(baseline_results)+1L]]<-data.table(tag=tag,center=center,profile=profiles,estimate=ff$estimate,auto_gradient=ff$auto_gradient,analytic_gradient=ff$analytic_gradient,min_eigen=ff$min_eigen)
    if(center==0L&&tag=="5km_shift0") {
      ref<-fread("outputs/final_robustness/baseline_primary_results.csv")[outcome=="fire"]
      stopifnot(max(abs(ff$estimate-ref[match(profiles,governance_profile),estimate]))<1e-5)
      saveRDS(ff,file.path(out,"fire_main_validated.rds"))
      fwrite(cbind(d,as.data.table(ff$scores)),file.path(out,"fire_scores.csv"))
    }
  }
  fwrite(rbindlist(baseline_results),file.path(out,paste0("fire_",mode,"_baseline.csv")))
  set.seed(48291L+as.integer(info$block_km)*100L+as.integer(info$origin_fraction*100))
  draws<-list();diag<-list()
  t0<-proc.time()[3]
  for(rep in seq_len(B)) {
    w<-as.integer(rmultinom(1,nrow(N),rep(1/nrow(N),nrow(N))))
    nn<-drop(crossprod(w,N));yy<-drop(crossprod(w,Y))
    for(center in centers) {
      sel<-which(meta$center==center)
      d<-copy(meta[sel]);d[,`:=`(n=nn[sel],y=yy[sel])]
      ff<-fit_fire(d,start=baseline[[as.character(center)]]$start)
      if(!ff$valid)ff<-fit_fire(d)
      diag[[length(diag)+1L]]<-data.table(replicate=rep,tag=tag,center=center,valid=ff$valid,reason=ff$reason,
        auto_gradient=if(is.null(ff$auto_gradient))NA_real_ else ff$auto_gradient,
        analytic_gradient=if(is.null(ff$analytic_gradient))NA_real_ else ff$analytic_gradient,
        min_eigen=if(is.null(ff$min_eigen))NA_real_ else ff$min_eigen)
      if(ff$valid)draws[[length(draws)+1L]]<-data.table(replicate=rep,tag=tag,center=center,profile=profiles,estimate=ff$estimate)
    }
    if(rep%%25L==0L||rep==B) {
      elapsed<-proc.time()[3]-t0
      cat(mode,tag,rep,"/",B,"seconds",round(elapsed,1),"ETA minutes",round(elapsed/rep*(B-rep)/60,1),"\n")
      fwrite(rbindlist(draws),file.path(out,paste0("fire_",mode,"_",tag,"_draws.csv")))
      fwrite(rbindlist(diag),file.path(out,paste0("fire_",mode,"_",tag,"_diagnostics.csv")))
      writeLines(sprintf('{"mode":"%s","tag":"%s","completed":%d,"total":%d,"elapsed_seconds":%.3f,"failures":%d,"updated":"%s"}',
        mode,tag,rep,B,elapsed,sum(!rbindlist(diag)$valid),format(Sys.time(),tz="UTC",usetz=TRUE)),
        file.path(out,paste0("fire_",mode,"_progress.json")))
    }
  }
  dd<-rbindlist(draws)
  intervals<-dd[,.(low=quantile(estimate,.025),high=quantile(estimate,.975),retained=.N),by=.(tag,center,profile)]
  config_tag<-tag
  intervals<-merge(intervals,rbindlist(baseline_results)[tag==config_tag,.(tag,center,profile,estimate)],by=c("tag","center","profile"))
  fwrite(intervals,file.path(out,paste0("fire_",mode,"_",tag,"_intervals.csv")))
  print(intervals)
}
capture.output(sessionInfo(),file=file.path(out,paste0("fire_",mode,"_sessionInfo.txt")))
