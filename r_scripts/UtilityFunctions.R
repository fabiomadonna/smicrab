
## Functions
CreateLongDF <- function(df){
  df |>
    pivot_longer(cols=starts_with("X"),names_to="Variable",values_to = "value") |>
    separate(Variable, c("Prefix", "date"), 1) |>
    mutate(Date=as.Date(date,tryFormats = c("%Y.%m.%d"))) |>
    select(-c(Prefix,date)) |>
    rename(Latitude=latitude,Longitude=longitude)
}

CreateNestedDF <- function(df) {
  df |>
    nest(data=-c(Latitude,Longitude))
}

Create_tsibble <- function(obj) {
  # Create monthly time series objects for additional analysis
  obj |>
    mutate(Month = yearmonth(Date)) |>
    as_tsibble(index = Month)
}

Create_ts <- function(obj) {
  # Create monthly time series objects for additional analysis
  as.ts(zoo::zoo(obj$value, order.by = zoo::as.yearmon(obj$Date)))
}

ComputeAdjSTL <- function(obj_tsibble){
  # Compute deasonalized time series with stl
  dcmp <- obj_tsibble |>
    model(STL(value ~ season(period = 12), robust = TRUE)) |>
    components()
  as.ts(zoo::zoo(dcmp$season_adjust, order.by = obj_tsibble$Month))
}

GenerateTSDataFrame <- function(nested_df){
  nested_df |>
    mutate(data_tsibble = future_map(data, Create_tsibble,
                                     .options=furrr_options(seed=TRUE))) |>
    mutate(data_ts = future_map(data, Create_ts,
                                .options=furrr_options(seed=TRUE))) |>
    mutate(seasadj_stl = future_map(data_tsibble, ComputeAdjSTL,
                                    .options=furrr_options(seed=TRUE))) |>
    select(-data)
}

CreateFullDataset <- function(data_df){
  # It just chenges the generic name "dat" with the name of teh variable
  nameVarsModel <- names(data_df)
  oldnames <- c("Longitude","Latitude","value","Date")
  for (varName in nameVarsModel) {
    newnames <- c("Longitude","Latitude",varName,"Date")
    data_df[[varName]] <- data_df[[varName]]|> 
      dplyr::select(all_of(oldnames)) %>%
      dplyr::rename_with(~ newnames, all_of(oldnames)) 
  }
  full_data_df <- purrr::reduce(data_df, left_join)
  data_nested_df <- full_data_df  |>
    nest(data=-c("Longitude","Latitude"))
  data_ts_nested <- data_nested_df |> 
    mutate(data_tsibble = future_map(data, Create_tsibble,
                                     .options=furrr_options(seed=TRUE))) |>
    select(-data)
}



plotVarSpatial <- function(varName,datePoint,data, pars){
  # Plot a spatial map for a given variable at a given time point
  new.date <- paste(substr(datePoint, 1, 4),substr(datePoint, 6, 7), substr(datePoint, 9,10), sep=".") 
  plt <- data|>
    select(Latitude=latitude, Longitude=longitude, value=paste("X", new.date, sep="")) |>
    ggplot(aes(x = Longitude, y =  Latitude)) +
    geom_point(aes(colour = value), size=0.8) +
    scale_colour_gradientn(colours=pars$colori, limits=pars$limiti) + 
    labs(title = paste("Monthly mean value of", varName), subtitle=paste("Observed on ", substr(datePoint, 1, 7)), colour=pars$unit)
  plt
}


plotVarSpatial2 <- plotVarSpatial

# PlotComponentsSTL_lonlat <- function(lat,lon,varName,dataNestedTS){
#   # Plot TS components using STL
#   obj_tsibble <- dataNestedTS[[varName]]
#   obj <- obj_tsibble |>
#     mutate(Latitude=round(Latitude,1)) |>
#     mutate(Longitude=round(Longitude,1)) |>
#     filter(Latitude==round(lat,1),Longitude==round(lon,1))
#   obj$data_tsibble[[1]] |>
#     model(STL(value ~ season(period = 12), robust = TRUE)) |>
#     components() |>
#     autoplot() +
#     ggtitle(paste(varName,"(STL decomposition)")) +
#     theme_bw()
# }

# PlotComponentsSTL_nonest_lonlat <- function(lat,lon,varName,dataNested, pars){
#   # Plot TS components using STL
#   data_df <- dataNested[[varName]] |>
#     mutate(Latitude=round(Latitude,1)) |>
#     mutate(Longitude=round(Longitude,1)) |>
#     filter(Latitude==round(lat,1),Longitude==round(lon,1))
#   data_df$data[[1]] |>
#     mutate(Month = yearmonth(Date)) |>
#     as_tsibble(index = Month) |>
#     model(STL(value ~ season(period = 12), robust = TRUE)) |>
#     components() |>
#     autoplot() +
#     ggtitle(paste(varName,"(STL decomposition)")) +
#     theme_bw()
# }


PlotComponentsSTL_nonest_lonlat2 <- function(lat,lon,varName,data, pars){
  # Plot TS components using STL
  data_df <- data |>
    mutate(Latitude=round(latitude,1)) |>
    mutate(Longitude=round(longitude,1)) |>
    filter(Latitude==round(lat,1),Longitude==round(lon,1)) |>
    select(-c(Latitude, Longitude))

  data_df <- CreateLongDF(data_df)
  data_nested_df <- CreateNestedDF(data_df)

  temp_data <- data_nested_df$data[[1]] |>
    mutate(Month = yearmonth(Date))
  
  from.to <- range(temp_data$Month)
  
  temp_data|>
    as_tsibble(index = Month) |>
    model(STL(value ~ season(period = 12), robust = TRUE)) |>
    components() |>
    autoplot() +
    ggtitle(paste(varName,"(STL decomposition)")) +
    guides(x = guide_axis(minor.ticks = TRUE, angle = 0, check.overlap=FALSE)) + 
    labs(caption = paste("(based on data from ", from.to[1], " to ", from.to[2], ")", sep="")) + 
    theme_bw()
}


estimateTemporalModel <- function(obj_ts,modelFormula){
  # Estimate a Trend + Season + ARMA model on original time series
  # XREG and different specifications can be given via modelFormula
  #
  fit <- obj_ts |>
    model(arima_seas = ARIMA(as.formula(modelFormula)))
  stats <- fit$arima_seas[[1]][[1]]$par |>
    select(term,estimate,std.error,p.value) |>
    filter(term=="trend()") |>
    select(-term)
  res <- fit$arima_seas[[1]][[1]]$est$.resid
  resMean <- mean(res)
  resDS <- sd(res)
  resAsy <- moments::skewness(res)
  resSK <- moments::kurtosis(res)
  JB <- tseries::jarque.bera.test(res)$p.value

  LB <- Box.test(res, lag=24, type = "Ljung")$p.value
  ris <- unlist(c(stats,resMean,resDS,resAsy,resSK,JB,LB))
  names(ris) <- c("estimate","std.error","p.value",
                  "res.mean","res.sd","res.asymmetry","res.skewness",
                  "JB_p.value","LB_p.value")
  list(Stats=as_tibble(t(ris)),Residuals=res)
}


computeTemporalModelStats <- function(full_dataset,varNames,xreg){
  # Compute a standard model for all variables
  # in varNames whose data are in full_dataset
  modelNames <- paste0("Model_",varNames)
  modStats <- list()
  modResiduals <- list()
  for (i in (1:length(varNames))) {
    print(varNames[i])
    plan(multisession,gc=TRUE)
    modFits <-  full_dataset |>
      mutate(fit = future_map2(data_tsibble, 
                               paste(varNames[i] , "~", xreg),
                               estimateTemporalModel,
                               .options=furrr_options(seed=TRUE))) |>
      select(Longitude,Latitude,fit) |>
      unnest_wider(col=fit)
    modResiduals[[i]] <- modFits |>
      select(-c(Stats))
    modStats[[i]] <- modFits |>
      select(-c(Residuals)) |>
      unnest(cols=c(Stats)) |>
      mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
      mutate(LB_p.value_BY=p.adjust(LB_p.value,method="BY")) |>
      mutate(JB_p.value_BY=p.adjust(JB_p.value,method="BY")) |>
      mutate(sig=p.value < 0.05) |>
      mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
      mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
      mutate(trend=factor(trend1+trend2)) |>
      mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
      mutate(sig_BY=p.value_BY < 0.05) |>
      mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
      mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
      mutate(trend_BY=factor(trend1+trend2)) |>
      mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
      mutate(LB_sig = ifelse(LB_p.value < 0.05,"Significant","Not significant")) |>
      mutate(JB_sig = ifelse(JB_p.value < 0.05,"Significant","Not significant")) |>
      mutate(LB_sig_BY = ifelse(LB_p.value_BY < 0.05,"Significant","Not significant")) |>
      mutate(JB_sig_BY = ifelse(JB_p.value_BY < 0.05,"Significant","Not significant")) |>
      select(-c(trend1,trend2,sig,sig_BY))
  }
  names(modStats) <- varNames
  names(modResiduals) <- varNames
  list(modStats=modStats,Residuals=modResiduals)
}


estimateSpatialModels <- function(modStats_df,slc_df) {
  varNames <- names(modStats_df$Residuals)
  plan(multisession)
  mods <- list()
  spatialModels <- foreach(i=1:length(varNames)) %dorng% {
    coords <- modStats_df$Residuals[[varNames[[i]]]] |>
      select(c(Longitude, Latitude)) |>
      as.matrix()
    D <- distm_scaled(coords)
    npix <- dim(D)[1]
    res_mat <- do.call(rbind, modStats_df$Residuals[[varNames[[i]]]]$Residuals)
    corfit <- fitCor(resids = res_mat, coords = coords, covar_FUN = "covar_exp", start = list(range = 0.1), fit.n = npix)
    range.opt <-  corfit$spcor
    V.opt <- covar_exp(D, range.opt)
    beta_df <- modStats_df$modStats[[varNames[[i]]]] |>
      select(Longitude,Latitude,estimate) |>
      mutate(Latitude=round(Latitude,1),Longitude=round(Longitude,1)) |>
      left_join(slc_df)
    mods[[1]] <- fitGLS(estimate ~ 1, data = beta_df, 
                        V = V.opt, nugget = NA, no.F = TRUE)
    mods[[2]] <- fitGLS(estimate ~ 0 + LC, data = beta_df, 
                        V = V.opt, nugget = NA, no.F = FALSE)
    mods[[3]]  <- fitGLS(estimate ~ 1 + Longitude, data = beta_df, 
                         V = V.opt, nugget = NA, no.F = FALSE)
    mods[[4]] <- fitGLS(estimate ~ 1 + Latitude, data = beta_df, 
                        V = V.opt, nugget = NA, no.F = FALSE)
    mods[[5]] <-  fitGLS(estimate ~ 1 + Longitude + LC + Longitude:LC, data = beta_df, 
                         V = V.opt, nugget = NA, no.F = FALSE)
    mods[[6]] <- fitGLS(estimate ~ 1 + Latitude + LC + Latitude:LC, data = beta_df, 
                        V = V.opt, nugget = NA, no.F = FALSE)
    names(mods) <- c("GLS.int","GLS.lc","GLS.lon","GLS.lat","GLS.lonxlc","GLS.latxlc")
    mods
  }
  names(spatialModels) <- varNames
  spatialModels
}


ComputeMajorityVote <-function(x){
  
  mclust::majorityVote(unlist(x))$majority
  
}

ComputeScoreValue <- function(sens_df,cs_df,mk_df,smk_df,pwmk_df,bcpw_df,robust_df){
  beta_sens_df <- sens_df |>
    select(Longitude,Latitude,Sens_test) |>
    unnest(cols = c(Sens_test)) |>
    rename(p.value_sens=p.value,
           p.value_sens_BY=p.value_BY,
           estimate_sens=estimate) |>
    rename(trend_sens=trend,
           trend_sens_lab=trend_lab) |>
    rename(trend_sens_BY=trend_BY,
           trend_sens_lab_BY=trend_lab_BY) 
  
  beta_cs_df <- cs_df |>
    select(Longitude,Latitude,CS_test) |>
    unnest(cols = c(CS_test)) |>
    rename(p.value_cs=p.value,
           p.value_cs_BY=p.value_BY,
           estimate_cs=estimate) |>
    rename(trend_cs=trend,
           trend_cs_lab=trend_lab) |>
    rename(trend_cs_BY=trend_BY,
           trend_cs_lab_BY=trend_lab_BY) 
  
  beta_mk_df <- mk_df |>
    select(Longitude,Latitude,MK_test) |>
    unnest(cols = c(MK_test)) |>
    rename(p.value_mk=p.value,
           p.value_mk_BY=p.value_BY,
           estimate_mk=estimate) |>
    rename(trend_mk=trend,
           trend_mk_lab=trend_lab) |>
    rename(trend_mk_BY=trend_BY,
           trend_mk_lab_BY=trend_lab_BY) 
  
  beta_smk_df <- smk_df |>
    select(Longitude,Latitude,SMK_test) |>
    unnest(cols = c(SMK_test)) |>
    rename(p.value_smk=p.value,
           p.value_smk_BY=p.value_BY,
           estimate_smk=estimate) |>
    rename(trend_smk=trend,
           trend_smk_lab=trend_lab) |>
    rename(trend_smk_BY=trend_BY,
           trend_smk_lab_BY=trend_lab_BY) 
  
  beta_pwmk_df <-  pwmk_df |>
    select(Longitude,Latitude,PWMK_test) |>
    unnest(cols = c(PWMK_test)) |>
    rename(p.value_pwmk=p.value,
           p.value_pwmk_BY=p.value_BY,
           estimate_pwmk=estimate) |>
    rename(trend_pwmk=trend,
           trend_pwmk_lab=trend_lab) |>
    rename(trend_pwmk_BY=trend_BY,
           trend_pwmk_lab_BY=trend_lab_BY) 
  
  beta_bcpw_df <-  bcpw_df |>
    select(Longitude,Latitude,BCPW_test) |>
    unnest(cols = c(BCPW_test)) |>
    rename(p.value_bcpw=p.value,
           p.value_bcpw_BY=p.value_BY,
           estimate_bcpw=estimate) |>
    rename(trend_bcpw=trend,
           trend_bcpw_lab=trend_lab) |>
    rename(trend_bcpw_BY=trend_BY,
           trend_bcpw_lab_BY=trend_lab_BY) 
  
  beta_robust_df <- robust_df |>
    select(Longitude,Latitude,Robust_test) |>
    unnest(cols = c(Robust_test)) |>
    rename(p.value_robust=p.value,
           p.value_robust_BY=p.value_BY,
           estimate_robust=estimate) |>
    rename(trend_robust=trend,
           trend_robust_lab=trend_lab) |>
    rename(trend_robust_BY=trend_BY,
           trend_robust_lab_BY=trend_lab_BY) 
  
  beta_sig_df <- beta_sens_df |>
    left_join(beta_cs_df)|>
    left_join(beta_mk_df) |>
    left_join(beta_smk_df) |>
    left_join(beta_pwmk_df) |>
    left_join(beta_bcpw_df) |>
    left_join(beta_robust_df)
  
  dff <- beta_sig_df |>
    mutate(t1=as.numeric(as.character(trend_sens)),
           t2=as.numeric(as.character(trend_cs)),
           t3=as.numeric(as.character(trend_mk)),
           t4=as.numeric(as.character(trend_smk)),
           t5=as.numeric(as.character(trend_pwmk)),
           t6=as.numeric(as.character(trend_bcpw)),
           t7=as.numeric(as.character(trend_robust))) |>
    mutate(t1_BY=as.numeric(as.character(trend_sens_BY)),
           t2_BY=as.numeric(as.character(trend_cs_BY)),
           t3_BY=as.numeric(as.character(trend_mk_BY)),
           t4_BY=as.numeric(as.character(trend_smk_BY)),
           t5_BY=as.numeric(as.character(trend_pwmk_BY)),
           t6_BY=as.numeric(as.character(trend_bcpw_BY)),
           t7_BY=as.numeric(as.character(trend_robust_BY)))  |>
    select(Longitude,Latitude,t1:t7,t1_BY:t7_BY) |>
    rowwise() |> 
    mutate(score = sum(t1,t2,t3,t4,t5,t6,t7)) |>
    mutate(score_BY=sum(t1_BY,t2_BY,t3_BY,t4_BY,t5_BY,t6_BY,t7_BY))
  
  dff |>
    select(Latitude,Longitude,score,score_BY)
}


ComputeMajorityVoteDataFrame <- function(sens_df,cs_df,mk_df,smk_df,pwmk_df,bcpw_df,robust_df){
  beta_sens_df <- sens_df |>
    select(Longitude,Latitude,Sens_test) |>
    unnest(cols = c(Sens_test)) |>
    rename(p.value_sens=p.value,
           p.value_sens_BY=p.value_BY,
           estimate_sens=estimate) |>
    rename(trend_sens=trend,
           trend_sens_lab=trend_lab) |>
    rename(trend_sens_BY=trend_BY,
           trend_sens_lab_BY=trend_lab_BY) 
  
  beta_cs_df <- cs_df |>
    select(Longitude,Latitude,CS_test) |>
    unnest(cols = c(CS_test)) |>
    rename(p.value_cs=p.value,
           p.value_cs_BY=p.value_BY,
           estimate_cs=estimate) |>
    rename(trend_cs=trend,
           trend_cs_lab=trend_lab) |>
    rename(trend_cs_BY=trend_BY,
           trend_cs_lab_BY=trend_lab_BY) 
  
  beta_mk_df <- mk_df |>
    select(Longitude,Latitude,MK_test) |>
    unnest(cols = c(MK_test)) |>
    rename(p.value_mk=p.value,
           p.value_mk_BY=p.value_BY,
           estimate_mk=estimate) |>
    rename(trend_mk=trend,
           trend_mk_lab=trend_lab) |>
    rename(trend_mk_BY=trend_BY,
           trend_mk_lab_BY=trend_lab_BY) 
  
  beta_smk_df <- smk_df |>
    select(Longitude,Latitude,SMK_test) |>
    unnest(cols = c(SMK_test)) |>
    rename(p.value_smk=p.value,
           p.value_smk_BY=p.value_BY,
           estimate_smk=estimate) |>
    rename(trend_smk=trend,
           trend_smk_lab=trend_lab) |>
    rename(trend_smk_BY=trend_BY,
           trend_smk_lab_BY=trend_lab_BY) 
  
  beta_pwmk_df <-  pwmk_df |>
    select(Longitude,Latitude,PWMK_test) |>
    unnest(cols = c(PWMK_test)) |>
    rename(p.value_pwmk=p.value,
           p.value_pwmk_BY=p.value_BY,
           estimate_pwmk=estimate) |>
    rename(trend_pwmk=trend,
           trend_pwmk_lab=trend_lab) |>
    rename(trend_pwmk_BY=trend_BY,
           trend_pwmk_lab_BY=trend_lab_BY) 
  
  beta_bcpw_df <-  bcpw_df |>
    select(Longitude,Latitude,BCPW_test) |>
    unnest(cols = c(BCPW_test)) |>
    rename(p.value_bcpw=p.value,
           p.value_bcpw_BY=p.value_BY,
           estimate_bcpw=estimate) |>
    rename(trend_bcpw=trend,
           trend_bcpw_lab=trend_lab) |>
    rename(trend_bcpw_BY=trend_BY,
           trend_bcpw_lab_BY=trend_lab_BY) 
  
  beta_robust_df <- robust_df |>
    select(Longitude,Latitude,Robust_test) |>
    unnest(cols = c(Robust_test)) |>
    rename(p.value_robust=p.value,
           p.value_robust_BY=p.value_BY,
           estimate_robust=estimate) |>
    rename(trend_robust=trend,
           trend_robust_lab=trend_lab) |>
    rename(trend_robust_BY=trend_BY,
           trend_robust_lab_BY=trend_lab_BY) 
  
  beta_sig_df <- beta_sens_df |>
    left_join(beta_cs_df)|>
    left_join(beta_mk_df) |>
    left_join(beta_smk_df) |>
    left_join(beta_pwmk_df) |>
    left_join(beta_bcpw_df) |>
    left_join(beta_robust_df)
  
  dff_mv <- beta_sig_df |>
    mutate(t1=trend_sens,
           t2=trend_cs,
           t3=trend_mk,
           t4=trend_smk,
           t5=trend_pwmk,
           t6=trend_bcpw,
           t7=trend_robust) |>
    mutate(t1_BY=trend_sens_BY,
           t2_BY=trend_cs_BY,
           t3_BY=trend_mk_BY,
           t4_BY=trend_smk_BY,
           t5_BY=trend_pwmk_BY,
           t6_BY=trend_bcpw_BY,
           t7_BY=trend_robust_BY) |>
    select(Longitude,Latitude,t1:t7,t1_BY:t7_BY)
  dff_nest <- dff_mv |> 
    select(Longitude,Latitude,t1:t7) |>
    nest(data=-c(Longitude,Latitude))
  ris <- dff_nest |>
    mutate(Vote = future_map(data, ComputeMajorityVote,
                             .options=furrr_options(seed=TRUE)))
  dff_nest_BY <- dff_mv |> 
    select(Longitude,Latitude,t1_BY:t7_BY) |>
    nest(data=-c(Longitude,Latitude))
  ris_BY <- dff_nest_BY |>
    mutate(Vote = future_map(data, ComputeMajorityVote,
                             .options=furrr_options(seed=TRUE)))
  votes <- ris %>% 
    select(Longitude,Latitude,Vote) |>
    unnest(cols = c(Vote))
  votes_BY <- ris_BY %>% 
    select(Longitude,Latitude,Vote) |>
    unnest(cols = c(Vote))
  list(Vote=votes,Vote_BY=votes_BY)
}




estimate_sens_TrendSlope <- function(seasadj_ts){
  fit <- trend::sens.slope(seasadj_ts)
  data.frame(estimate=fit$estimates,p.value=fit$p.value)
}

ComputeSens_Stats <- function(df){
  df |>
    mutate(SENS = future_map(seasadj_stl, estimate_sens_TrendSlope, 
                             .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,SENS) |>
    unnest(cols = c(SENS)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(Sens_test=-c(Longitude,Latitude))
}

estimate_cs_TrendSlope <- function(seasadj_ts){
  # Implements the CS trend test
  # With Sens slope estimates
  fits <- trend::sens.slope(seasadj_ts)
  fit <- trend::cs.test(seasadj_ts)
  data.frame(estimate=fits$estimates,p.value=fit$p.value)
}

ComputeCS_Stats <- function(df){
  df |>
    mutate(tst = future_map(seasadj_stl, estimate_cs_TrendSlope, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(CS_test=-c(Longitude,Latitude))
}

estimate_pwmk_TrendSlope <- function(seasadj_ts){
  ss <- as.vector(seasadj_ts)
  fit <- modifiedmk::pwmk(ss)
  out <- data.frame(fit["Sen's Slope"],fit["P-value"])
  colnames(out) <- c("estimate","p.value")
  out
}

ComputePWMK_Stats <- function(df){
  df |>
    mutate(tst = future_map(seasadj_stl, estimate_pwmk_TrendSlope, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(PWMK_test=-c(Longitude,Latitude))
}

estimate_mk_TrendSlope <- function(seasadj_ts){
  fit <- rtrend::mkTrend(seasadj_ts)
  out <- data.frame(fit["slp"],fit["pval"])
  colnames(out) <- c("estimate","p.value")
  out
}

ComputeMK_Stats <- function(df){
  df |>
    mutate(tst = future_map(seasadj_stl, estimate_mk_TrendSlope, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(MK_test=-c(Longitude,Latitude))
}

estimate_smk_TrendSlope <- function(obj_ts){
  fit <- trend::smk.test(obj_ts, alternative = c("two.sided"), continuity = TRUE)
  # fits <- trend::sens.slope(yts)
  data.frame(estimate=fit$estimates["S"],p.value=fit$p.value)
}


ComputeSMK_Stats <- function(df){
  df |>
    mutate(tst = future_map(data_ts, estimate_smk_TrendSlope, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(SMK_test=-c(Longitude,Latitude))
}


estimate_bcpw_TrendSlope <- function(seasadj_ts){
  ss <- as.vector(seasadj_ts)
  fit <- modifiedmk::bcpw(ss)
  out <- data.frame(fit["Sen's Slope"],fit["P-value"])
  colnames(out) <- c("estimate","p.value")
  out
}

ComputeBCPW_Stats <- function(df){
  df |>
    mutate(tst = future_map(seasadj_stl, estimate_bcpw_TrendSlope, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(BCPW_test=-c(Longitude,Latitude))
}


estimate_robust_TrendModel <- function(seasadj_ts){
  # Estimate a robust trend model
  # Standard error correction with Newey and West
  lin_trend <- 1:length(as.vector(seasadj_ts))
  fit <- MASS::rlm(seasadj_ts ~ lin_trend,method="MM")
  tst <- lmtest::coeftest(fit, vcov = sandwich::NeweyWest(fit))
  ris <- broom::tidy(tst)
  # box.tst.pvalue <- Box.test(fit$wresid,
  #                            lag=24,
  #                            type = "Ljung")$p.value
  ris |>
    filter(term=="lin_trend") |>
    select(c(estimate,std.error,p.value))
}

ComputeRobust_Stats <- function(df){
  df |>
    mutate(tst = future_map(seasadj_stl, estimate_robust_TrendModel, 
                            .options = furrr_options(seed = TRUE))) |>
    select(Longitude,Latitude,tst) |>
    unnest(cols = c(tst)) |>
    mutate(p.value_BY=p.adjust(p.value,method="BY")) |>
    mutate(sig=p.value < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig==TRUE,-1,0)) |>
    mutate(trend=factor(trend1+trend2)) |>
    mutate(trend_lab = recode(trend, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    mutate(sig_BY=p.value_BY < 0.05) |>
    mutate(trend1=ifelse(estimate > 0 & sig_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_BY==TRUE,-1,0)) |>
    mutate(trend_BY=factor(trend1+trend2)) |>
    mutate(trend_lab_BY = recode(trend_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2,sig,sig_BY)) |>
    nest(Robust_test=-c(Longitude,Latitude))
}

EvaluateTest_map <- function(mod.fit){
  if(mod.fit$pval_t>0.05) str <- "There is no map effect on trend slopes"
  else str <- "There is a map effect on trend slopes"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_t,4)),").")
}

EvaluateTest_LC <- function(mod.fit){
  if(mod.fit$pval_F>0.05) str <- "There is no land cover effect on trend slopes"
  else str <- "There is a land cover effect on trend slopes"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_F,4)),").")
}

EvaluateTest_latitude <- function(mod.fit){
  if(mod.fit$pval_F>0.05) str <- "There is no latitude effect on trend slopes"
  else str <- "There is a latitude effect on trend slopes"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_F,4)),").")
}

EvaluateTest_longitude <- function(mod.fit){
  if(mod.fit$pval_F>0.05) str <- "There is no longitude effect on trend slopes"
  else str <- "There is a longitude effect on trend slopes"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_F,4)),").")
}

EvaluateTest_lonxlc <- function(mod.fit){
  if(mod.fit$pval_F>0.05) str <- "There is no longitude and land cover interaction on trend slopes"
  else str <- "There is a land cover effect on trend slopes,  which varies with the longitude"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_F,4)),").")
}

EvaluateTest_latxlc <- function(mod.fit){
  if(mod.fit$pval_F>0.05) str <- "There is no latitude and land cover interaction on trend slopes"
  else str <- "There is a land cover effect on trend slopes, which varies with the latitude"
  paste0(str," (p.value=",as.character(round(mod.fit$pval_F,4)),").")
}