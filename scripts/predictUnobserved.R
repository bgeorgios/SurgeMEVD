# load packages
packages <-
  c("dplyr",
    "extRemes",
    "lubridate",
    "fitdistrplus")

load.packages <- lapply(packages, library, character.only = TRUE)

# function to be used for fitting the MEVD
fun <- function(par, data) {
  zeta <- 0
  
  for (y in train.years) {
    ny <- length(which(year(data[["Time"]]) == y))
    idc <- which(year(data[["Time"]]) == y)
    # change "ordinary" distribution and estimation method accordingly...
    fit <- fitdist(data[["Surge"]], "gamma", method = c("mme"))
    zeta <-
      zeta + pgamma(par[1], shape = fit[["estimate"]][1], scale = 1 / fit[["estimate"]][2]) ** ny
  }
  
  zeta <- zeta / length(train.years)
  error <- (pr - zeta) ** 2
  
  return(error)
}

# opposite of "in" function
"%nin%" <- Negate("%in%")

# set seed
set.seed(1999)

# set calibration sample size (years)
c <- 10

# read surge annual maxima
bm <-
  read.csv("Boston-surge-annual-maxima.csv")

# read "ordinary" surge data
ord <-
  read.csv("Boston-surge-ordinary.csv")

# initialize dataframe to store predictive error and bias
error.data <-
  data.frame(
    OBS = rep(NA, 1000),
    GEV = rep(NA, 1000),
    MEVD = rep(NA, 1000),
    GEV.BIAS = rep(NA, 1000),
    MEVD.BIAS = rep(NA, 1000),
    GEV.NDE = rep(NA, 1000),
    MEVD.NDE = rep(NA, 1000)
  )

# do cross-validation, i.e., iteratively predict out-of-sample
for (sim in 1:1000) {
  train.years <- sample(bm[['Year']], c, replace = FALSE)
  test.years <-
    bm[["Year"]][which(bm[["Year"]] %nin% train.years)]
  bm.train <-
    bm[['Surge']][which(bm[["Year"]] %in% train.years)]
  bm.test <-
    bm[['Surge']][which(bm[["Year"]] %in% test.years)]
  bm.test <- sort(bm.test)
  rank.test <- (seq(1, length(bm.test)) / (length(bm.test) + 1))
  rp.test <- 1 / (1 - rank.test)
  rp <- rp.test[length(rp.test)]
  pr <- rank.test[length(rank.test)]
  rl <- bm.test[length(bm.test)]
  gev.fit <- fevd(bm.train, type = "GEV", method = "Lmoments")
  bm.rl <- return.level(gev.fit, return.period = rp)
  idx <- which(year(ord[["Time"]]) %in% train.years)
  ord.train <- ord[idx,]
  mevd.quant <- optim(c(1), fn = fun, data = ord.train)[["par"]]
  error.data[["OBS"]][sim] <- rl
  error.data[["GEV"]][sim] <- bm.rl
  error.data[["MEVD"]][sim] <- mevd.quant
  error.data[["GEV.BIAS"]][sim] <- bm.rl / rl
  error.data[["MEVD.BIAS"]][sim] <- mevd.quant / rl
  error.data[["GEV.NDE"]][sim] <- (bm.rl - rl) / rl
  error.data[["MEVD.NDE"]][sim] <- (mevd.quant - rl) / rl
}

# save cross-validation results
write.csv(error.data, "Boston-CV-10-Gamma.csv", row.names = FALSE)