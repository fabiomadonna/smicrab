
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


fun.derive.function.VARs <- function(nome.funzione){
  if(nome.funzione=="mean")
    funzione <- function(x){mean(x, na.rm=TRUE)}
  if(nome.funzione=="standard_deviation")
    funzione <- function(x){sd(x, na.rm=TRUE)}
  if(nome.funzione=="min")
    funzione <- function(x){min(x, na.rm=TRUE)}
  if(nome.funzione=="max")
    funzione <- function(x){max(x, na.rm=TRUE)}
  if(nome.funzione=="median")
    funzione <- function(x){median(x, na.rm=TRUE)}
  if(nome.funzione=="range")
    funzione <- function(x){diff(range(x, na.rm=TRUE))}
  if(nome.funzione=="count.NAs")
    funzione <- function(x){sum(is.na(x))}
  funzione
}


fun.plot.stat.VARs <- function(df_serie, statistic, title, pars){
  dati <- apply(df_serie[,-c(1,2)], 1, FUN=statistic)
  res <- df_serie %>% 
    mutate(newvar=dati) %>%
    ggplot(aes(longitude,latitude, colour = newvar)) +
    geom_point(size = .8) +
    scale_colour_gradientn(colours=pars$colori, limits=pars$limiti) + 
    labs(title = title, colour=pars$unit)
  res
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



fun.plot.coeff.FITs <- function(obj.results, pars=NULL){
  res <- list()
  nomi <- names(obj.results$coeff.hat)
  for(ii in 1:length(nomi)){
    dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, newvar=obj.results$coeff.hat[,ii])
    res[[ii]] <- dati %>% ggplot(aes(lon, lat)) +
      geom_point(aes(colour = newvar), size=0.8) +
      scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=pars_list[[name.endogenous]]$limiti) + 
      labs(title = paste("Estimated coefficients for the", nomi[ii]), colour="value")
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
  coeff <- range(serie1$fitted, na.rm=T)[1]-0.1*diff(range(serie1$fitted, na.rm=T))
  res <- data.frame(time=as.yearmon(time), fitted=as.numeric(serie1$fitted), resid=as.numeric(serie1$resid)) %>%
      ggplot(aes(x=time)) +
      geom_line(aes(y=fitted, color="Fitted")) + 
      geom_line(aes(y=resid+fitted, color="Observed")) + 
      geom_line(aes(y=resid+coeff, color="Residuals")) + 
      geom_hline(aes(yintercept = mean(resid, na.rm=T)+coeff)) + 
      guides(x = guide_axis(angle = 0)) + 
      scale_y_continuous(
        # Features of the first axis
        name = name_y,
        # Add a second axis and specify its features
        sec.axis = sec_axis(transform=~.-coeff, name="2° axis is for residuals")) +
    labs(caption = paste("(based on data from ", range(time)[1], " to ", range(time)[2], ")", sep="")) + 
    labs(title = "Estimated model series", subtitle=sottotitolo, x="", color="")
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
  coeff <- range(fitted, na.rm=T)[1]-0.1*diff(range(fitted, na.rm=T))
  df.results.estimate <- data.frame(time=as.yearmon(time), fitted=as.numeric(fitted), resid=as.numeric(resids$Residuals[[1]])) |>
    mutate(observed=resid+fitted) |>
    mutate(residual=resid+coeff)
  if(dim(df.results.estimate)[1]==0){
    return("These coordinates are not present in the database")
  }
  res <- df.results.estimate %>%
    ggplot(aes(x=time)) +
    geom_line(aes(y=fitted, color="Fitted")) + 
    geom_line(aes(y=observed, color="Observed")) + 
    geom_line(aes(y=residual, color="Residual")) + 
    geom_hline(aes(yintercept = mean(resid, na.rm=T)+coeff)) + 
    guides(x = guide_axis(angle = 0)) + 
    scale_y_continuous(
      # Features of the first axis
      name = name.endogenous,
      # Add a second axis and specify its features
      sec.axis = sec_axis(transform=~.-coeff, name="2° axis is for residuals")) +
    labs(title = "Estimated model series", subtitle=sottotitolo, x="", color="")
  res 
}

fun.plot.stat.RESIDs <- function(df.results, statistic, title, pars=NULL, ...){
  if(is.data.frame(df.results$resid))
    dati <- data.frame(lon=df.results$lon, lat=df.results$lat, newvar=apply(df.results$resid, 1, FUN=statistic, ...))
  else if(is.list(df.results$resid))
    dati <- data.frame(lon=df.results$lon, lat=df.results$lat, newvar=unlist(lapply(df.results$resid, FUN=statistic, ...)))
  res <- dati %>% ggplot(aes(lon, lat, colour = newvar)) +
    geom_point(size = .8) +
    guides(fill = "none") +
    labs(title = "Summary statistics for residuals", x = "Longitude", y = "Latitude", colour=paste(title, "\nof residuals")) +
    scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0)
  res
}  


fun.plot.stat.discrete.RESIDs <- function(df.results, statistic=mean, title, significant.test=FALSE, BYadjusted=FALSE, alpha, pars=NULL, ...){
  if(is.data.frame(df.results$resid))
    dati <- data.frame(lon=df.results$lon, lat=df.results$lat, newvar=apply(df.results$resid[,-1], 1, FUN=statistic, ...))
  else if(is.list(df.results$resid))
    dati <- data.frame(lon=df.results$lon, lat=df.results$lat, newvar=unlist(lapply(df.results$resid, FUN=statistic, ...)))
  if(BYadjusted)
    dati$newvar <- p.adjust(dati$newvar,method="BY")
  if(significant.test)
    dati$newvar <- as.factor(ifelse(dati$newvar<alpha, "Significant","Not significant"))
  res <- dati %>% ggplot(aes(x=lon, y=lat, colour = newvar)) +
    geom_point(size = .8) +
    guides(fill = "none") +
    labs(title = "Summary statistics for residuals", x = "Longitude", y = "Latitude", colour=paste(title, "\nof residuals"))
  res
}  


fun.JBtest <- function(x){
  if(sum(is.na(x))>0) JB <- 1 else JB <- tseries::jarque.bera.test(x)$p.value
  JB
}

fun.LBtest <- function(x){
  LB <- Box.test(x, lag=24, type = "Ljung")$p.value
}




fun.testing.parameters <- function(df.obj, correzione, n.boot, label.group, plot){
  if(!is.null(df.obj)){
    if(sum(is.na(df.obj$res.fit$coeff.hat))==0){
      pixels <- dimnames(df.obj$res.fit$coeff.hat)[[1]]
      indici.px <- ifelse(pixels %in% df.obj$px, 1, 3)
      gruppi.px <- label.group[df.obj$group$COD]
      res <- test.sdpd.model(df.obj$res.fit, correzione=correzione, H0="zero", method="normal basic", n.boot=n.boot,
                group.index=indici.px, opts.plot=list(boot.plot=plot, label.index=gruppi.px))
      list(px=df.obj$px, lon=df.obj$lon, lat=df.obj$lat, group=df.obj$group, diagnostics=res$diagnostics, res.test=res, modello=df.obj$modello) 
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
      res <- list(px=px, lon=obj.test$lon, lat=obj.test$lat, group=data.frame(t(obj.test$group)), coeff.hat=data.frame(obj.test$res.test$coeff.hat)[indici.px,],
        pvalue.test=data.frame(obj.test$res.test$pvalue)[indici.px,], diagnostics=data.frame(obj.test$diagnostics)[indici.px,], 
        coeff.bias.boot=data.frame(obj.test$res.test$coeff.boot["bias.boot",,])[indici.px,],
        coeff.sd.boot=data.frame(obj.test$res.test$coeff.boot["sd.boot",,])[indici.px,],
        coeff.pvalueShapirotest.boot=data.frame(obj.test$res.test$coeff.boot["pvSWnormaltest.boot",,])[indici.px,],
        coeff.NAs.boot=data.frame(obj.test$res.test$coeff.boot["NAs.boot",,])[indici.px,],
        sdevs.tsboot=data.frame(t(obj.test$res.test$sdevs.tsboot))[indici.px,])
    }
    else{
      res <- list(px=px, lon=obj.test$lon, lat=obj.test$lat, group=data.frame(obj.test$group), coeff.hat=data.frame(obj.test$res.test$coeff.hat)[indici.px,],
                  pvalue.test=data.frame(obj.test$res.test$pvalue)[indici.px,], diagnostics=data.frame(obj.test$diagnostics[indici.px,]),
                  coeff.bias.boot=data.frame(obj.test$res.test$coeff.boot["bias.boot",,])[indici.px,],
                  coeff.sd.boot=data.frame(obj.test$res.test$coeff.boot["sd.boot",,])[indici.px,],
                  coeff.pvalueShapirotest.boot=data.frame(obj.test$res.test$coeff.boot["pvSWnormaltest.boot",,])[indici.px,],
                  coeff.NAs.boot=data.frame(obj.test$res.test$coeff.boot["NAs.boot",,])[indici.px,],
                  sdevs.tsboot=data.frame(t(obj.test$res.test$sdevs.tsboot))[indici.px,])
    }
  }
  else res <- NULL
  res
}




fun.plot.coeffboot.TEST <- function(obj.results, matrix1, matrix2=NULL, alpha, limiti=NULL,
                                    titolo=NULL, sottotitolo="", legenda_colore="value", pars=NULL){
  res <- list()
  nomi <- names(obj.results[[matrix1]])
  if(matrix1=="sdevs.tsboot"){
    sottotitolo <- "of differences between the bootstrap and the observed time series\n(grey pixels show values bigger than 100)"
    limiti <- c(0,100)
  }
  else if(matrix1=="coeff.hat"){
    sottotitolo <- "Estimated coefficients validated by the bootstrap test"
  }
  else if(matrix1=="coeff.bias.boot"){
    sottotitolo <- "Bootstrap bias estimation"
    legenda_colore <- "bias"
  }
  else if(matrix1=="coeff.sd.boot"){
    sottotitolo <- "Boostrap standard deviation estimation"
    legenda_colore <- "sd"
  }
  titolo2 <- titolo
  for(ii in 1:length(nomi)){
    if(is.null(titolo))
      titolo2 <- nomi[ii]
    if(is.null(matrix2))
      dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, newvar=obj.results[[matrix1]][,ii])
    else{
      reject <- obj.results[[matrix2]][,ii]<alpha
      dati <- data.frame(lon=obj.results$lon, lat=obj.results$lat, newvar=obj.results[[matrix1]][,ii]*reject)
    }
    res[[ii]] <- dati %>% ggplot(aes(lon, lat)) +
      geom_point(aes(colour = newvar), size = .8) +
      scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) + 
      labs(title = titolo2, subtitle=sottotitolo, colour=legenda_colore)
  }
  names(res) <- nomi
  res
}


fun.download.csv <- function(raster_obj, name_file=varnames(raster_obj)[1]){
  tempo <- as.character(time(raster_obj))
  valori <- values(raster_obj)
  dimnames(valori)[[2]] <- tempo
  px <- seq(1, dim(valori)[1])
  coordinate <- xyFromCell(raster_obj, px)
  dataframe <- data.frame(longitude=coordinate[,1], latitude=coordinate[,2], valori)
  write.csv(dataframe, file=paste("downloads/", name_file, ".csv", sep=""))
}



fun.estimate.global.models <- function(df.results, slc, name.covariates, name.response){
  mods <- formulas <- list()
  if(name.response=="fixed_effects") name.response2 <- "trend"
  if(name.response=="trend") name.response2 <- "fixed_effects"
  
  beta_df <- df.results$coeff.hat |>
    mutate(Latitude=round(df.results$lat,1),Longitude=round(df.results$lon,1)) |>
    left_join(slc)

  formula <- reformulate(c("LC"), intercept=FALSE, response = name.response)
  mods[[1]] <- lm(formula, data = beta_df)
  formulas[[1]] <- formula
  
  formula <- reformulate(c("LC"), intercept=TRUE, response = name.response)
  mods[[2]] <- lm(formula, data = beta_df)
  formulas[[2]] <- formula
  
  formula <- reformulate(c("Longitude", "LC", "Longitude:LC"), intercept=TRUE, response = name.response)
  mods[[3]] <- lm(formula, data = beta_df)
  formulas[[3]] <- formula
  
  formula <- reformulate(c("Latitude", "LC", "Latitude:LC"), intercept=TRUE, response = name.response)
  mods[[4]] <- lm(formula, data = beta_df)
  formulas[[4]] <- formula
  
  formula <- reformulate(c(name.covariates, "LC", "Longitude", "Latitude"), intercept=TRUE, response = name.response)
  mods[[5]] <- lm(formula, data = beta_df)
  formulas[[5]] <- formula
  
  formula <- reformulate(name.response2, intercept=TRUE, response = name.response)
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