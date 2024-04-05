# load packages
packages <- c("fitdistrplus", "extRemes", "lubridate")

load.packages <- lapply(packages, library, character.only = TRUE)

# function to be used for fitting the MEVD
fun <- function(par, data, pr) {
  zeta <- 0
  
  for (y in unique(year(data[["Time"]]))) {
    ny <- length(which(year(data[["Time"]]) == y))
    idc <- which(year(data[["Time"]]) == y)
    # change "ordinary" distribution and estimation method accordingly...
    fit <-
      fitdist(data[["Surge"]][idc], distr = "gamma", method = "mme")
    zeta <-
      zeta + pgamma(par[1], shape = fit[["estimate"]][1], rate = fit[["estimate"]][2]) **
      ny
  }
  
  zeta <- zeta / length(unique(year(data[["Time"]])))
  error <- (pr - zeta) ** 2
  
  return(error)
}

# read surge annual maxima
bm <-
  read.csv("Boston-surge-annual-maxima.csv")

# read "ordinary" surge data
ord <-
  read.csv("Boston-surge-ordinary.csv")

# fit GEV distribution to annual maxima
gev.fit <- fevd(bm[["Surge"]], type = "GEV", method = "Lmoments")

# sort annual maxima
bm.data <- sort(bm[["Surge"]])

# assign probability of non-exceedance to annual maxima
rank <- (seq(1, length(bm.data)) / (length(bm.data) + 1))

# get return period
rp <- 1 / (1 - rank)

# get GEV estimates of observed annual maxima
gev.rl <- as.numeric(return.level(gev.fit, return.period = rp))

# get MEVD estimates of observed annual maxima
mevd.quant <- c()

for (j in 1:length(bm.data)) {
  mevd.quant <-
    append(mevd.quant, optim(
      c(0.25),
      fn = fun,
      data = ord,
      pr = rank[j]
    )[["par"]])
}
gev.rl <- as.numeric(gev.rl)

# save estimates
qq <- data.frame(OBS = bm.data, GEV = gev.rl, MEVD = mevd.quant)
write.csv(qq, "Boston-fit-GEV-MEVD.csv", row.names = FALSE)