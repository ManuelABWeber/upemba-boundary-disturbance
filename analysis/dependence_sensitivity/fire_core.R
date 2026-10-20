source("analysis/dependence_sensitivity/paths.R")
library(data.table)
library(glmmTMB)
profiles <- c("Neither actor dominant","Militia dominant","Park dominant")
fire_formula <- cbind(y,n-y)~0+sesu_year+side+inside_profile_militia+inside_profile_park
prepare_fire <- function(d) {
  d<-copy(d)
  d[,side:=factor(side,levels=c("outside","inside"))]
  d[,`:=`(inside_profile_militia=as.integer(side=="inside"&governance_profile==profiles[2]),
           inside_profile_park=as.integer(side=="inside"&governance_profile==profiles[3]),
           sesu_year=interaction(SESU_ID,year,drop=TRUE))]
  d
}
fire_scores <- function(m,par=NULL) {
  X<-model.matrix(m);response<-model.response(model.frame(m))
  yy<-response[,1];nn<-rowSums(response)
  if(is.null(par))par<-m$fit$par
  beta<-par[names(par)=="beta"];phi<-exp(par[names(par)=="betadisp"])
  mu<-plogis(drop(X%*%beta));a<-mu*phi;b<-(1-mu)*phi
  A<-digamma(yy+a)-digamma(a);B<-digamma(nn-yy+b)-digamma(b);C<-digamma(phi)-digamma(nn+phi)
  cbind(X*as.vector(phi*mu*(1-mu)*(A-B)),as.vector(phi*(mu*A+(1-mu)*B+C)))
}
polished_optimizer <- function(par,fn,gr,control=list(),...) {
  initial<-nlminb(par,fn,gr,control=list(iter.max=1000,eval.max=2000,rel.tol=1e-10,x.tol=1e-9))
  pp<-initial$par
  for(iter in seq_len(15)) {
    gg<-as.numeric(gr(pp))
    if(max(abs(gg))<1e-7)break
    H<-optimHess(pp,fn,gr)
    step<-tryCatch(solve(H,gg),error=function(e)rep(NA_real_,length(pp)))
    if(any(!is.finite(step)))break
    accepted<-FALSE
    for(frac in 2^-(0:12)) {
      candidate<-pp-frac*step
      if(all(is.finite(candidate))&&max(abs(gr(candidate)))<max(abs(gg))&&fn(candidate)<=fn(pp)+1e-6) {
        pp<-candidate;accepted<-TRUE;break
      }
    }
    if(!accepted)break
  }
  good<-max(abs(gr(pp)))<1e-5
  list(par=pp,objective=fn(pp),convergence=if(good)0L else 1L,iterations=initial$iterations+iter,
       evaluations=initial$evaluations,message=if(good)"Analytic-gradient convergence after Newton refinement" else "Gradient criterion not met")
}
fit_fire <- function(d,start=NULL,keep_scores=FALSE) {
  d<-prepare_fire(d)
  warnings<-character()
  m<-withCallingHandlers(tryCatch(glmmTMB(fire_formula,data=d,family=betabinomial("logit"),
       start=start,control=glmmTMBControl(optimizer=polished_optimizer,rank_check="stop")),error=function(e)e),
       warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")})
  if(inherits(m,"error"))return(list(valid=FALSE,reason=conditionMessage(m)))
  auto<-as.numeric(m$obj$gr(m$fit$par));scores<-fire_scores(m);analytic<--colSums(scores)
  H<-optimHess(m$fit$par,m$obj$fn,m$obj$gr)
  eig<-eigen(H,symmetric=TRUE,only.values=TRUE)$values
  good<-m$fit$convergence==0&&isTRUE(m$sdr$pdHess)&&all(is.finite(m$fit$par))&&
        min(eig)>0&&max(abs(auto))<1e-5&&max(abs(analytic))<1e-5&&max(abs(auto-analytic))<1e-6
  b<-fixef(m)$cond
  L<-matrix(0,3,length(m$fit$par))
  idx<-which(names(b)=="sideinside");L[,idx]<-1
  L[2,which(names(b)=="inside_profile_militia")]<-1
  L[3,which(names(b)=="inside_profile_park")]<-1
  est<-drop(L%*%m$fit$par)
  list(valid=good,reason=if(good)"" else paste("gradient",max(abs(auto)),"analytic",max(abs(analytic)),"eigen",min(eig)),
       estimate=est,start=list(beta=unname(b),betadisp=unname(fixef(m)$disp)),model=m,
       auto_gradient=max(abs(auto)),analytic_gradient=max(abs(analytic)),gradient_agreement=max(abs(auto-analytic)),
       min_eigen=min(eig),H=H,L=L,scores=if(keep_scores)scores else NULL,warnings=paste(unique(warnings),collapse=";"))
}
