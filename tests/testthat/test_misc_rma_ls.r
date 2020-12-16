### library(metafor); library(testthat); Sys.setenv(NOT_CRAN="true")

context("Checking misc: location-scale models")

source("tolerances.r") # read in tolerances

dat <- dat.bangertdrowns2004

test_that("location-scale model works correctly for an intercept-only model", {

   res1 <- rma(yi, vi, data=dat)
   res2 <- rma.mv(yi, vi, random = ~ 1 | id, data=dat)
   res3 <- rma(yi, vi, data=dat, scale = ~ 1)
   res4 <- rma(yi, vi, data=dat, scale = res3$Z)

   expect_equivalent(res1$tau2, res2$sigma2, tolerance=.tol[["var"]])
   expect_equivalent(res1$tau2, exp(res3$alpha[1]), tolerance=.tol[["var"]])
   expect_equivalent(res1$tau2, exp(res4$alpha[1]), tolerance=.tol[["var"]])

})

test_that("location-scale model works correctly for two subgroups with different tau^2 values", {

   res1 <- rma.mv(yi, vi, data=dat, random = ~ factor(meta) | id, struct="DIAG", subset=!is.na(meta), control=list(hessian=TRUE, vctransf=TRUE))
   expect_warning(res2 <- rma(yi, vi, data=dat, scale = ~ meta))
   expect_warning(res3 <- rma(yi, vi, data=dat, scale = res2$Z.f))

   expect_equivalent(res1$tau2, c(exp(res2$alpha[1]), exp(res2$alpha[1] + res2$alpha[2])), tolerance=.tol[["var"]])
   expect_equivalent(res1$tau2, c(exp(res3$alpha[1]), exp(res3$alpha[1] + res3$alpha[2])), tolerance=.tol[["var"]])

   expect_warning(res4 <- rma(yi, vi, data=dat, scale = ~  0 + factor(meta)))

   expect_equivalent(unname(sqrt(diag(solve(res1$hessian[1:2, 1:2])))), res4$se.alpha, tolerance=.tol[["se"]])

   expect_warning(res5 <- rma(yi, vi, data=dat, scale = ~  0 + factor(meta), link="identity"))
   expect_equivalent(res1$tau2, res5$alpha, tolerance=.tol[["var"]])

   conf1 <- confint(res1)
   conf5 <- confint(res5, control=list(vc.min=0, vc.max=.5))
   expect_equivalent(conf1[[1]]$random[1,], conf5[[1]]$random, tolerance=.tol[["var"]])
   expect_equivalent(conf1[[2]]$random[1,], conf5[[2]]$random, tolerance=.tol[["var"]])

})

test_that("profile() and confint() work correctly for location-scale models", {

   opar <- par(no.readonly=TRUE)

   par(mfrow=c(2,2))

   res1  <- rma(yi, vi, data=dat)
   prof1 <- profile(res1, progbar=FALSE, cline=TRUE, xlim=c(.01,.15))
   conf1 <- confint(res1, type="PL")
   abline(v=conf1$random[1,2:3], lty="dotted")

   res2  <- rma.mv(yi, vi, random = ~ 1 | id, data=dat)
   prof2 <- profile(res2, progbar=FALSE, cline=TRUE, xlim=c(.01,.15))
   conf2 <- confint(res2)
   abline(v=conf2$random[1,2:3], lty="dotted")

   expect_equivalent(prof1$ll, prof2$ll, tolerance=.tol[["fit"]])
   expect_equivalent(conf1$random[1,], conf2$random[1,], tolerance=.tol[["var"]])

   res3  <- rma(yi, vi, data=dat, scale = ~ 1)
   prof3 <- profile(res3, progbar=FALSE, cline=TRUE, xlim=log(c(.01,.15)))
   conf3 <- confint(res3)
   abline(v=conf3$random[1,2:3], lty="dotted")

   expect_equivalent(prof1$ll[c(1,20)], prof3$ll[c(1,20)], tolerance=.tol[["fit"]])
   expect_equivalent(conf1$random[1,], exp(conf3$random), tolerance=.tol[["var"]])

   expect_warning(res4 <- rma(yi, vi, data=dat, scale = ~ 1, link="identity"))
   prof4 <- profile(res4, progbar=FALSE, cline=TRUE, xlim=c(.01,.15))
   conf4 <- confint(res4, control=list(vc.max=.2))
   abline(v=conf4$random[1,2:3], lty="dotted")

   expect_equivalent(prof1$ll, prof4$ll, tolerance=.tol[["fit"]])
   expect_equivalent(conf1$random[1,], conf4$random, tolerance=.tol[["var"]])

   par(opar)

})

test_that("location-scale model works correctly for a continuous predictor", {

   opar <- par(no.readonly=TRUE)

   par(mfrow=c(3,2))

   res1 <- rma(yi, vi, data=dat, scale = ~ grade)
   expect_equivalent(res1$beta, 0.2220791, tolerance=.tol[["coef"]])
   expect_equivalent(res1$alpha, c(-3.10513013522415, 0.041361925354706), tolerance=.tol[["coef"]])

   res2 <- rma(yi, vi, data=dat, scale = ~ grade, link="identity")
   expect_equivalent(res1$tau2, res2$tau2, tolerance=.tol[["var"]])

   res3 <- rma.mv(yi, vi, data=dat, random = ~ sqrt(grade) | id, rho=0, struct="GEN", control=list(hessian=TRUE, vctransf=FALSE))
   expect_equivalent(c(res2$alpha), diag(res3$G), tolerance=.tol[["coef"]])
   expect_equivalent(diag(res2$M),  diag(res3$M), tolerance=.tol[["var"]])
   expect_equivalent(unname(sqrt(diag(solve(res3$hessian[1:2, 1:2])))), res2$se.alpha, tolerance=.tol[["se"]])

   conf1 <- confint(res1)
   expect_equivalent(conf1[[1]]$random, c(-3.10513, -5.25032, -1.21713), tolerance=.tol[["var"]])
   expect_equivalent(conf1[[2]]$random, c( 0.04136, -0.65819,  0.69562), tolerance=.tol[["var"]])

   profile(res1, alpha=1, progbar=FALSE, cline=TRUE)
   abline(v=conf1[[1]]$random[2:3], lty="dotted")
   profile(res1, alpha=2, progbar=FALSE, cline=TRUE)
   abline(v=conf1[[2]]$random[2:3], lty="dotted")

   conf21 <- confint(res2, alpha=1, control=list(vc.min=-0.4, vc.max=0.3))
   conf22 <- confint(res2, alpha=2, control=list(vc.min=-0.1, vc.max=0.05))
   conf2  <- list(conf21, conf22)
   class(conf2) <- "list.confint.rma"
   expect_equivalent(conf2[[1]]$random, c(0.04293, -0.00137, 0.23145), tolerance=.tol[["var"]])
   expect_equivalent(conf2[[2]]$random, c(0.00273, -0.04972, 0.04411), tolerance=.tol[["var"]])

   profile(res2, alpha=1, progbar=FALSE, cline=TRUE, xlim=c(0,0.3))
   abline(v=conf2[[1]]$random[2:3], lty="dotted")
   profile(res2, alpha=2, progbar=FALSE, cline=TRUE, xlim=c(-0.1,0.05))
   abline(v=conf2[[2]]$random[2:3], lty="dotted")

   conf3 <- confint(res3)
   expect_equivalent(conf3[[1]]$random[1,], c(0.04291, 0.00000, 0.11333), tolerance=.tol[["var"]])
   expect_equivalent(conf3[[2]]$random[1,], c(0.00273, 0.00000, 0.04062), tolerance=.tol[["var"]])

   profile(res3, tau2=1, progbar=FALSE, cline=TRUE, xlim=c(0,.3))
   abline(v=conf3[[1]]$random[1,2:3], lty="dotted")
   profile(res3, tau2=2, progbar=FALSE, cline=TRUE, xlim=c(0,.05))
   abline(v=conf3[[2]]$random[1,2:3], lty="dotted")

   # conf2 and conf3 are not the same because in res3 the two components must
   # be >= 0 while this restriction does not apply to res2 (and when profiling
   # or getting the CIs, fixing a particular component can lead to the other
   # component becoming negative)

   par(opar)

})

test_that("location-scale model works correctly for multiple predictors", {

   expect_warning(res1 <- rma(yi, vi, data=dat, scale = ~ grade + meta + sqrt(ni)))
   expect_equivalent(res1$beta, 0.1110317, tolerance=.tol[["coef"]])
   expect_equivalent(res1$alpha, c(-1.08826059, -0.03429344, 2.09197456, -0.28439165), tolerance=.tol[["coef"]])

   expect_warning(res2 <- rma(yi, vi, data=dat, scale = ~ grade + meta + sqrt(ni), control=list(scaleZ=FALSE)))
   expect_equivalent(res2$beta, 0.1110317, tolerance=.tol[["coef"]])
   expect_equivalent(res2$alpha, c(-1.08826210, -0.03429332, 2.09197501, -0.28439156), tolerance=.tol[["coef"]])

   out <- capture.output(print(res1))

})
