
fun.extract.data <- function(df.obj, rry, rrxx, rrgroups, label_groups, vec.options){
  res <- build.sdpd.series(px=df.obj$px, rry=rry, rrXX=rrxx, rrgroups=rrgroups, label_groups=label_groups, vec.options=vec.options)
  if(length(res$error)==0){
    res <- list(px=res$p.axis$pixel, lon=res$p.axis$longit, lat=res$p.axis$latit, series=res$series, 
       X=res$X, ww.index=res$ww.index, ww.values=res$ww.values, px.neighbors=res$px.neighbors, NAs=res$n.NA, p.axis=res$p.axis,
       t.axis=res$t.axis, description=res$description)
  }
  else{
    cat("\n Error: ", res$error)
    res <- list(error=res$error) 
  }
  res
}


fun.derive.function.VARs <- function(summary_stat) {
  switch(summary_stat,
         mean = function(x) mean(x, na.rm = TRUE),
         standard_deviation = function(x) sd(x, na.rm = TRUE),
         min = function(x) min(x, na.rm = TRUE),
         max = function(x) max(x, na.rm = TRUE),
         median = function(x) median(x, na.rm = TRUE),
         range = function(x) diff(range(x, na.rm = TRUE)),
         count.NAs = function(x) sum(is.na(x)),
         skewness = function(x) skewness(x, na.rm = TRUE),
         kurtosis = function(x) kurtosis(x, na.rm = TRUE),
         stop(paste("Unknown statistic:", summary_stat))
  )
}


fun.plot.stat.VARs <- function(df_serie, statistic, title, pars, output_path, bool_dynamic = FALSE) {
  from.to <- dimnames(df_serie)[[2]][c(3, dim(df_serie)[2])]
  from.to <- substr(from.to, 2, 11)
  plot <- df_serie %>%
    mutate(value = round(apply(df_serie[, -c(1, 2)], 1, FUN = statistic), digits=5)) %>%
    ggplot(aes(longitude, latitude, colour = value)) +
    geom_point(size=size.point) +
    scale_colour_gradientn(colours = pars$colori, limits = pars$limiti) +
    labs(x="Longitude", y="Latitude", caption = paste("(based on data observed from ", from.to[1], " to ", from.to[2], ")", sep="")) + 
    labs(title = title, colour = pars$unit)
  
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(plot)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(
      filename = output_path,
      plot = plot,
      width = 8,
      height = 6
    )
  }
}


fun.estimate.parameters <- function(df.obj, model, vec.options){
  if(is.null(df.obj$error)){
    res <- fit.sdpd.model(series=df.obj, model=model, vec.options=vec.options)
    if(length(res$error)==0){
      list(px=df.obj$px, lon=df.obj$lon, lat=df.obj$lat, group=df.obj$p.axis$group, res.fit=res, modello=res$model)
    }
    else{
      cat("\n Errore: ", res$error)
      list(error=res$error)
    }
  }
  else{
    cat("\n Errore: df.data is NULL")
    df.obj
  }
}


fun.assemble.estimate.results <- function(obj.stime){
  if(is.null(obj.stime$error)){
      indici <- as.character(obj.stime$px)
      px <- obj.stime$px
      names(px) <- indici
      if(length(obj.stime$px)==1){
        res <- list(px=px, lon=obj.stime$lon, lat=obj.stime$lat, group=data.frame(t(obj.stime$group)),
                    fitted=data.frame(obj.stime$res.fit$fitted, check.names=F)[indici,], resid=data.frame(obj.stime$res.fit$resid, check.names=F)[indici,],
                    coeff.hat=data.frame(obj.stime$res.fit$coeff.hat, check.names=F)[indici,])
      }
      else{
        res <- list(px=px, lon=obj.stime$lon, lat=obj.stime$lat, group=data.frame(obj.stime$group),
                    fitted=data.frame(obj.stime$res.fit$fitted, check.names=F)[indici,], resid=data.frame(obj.stime$res.fit$resid, check.names=F)[indici,],
                    coeff.hat=data.frame(obj.stime$res.fit$coeff.hat, check.names=F)[indici,])
      }
  }
  else res <- obj.stime
  res
}


fun.plot.coeff.FITs <- function(obj.results, name.endogenous=NULL, time=NULL, pars=NULL){
  res <- list()
  nomi <- names(obj.results$coeff.hat)
  if(is.null(time))
    testo <- titolo <- NULL
  else{
    from.to <- range(time)
    titolo <- "Estimated coefficients for the "
    testo <- paste("(Model: ", name.endogenous, "~H-SDPD, based on data from ", from.to[1], " to ", from.to[2], ")", sep="")
  }
  for(ii in 1:length(nomi)){
    if(nomi[ii]=="intercept_norm"|nomi[ii]=="slope_norm") limiti <- c(-1,1) else limiti=NULL
    dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, district=obj.results$group$LABEL, value=round(obj.results$coeff.hat[,ii], digits=5))
    res[[ii]] <- dati %>% ggplot(aes(x=lon, y=lat, district=district, colour = value)) +
      geom_point(size=size.point) +
      scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) + 
      labs(x="Longitude", y="Latitude", caption = testo) + 
      labs(title = paste(titolo, nomi[ii], sep=""), colour="value")
  }
  names(res) <- nomi
  res
}



fun.plot.series.FITs <- function(df.results, latitude, longitude, name_y="", pars=NULL){
  sottotitolo <- paste("longitude=", longitude, " - latitude=", latitude, sep="")
  time <- dimnames(df.results$fitted)[[2]]
  serie1 <- df.results |> 
    mutate(Latitude=round(lat,1)) |>
    mutate(Longitude=round(lon,1)) |>
    filter(Latitude==round(latitude,1),Longitude==round(longitude,1)) 
  if(dim(serie1)[1]==0){
    return("These coordinates are not present in the database")
  }
  offset.axis <- range(serie1$fitted, na.rm=T)[1]-0.1*diff(range(serie1$fitted, na.rm=T))
  res <- data.frame(time=as.yearmon(time), fitted=as.numeric(serie1$fitted), resid=as.numeric(serie1$resid)) %>%
    mutate(observed=resid+fitted) %>%
    ggplot(aes(x=time)) +
    geom_line(aes(y=fitted, color="Fitted")) + 
    geom_line(aes(y=observed, color="Observed")) + 
    geom_line(aes(y=resid+offset.axis, color="Residuals")) + 
    geom_hline(aes(yintercept = mean(resid, na.rm=T)+offset.axis)) + 
    guides(x = guide_axis(angle = 0)) + 
    scale_y_continuous(
      # Features of the first axis
      name = name_y,
      # Add a second axis and specify its features
      sec.axis = sec_axis(transform=~.-offset.axis, name="2° axis is for residuals")) +
    labs(caption = paste("(Model: ", name_y, "~H-SDPD, based on data from ", range(time)[1], " to ", range(time)[2], ")", sep="")) + 
    labs(title = "Estimated model series", subtitle=sottotitolo, x="", y=name_y, color="")
  res
} 

fun.plot.series.FITs2 <- function(df.results, latitude, longitude, name_y="", pars=NULL){
  sottotitolo <- paste("longitude=", user_longitude_choice, " - latitude=", user_latitude_choice, sep="")
  resids <- modelStats_df$Residuals[[name.endogenous]] |>
    mutate(latitude=round(Latitude,1)) |>
    mutate(longitude=round(Longitude,1)) |>
    filter(latitude==round(user_latitude_choice,1),longitude==round(user_longitude_choice,1)) |>
    select(Residuals)
  observed <- data_df[[name.endogenous]] |>
    mutate(latitude=round(Latitude,1)) |>
    mutate(longitude=round(Longitude,1)) |>
    filter(latitude==round(user_latitude_choice,1),longitude==round(user_longitude_choice,1)) |>
    select(Date, value)
  fitted <- observed$value - resids$Residuals[[1]]
  time <- data_df[[name.endogenous]]$Date
  offset.axis <- range(fitted, na.rm=T)[1]-0.1*diff(range(fitted, na.rm=T))
  df.results.estimate <- data.frame(time=as.yearmon(time), fitted=as.numeric(fitted), resid=as.numeric(resids$Residuals[[1]])) |>
    mutate(observed=resid+fitted) |>
    mutate(residual=resid+offset.axis) |>
    select(-c(resid))
  if(dim(df.results.estimate)[1]==0){
    return("These coordinates are not present in the database")
  }
  res <- df.results.estimate %>%
    ggplot(aes(x=time)) +
    geom_line(aes(y=fitted, color="Fitted")) + 
    geom_line(aes(y=observed, color="Observed")) + 
    geom_line(aes(y=residual, color="Residual")) + 
    geom_hline(aes(yintercept = mean(resid, na.rm=T)+offset.axis)) + 
    guides(x = guide_axis(angle = 0)) + 
    scale_y_continuous(
      # Features of the first axis
      name = name.endogenous,
      # Add a second axis and specify its features
      sec.axis = sec_axis(transform=~.-offset.axis, name="2° axis is for residuals")) +
    labs(title = "Estimated model series", subtitle=sottotitolo, x="", color="")
  res 
}

fun.plot.stat.RESIDs <- function(df.results, statistic, title, pars = NULL, bool_dynamic = FALSE, output_path, ...) {
  # Check if residuals are in data.frame or list format
  if (is.data.frame(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, value = round(apply(df.results$resid, 1, FUN = statistic, ...), digits=5))
  } else if (is.list(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, value = round(unlist(lapply(df.results$resid, FUN = statistic, ...)), digits=5))
  } else {
    # Handle simple vector case
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, value = round(statistic(df.results$resid, ...), digits=5))
  }
  
  # Create the base ggplot
  res <- dati %>%
    ggplot(aes(lon, lat, colour = value)) +
    geom_point(size = size.point) +
    guides(fill = "none") +
    labs(
      title = "Summary statistics for residuals",
      x = "Longitude",
      y = "Latitude",
      colour = paste(title, "\nof residuals")
    ) +
    scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
    theme_bw()
  
  # Save as either interactive HTML or static PNG based on bool_dynamic
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(res)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = res, width = 8, height = 6)
  }
}


fun.plot.stat.discrete.RESIDs <- function(
    df.results,
    statistic = mean,
    title,
    significant.test = FALSE,
    BYadjusted = FALSE,
    alpha,
    pars = NULL,
    bool_dynamic = FALSE,
    output_path,
    ...) {
  # Compute summary statistics on residuals
  if (is.data.frame(df.results$resid)) {
    dati <- data.frame(
      lon = df.results$lon,
      lat = df.results$lat,
      value = apply(df.results$resid[, -1], 1, FUN = statistic, ...)
    )
  } else if (is.list(df.results$resid)) {
    dati <- data.frame(
      lon = df.results$lon,
      lat = df.results$lat,
      value = unlist(lapply(df.results$resid, FUN = statistic, ...))
    )
  } else {
    # Handle simple vector case
    dati <- data.frame(
      lon = df.results$lon,
      lat = df.results$lat,
      value = statistic(df.results$resid, ...)
    )
  }
  
  # Adjust p-values if requested
  if (BYadjusted) {
    dati$value <- p.adjust(dati$value, method = "BY")
  }
  
  # Convert to factor for significance test
  if (significant.test) {
    dati$value <- as.factor(ifelse(dati$value < alpha, "Significant", "Not significant"))
  }
  
  # Create plot
  res <- dati %>%
    ggplot(aes(x = lon, y = lat, colour = value)) +
    geom_point(size=size.point) +
    guides(fill = "none") +
    labs(
      title = "Summary statistics for residuals",
      x = "Longitude",
      y = "Latitude", caption=pars$caption,
      colour = paste(title, "\nof residuals")
    ) +
    theme_bw()
  
  # Save plot
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(res)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = res, width = 8, height = 6)
  }
}



fun.JBtest <- function(x, ...) {
  tryCatch(
    {
      if (length(x) > 7 && !all(is.na(x))) {
        # Simple Jarque-Bera test implementation
        n <- length(x)
        x_centered <- x - mean(x, na.rm = TRUE)
        s <- sqrt(sum(x_centered^2, na.rm = TRUE) / n)
        skewness_val <- sum(x_centered^3, na.rm = TRUE) / (n * s^3)
        kurtosis_val <- sum(x_centered^4, na.rm = TRUE) / (n * s^4)
        jb_stat <- n * (skewness_val^2 / 6 + (kurtosis_val - 3)^2 / 24)
        p_value <- 1 - pchisq(jb_stat, df = 2)
        return(p_value)
      } else {
        return(NA)
      }
    },
    error = function(e) {
      return(NA)
    }
  )
}


fun.LBtest <- function(x, ...) {
  tryCatch(
    {
      if (length(x) > 10 && !all(is.na(x))) {
        test_result <- Box.test(x, lag = min(12, length(x) / 4), type = "Ljung-Box")
        return(test_result$p.value)
      } else {
        return(NA)
      }
    },
    error = function(e) {
      return(NA)
    }
  )
}


fun.testing.parameters <- function(df.obj, correction=FALSE, indici.correction=NULL, markovian=markovian, cartel=NULL, n.boot, label.group, plot){
  if(!is.null(df.obj)){
    if(sum(is.na(df.obj$res.fit$coeff.hat))==0){
      pixels <- dimnames(df.obj$res.fit$coeff.hat)[[1]]
      indici.px <- ifelse(pixels %in% df.obj$px, 1, 3)
      gruppi.px <- label.group[as.character(df.obj$group$COD)]
      res <- test.sdpd.model(df.obj$res.fit, correction=correction, indici.correction=indici.correction,
                             H0="zero", method="normal basic", n.boot=n.boot, markovian=markovian,
                             group.index=indici.px, opts.plot=list(boot.plot=plot, label.index=gruppi.px, cartel=cartel))
      list(px=df.obj$px, lon=df.obj$lon, lat=df.obj$lat, group=df.obj$group, res.test=res, modello=df.obj$modello) 
    }
    else{
      cat("\n Errore:", sum(is.na(df.obj$res.fit$coeff.hat)), "NAs nei coefficienti stimati")
      NULL
    }
  }
  else{
    cat("\n Errore: res.fit è NULL")
    res <- NULL
  }
}


fun.assemble.test.results <- function(obj.test){
  if(!is.null(obj.test)){
    indici.px <- as.character(obj.test$px)
    px <- obj.test$px
    names(px) <- indici.px
    if(length(obj.test$px)==1){
      res <- list(px=px, lon=obj.test$lon, lat=obj.test$lat, group=obj.test$group$LABEL, 
                  mu.i=obj.test$res.test$mu.i[indici.px], mu.around=obj.test$res.test$mu.around[indici.px],
                  coeff.hat=data.frame(obj.test$res.test$coeff.hat)[indici.px,],
                  pvalue.test=data.frame(obj.test$res.test$pvalue)[indici.px,], 
                  coeff.bias.boot=data.frame(obj.test$res.test$coeff.boot["bias.boot",,])[indici.px,],
                  coeff.sd.boot=data.frame(obj.test$res.test$coeff.boot["sd.boot",,])[indici.px,],
                  coeff.pvalueJBtest.boot=data.frame(obj.test$res.test$coeff.boot["pvJBnormaltest.boot",,])[indici.px,],
                  coeff.NAs.boot=data.frame(obj.test$res.test$coeff.boot["NAs.boot",,])[indici.px,],
                  sdevs.tsboot=data.frame(t(obj.test$res.test$sdevs.tsboot))[indici.px,])
    }
    else{
      res <- list(px=px, lon=obj.test$lon, lat=obj.test$lat, group=obj.test$group$LABEL, coeff.hat=data.frame(obj.test$res.test$coeff.hat)[indici.px,],
                  pvalue.test=data.frame(obj.test$res.test$pvalue)[indici.px,],
                  mu.i=obj.test$res.test$mu.i[indici.px], mu.around=obj.test$res.test$mu.around[indici.px],
                  coeff.bias.boot=data.frame(obj.test$res.test$coeff.boot["bias.boot",,])[indici.px,],
                  coeff.sd.boot=data.frame(obj.test$res.test$coeff.boot["sd.boot",,])[indici.px,],
                  coeff.pvalueJBtest.boot=data.frame(obj.test$res.test$coeff.boot["pvJBnormaltest.boot",,])[indici.px,],
                  coeff.NAs.boot=data.frame(obj.test$res.test$coeff.boot["NAs.boot",,])[indici.px,],
                  sdevs.tsboot=data.frame(t(obj.test$res.test$sdevs.tsboot))[indici.px,])
    }
  }
  else res <- NULL
  res
}


fun.diagnostic.boot.results <- function(obj.test){
  if(!is.null(obj.test)){
    indici.px <- as.character(obj.test$px)
    indici.out <- dimnames(obj.test$res.test$coeff.hat)[[1]][!(dimnames(obj.test$res.test$coeff.hat)[[1]] %in% indici.px)]
    px <- obj.test$px
    res <- data.frame(px=px, lon=obj.test$lon, lat=obj.test$lat, district=obj.test$group$LABEL,
                      eigenA.pre=round(rep(obj.test$res.test$diagnostics$Mod.eigenA[1], length(px)), 2),
                      nNA=data.frame(obj.test$res.test$coeff.boot["NAs.boot",indici.px,]),
                      l0=round(obj.test$res.test$coeff.hat[indici.px,"lambda0"], 2),
                      l1=round(obj.test$res.test$coeff.hat[indici.px,"lambda1"], 2),
                      l0l1l2=round(obj.test$res.test$coeff.hat[indici.px,"lambda0"]+obj.test$res.test$coeff.hat[indici.px,"lambda1"]+obj.test$res.test$coeff.hat[indici.px,"lambda2"], 2),
                      row.names = NULL)
  }
  else res <- NULL
  res
}



fun.plot.coeffboot.TEST <- function(obj.results, matrix1, matrix2=NULL, alpha, limiti=NULL, name_y=NULL, time=NULL, 
                                    titolo=NULL, sottotitolo=NULL, legenda_colore="value", pars=NULL){
  res <- list()
  nomi <- names(obj.results[[matrix1]])
  if(matrix1=="sdevs.tsboot" & is.null(sottotitolo)){
    sottotitolo <- " of differences between the bootstrap and the observed time series"
  }
  else if(matrix1=="coeff.hat" & is.null(sottotitolo)){
    sottotitolo <- ": Boostrap significance test"
  }
  else if(matrix1=="coeff.bias.boot" & is.null(sottotitolo)){
    sottotitolo <- ": Bootstrap bias estimation"
    legenda_colore <- "bias of\nestimator"
  }
  else if(matrix1=="coeff.sd.boot" & is.null(sottotitolo)){
    sottotitolo <- ": Boostrap standard error estimation"
    legenda_colore <- "standard\nerror of\nestimator"
  }
  if(is.null(time) | is.null(name_y))
    testo_caption <- ""
  else
    testo_caption <- paste("(Model: ", name_y, "~H-SDPD, based on data from ", range(time)[1], " to ", range(time)[2], ")", sep="")
  titolo2 <- titolo
  if(sottotitolo=="") sottotitolo <- NULL
  for(ii in 1:length(nomi)){
    if(is.null(titolo)) titolo2 <- nomi[ii]
    else titolo2 <- paste(titolo, nomi[ii])
    if(is.list(limiti)) limiti.b <- limiti[[ii]] else limiti.b <- limiti
    if(is.null(matrix2)){
      dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, district=obj.results$group,
                         l0=round(obj.results$coeff.hat$lambda0,2), l1=round(obj.results$coeff.hat$lambda1,2),
                         l2=round(obj.results$coeff.hat$lambda2,2), value=round(obj.results[[matrix1]][,ii], digits=5))
      res[[ii]] <- dati %>%
        ggplot(aes(x=lon, y=lat, district=district, l0=l0, l1=l1, l2=l2, colour = value)) +
        geom_point(size=size.point) +
        scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti.b) + 
        labs(caption = testo_caption) + 
        labs(title = paste(titolo2, sottotitolo, "\n", testo_caption, sep=""), colour=legenda_colore, x="Longitude", y="Latitude")
    }else{
      dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, district=obj.results$group, value=obj.results[[matrix2]][,ii]<alpha) |>
        mutate(boot_test = ifelse(value, "Significant", "Not significant"))
      res[[ii]] <- dati %>% ggplot(aes(x=lon, y=lat, district=district, colour = boot_test)) +
        geom_point(size=size.point) +
        labs(caption = testo_caption) + 
        labs(title = paste(titolo2, sottotitolo, "\n", testo_caption, sep=""), colour=paste("Test result\n(size ", alpha*100, "%):", sep=""), x="Longitude", y="Latitude")
    }
  }
  names(res) <- nomi
  res
}



fun.download.csv <- function(raster_obj, name_file = varnames(raster_obj)[1], output_dir) {
  tempo <- as.character(time(raster_obj))
  valori <- values(raster_obj)
  dimnames(valori)[[2]] <- tempo
  px <- seq(1, dim(valori)[1])
  coordinate <- xyFromCell(raster_obj, px)
  dataframe <- data.frame(longitude = coordinate[, 1], latitude = coordinate[, 2], valori)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(dataframe, file = file.path(output_dir, paste0(name_file, ".csv")), row.names = FALSE)
}



fun.estimate.global.models <- function(df.results, name.covariates, name.response){
  mods <- formulas <- list()

  beta_df <- df.results$coeff.hat |>
    mutate(Latitude=df.results$Latitude, Longitude=df.results$Longitude) |>
    mutate(Elevation=df.results$elevation, LC=df.results$LC)

  formula <- reformulate(c("LC", "Elevation", "LC:Elevation"), intercept=TRUE, response = name.response)
  mods[[1]] <- lm(formula, data = beta_df)
  formulas[[1]] <- formula
  
  formula <- reformulate(c("LC", "Elevation", "Latitude", "Elevation:LC"), intercept=TRUE, response = name.response)
  mods[[2]] <- lm(formula, data = beta_df)
  formulas[[2]] <- formula
  
  formula <- reformulate(c("LC", "Elevation", "Longitude", "Elevation:LC"), intercept=TRUE, response = name.response)
  mods[[3]] <- lm(formula, data = beta_df)
  formulas[[3]] <- formula
  
  formula <- reformulate(c("LC", "Longitude*Latitude"), intercept=TRUE, response = name.response)
  mods[[4]] <- lm(formula, data = beta_df)
  formulas[[4]] <- formula
  
  formula <- reformulate(c(name.covariates, "LC", "Longitude", "Latitude", "Elevation"), intercept=TRUE, response = name.response)
  mods[[5]] <- lm(formula, data = beta_df)
  formulas[[5]] <- formula
  
  formula <- reformulate(c(name.covariates, "LC", "Elevation", "Longitude*Latitude"), intercept=TRUE, response = name.response)
  mods[[6]] <- lm(formula, data = beta_df)
  formulas[[6]] <- formula
  
  mods[[7]] <- formulas

  mods
  
}



fun.prepare.df.results <- function(df.results, model){
  final.df.results <- df.results |>
    select(Longitude=lon, Latitude=lat, District=group, Estimated_coefficients=coeff.hat)
  final.df.results
}


Evaluate_global_Test <- function(mod.fit, alpha){
  temp <- summary(mod.fit)
  pvalore <- pf(temp$fstatistic[1], temp$fstatistic[2], temp$fstatistic[3], lower.tail=FALSE)
  if(pvalore>alpha) str <- "THERE IS NO evidence of significativity for this model"
  else str <- "THERE IS evidence of significativity for this model"
  paste0(str," (p.value=",as.character(round(pvalore,4)),").")
}


diagnostic_models <- function(mod.fit){
  
  plot(mod.fit, which=c(1,2))
  
}