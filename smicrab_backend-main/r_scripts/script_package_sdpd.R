build.sdpd.series <- function(px="all", rry, rrXX=NULL, rrgroups=NULL, label_groups=NULL, dummy=NULL, latit=NULL, longit=NULL, n.px=NULL, 
                    vec.options=list(groups=0, px.core=0, px.neighbors=0, t_frequency=1, na.rm=T, NAcovs="pairwise.complete.obs"), 
                    titolo=NULL, type.w=c("distanze", "correlazioni")[1]){
  ### estrazione e organizzazione dei dati input, con identificazione dei valori mancanti
  ### restituisce la serie spazio-temporale, aggiungendo i vicini dei pixel selezionati, il vettore w_i dei pesi spaziali
  ### ed eventualmente la matrice X dei regressori (max 2 covariate)
  if(is.null(px)){
    if(is.null(latit)|is.null(longit)){
      if(is.null(n.px))
        n.px <- 1
      par(mfrow=c(1,1))
      plot(rry[[1]])
      cat("\n Selezionare", n.px, "pixel dal grafico mediante click....\n")
      temp <- click(rry, n=n.px, cell=T, xy=T, show=F)
      px <-  temp$cell
      longit <- temp$x
      latit <- temp$y
    }
    else{
      if(length(latit)==length(longit))
        n.px <- length(latit)
      else
        return(list(error="Latitudine e longitudine sono di lunghezza diversa."))
      px <- cellFromXY(rry, cbind(longit, latit))
    }
  }
  else if(is.numeric(px)){
    n.px <- length(px)
    temp <- xyFromCell(rry, px)
    latit <- temp[,"y"]
    longit <- temp[,"x"]
  }
  else if(is.character(px)){
    n.px <- length(px)
    if(px[1]=="all"){
      px <- seq(1, dim(values(rry))[1])
    }
    else
      px <- as.numeric(px)
    temp <- xyFromCell(rry, px)
    latit <- temp[,"y"]
    longit <- temp[,"x"]
  }
  if(n.px==0)
    return(list(error="Non ci sono serie da analizzare."))
  
  ### inizializzazione serie includenti i punti dei vicini stretti (=mat.core, che considera n°=px.core cerchi intorno ad ogni pixel)
  if(vec.options$px.core==0)
    vicini.stretti <- ww.index <- ww.values <- NULL
  else{
    mat.core <- matrix(1, ncol=2*vec.options$px.core+1, nrow=2*vec.options$px.core+1)
    mat.core[vec.options$px.core+1,vec.options$px.core+1]<- 0
    vicini.stretti <- adjacent(rry, px, pairs=TRUE, directions=mat.core, include=TRUE, symmetrical=FALSE)    
  }
  indici <- na.exclude(unique(c(px, vicini.stretti)))
  tempo <- time(rry)
  serie <- values(rry)[indici,]
  dimnames(serie)[[1]] <- indici
  dimnames(serie)[[2]] <- substr(as.character(tempo), start=1, stop=10)
  tt <- length(tempo)
  pp <- dim(serie)[1]

  ### creazione regressori
  coordinate <- xyFromCell(rry, indici)
  if(is.null(rrXX)){
    kk <- n.reg <- 0
    XX <- varX <- NULL
  }
  else if(!is.list(rrXX)){
    kk <- n.reg <- 1
  }
  else if(is.list(rrXX)){
    kk <- length(rrXX)
  }
  if(kk>0){
    n.reg <- 0
    varX <- character(kk)
    XX <- array(0, dim=c(kk, pp, tt))
    for(rr in 1:kk){
      if(!is.null(rrXX[[rr]])){
        n.reg <- n.reg+1
        if(is.character(rrXX[[rr]])){
          if(rrXX[[rr]]=="trend"){
            XX[n.reg,,] <- matrix(rep(seq(1, tt)/tt, pp), byrow=TRUE, nrow=pp)
            varX[n.reg] <- "trend"
          }
        }
        else{
          varX[n.reg] <- names(rrXX)[rr]
          pXX <- cellFromXY(rrXX[[rr]], coordinate)
          XX[n.reg,,] <- values(rrXX[[rr]])[pXX,]
        }
      }
    }
    if(n.reg>0){
      kk <- n.reg
      dimnames(XX) <- list(varX, indici, substr(as.character(tempo), start=1, stop=10)) 
    }
  }

  ### definizione dei gruppi
  if(vec.options$groups==0){
    gruppi <- rep(1, nrow=pp)
    labels <- rep("Common group", nrow=pp)
    gruppi <- cbind(COD=gruppi, LABEL=labels)
  }
  else{
    gruppi <- values(rrgroups)[indici,1]
    labels <- label_groups[as.character(gruppi)]
    gruppi <- data.frame(COD=gruppi, LABEL=labels)
  }
  dimnames(gruppi)[[1]] <- indici
  
  ## eliminazione dei pixel con valori NA
  n.NAY <- apply(serie, 1, FUN=function(x){sum(is.na(x))})
  n.NAg <- is.na(gruppi[,1])
  n.NAgor <- xor(n.NAY>0,n.NAg>0)
  if(kk>1){
    n.NAX <- t(apply(XX, c(1,2), FUN=function(x){sum(is.na(x))}))
    n.NAxor <- apply(n.NAX, 2, FUN=function(x,y){xor(x>0,y>0)}, y=n.NAY)
    tot.NAX <- apply(n.NAX, 1, sum)
  }
  else if(kk==1){
    n.NAX <- tot.NAX <- apply(XX, 1, FUN=function(x){sum(is.na(x))})
    n.NAxor <- xor(n.NAX>0,n.NAY>0)
  }
  else n.NAX <- n.NAxor <- tot.NAX <- rep(0, pp)
  if(vec.options$na.rm)
    da.mantenere <- n.NAY==0 & n.NAg==0 & tot.NAX==0
  else
    da.mantenere <- n.NAY<tt & n.NAg==0  & tot.NAX<tt
  indici.na <- indici[!da.mantenere]
  if(sum(da.mantenere)==0)
    return(list(error="Non ci sono serie da analizzare."))
  varY <- varnames(rry)[1]
  if(kk>0){
    n.NA <- cbind(coordinate, n.NAY, n.NAX, n.NAxor, n.NAgor)
    dimnames(n.NA) <- list(indici, c("lat", "lon", varY, varX, paste(varY, "XOR", varX, sep=""), paste(varY, "XORGroups")))
  }
  else if(kk==0){
    n.NA <- cbind(coordinate, n.NAY, n.NAgor)
    dimnames(n.NA) <- list(indici, c("lat", "lon", varY, paste(varY, "XORGroups")))
  }
  
  ### creazione dei vettori dei pesi spaziali w_i e verifica dei punti isolati
  if(vec.options$px.core>0){
    coordinate1 <- xyFromCell(rry, vicini.stretti[,1])
    coordinate2 <- xyFromCell(rry, vicini.stretti[,2])
    ww.index <- ww.values <- matrix(0, nrow=sum(da.mantenere), ncol=(2*vec.options$px.core+1)^2)
    dimnames(ww.index)[[1]] <- dimnames(ww.values)[[1]] <- indici[da.mantenere]
    if(type.w=="distanze"){
      WW <- distance(x=coordinate1, y=coordinate2, lonlat=TRUE, pairwise=TRUE)
      WW <- ifelse(WW==0, 0, 1/WW)
    }
    else if(type.w=="correlazioni"){
      # WW <- cor(t(serie), use=vec.options$NAcovs)
      return(list(error="Matrice spaziale basata su correlazioni non ancora implementata..."))
    }
    else return(list(error="The values set for type.w is not allowed."))
    punti.isolati <- logical(pp)
    names(punti.isolati) <- indici
    for(ii in 1:sum(da.mantenere)){
      pixel <- indici[da.mantenere][ii]
      # controlliamo prima nella prima colonna di vicini.stretti
      ww1 <- vicini.stretti[,1]==pixel
      ww2 <- vicini.stretti[ww1,2]
      to.exclude <- ww2 %in% indici.na
      ww2 <- ww2[!to.exclude]
      if(sum(ww1)-sum(to.exclude)>0){
        ww.index[ii,1:length(ww2)] <- ww2
        ww.values[ii,1:length(ww2)] <- WW[ww1][!to.exclude]
      }
      else{
        # per completezza, controlliamo anche eventuali punti aggiuntivi nella seconda colonna di vicini.stretti
        ww1 <- vicini.stretti[,2]==pixel
        ww2 <- vicini.stretti[ww1,1]
        to.exclude <- ww2 %in% indici.na
        ww2 <- ww2[!to.exclude]
        if(sum(ww1)-sum(to.exclude)>0){
          ww.index[ii,1:length(ww2)] <- ww2
          ww.values[ii,1:length(ww2)] <- WW[ww1][!to.exclude]
        }
      }
      if(sum(abs(ww.values[ii,]))>0)
        ww.values[ii,] <- ww.values[ii,]/sum(abs(ww.values[ii,]))
      else
        punti.isolati[da.mantenere][ii] <- TRUE
    }
    ww.values <- ww.values[!(punti.isolati[da.mantenere]),]
    ww.index <- ww.index[!(punti.isolati[da.mantenere]),]
    da.mantenere <- da.mantenere & !punti.isolati
    n.NA <- cbind(n.NA, punti.isolati=punti.isolati)
  }

  ## ridefinizione delle quantità al netto dei punti isolati e missing values
  if(is.null(dummy))
    index.t <- rep(T, tt)
  else
    index.t <- dummy
  indici <- as.character(indici[da.mantenere])
  serie <- serie[indici,index.t]
  XX <- XX[,indici,index.t]
  i.px <- as.character(px) %in% indici
  latit <- latit[i.px]
  longit <- longit[i.px]
  px <- px[i.px]
  n.px <- length(px)
  if(n.px==0)
    return(list(error="Tutte le serie scelte hanno valori NA nella Y o nelle covariate X o nei dintorni."))
  if(!is.null(gruppi))
    gruppi <- gruppi[as.character(px),]
  tt <- sum(index.t)
  ### titoli e sottotitoli per etichettare la serie prodotta nei grafici
  range <- paste("(from ",  substr(as.character(tempo[1]), start=1, stop=10), " to ",  substr(as.character(tempo[tt]), start=1, stop=10), ")", sep="")
  sottotitolo <- NULL
  if(n.px==1)
    sottotitolo <- paste("latitude:", latit, " longitude:", longit, "  -  ")
  if(n.reg>0)
    sottotitolo <- paste(sottotitolo, "covariates:", varX)

  ### creazione matrice index con gli indici delle serie ricadenti nell'intorno dei vicini-lontani
  if(vec.options$px.neighbors>0){
    mat.intorno <- matrix(1, ncol=2*vec.options$px.neighbors+1, nrow=2*vec.options$px.neighbors+1)
    mat.intorno[vec.options$px.neighbors+1,vec.options$px.neighbors+1]<- 0
    px.neighbors <- matrix(NA, nrow=length(indici), ncol=(2*vec.options$px.neighbors+1)^2-1)
    dimnames(px.neighbors)[[1]] <- indici
    for(ii in 1:n.px){
      temp <- adjacent(rry, cells=px[ii], directions=mat.intorno)
      temp <- temp[temp>0]
      px.neighbors[as.character(px[ii]), 1:length(temp)] <- temp
    }
    indici.intorno <- na.exclude(unique(as.vector(px.neighbors)))
    rimanenti <- indici[!(as.numeric(indici) %in% px)]
    for(ii in rimanenti){
      temp <- adjacent(rry, cells=as.numeric(ii), directions=mat.intorno)
      temp <- temp[temp>0]
      temp <- temp[temp %in% indici.intorno]
      px.neighbors[as.character(ii), 1:length(temp)] <- temp
    }
    ## controllo se alcune serie dell'intorno dei vicini-lontani includono NA, in tal caso le elimino dall'intorno
    serie.intorno <- values(rry)[indici.intorno,index.t]
    dimnames(serie.intorno)[[1]] <- indici.intorno
    dimnames(serie.intorno)[[2]] <-  substr(as.character(tempo), start=1, stop=10)
    na.intorno <- apply(serie.intorno, 1, FUN=function(x){sum(is.na(x))})
    px.neighbors <- t(apply(px.neighbors, 1, FUN=function(x, ind){ifelse(x%in%ind, NA, x)}, ind=indici.intorno[na.intorno>0]))
    ## infine, estraggo la serie dei vicini-lontani, che sarà utilizzata per il calcolo delle covarianze
    esterni <- indici.intorno[!(indici.intorno %in% indici)]
    serie.intorno <- serie.intorno[as.character(esterni),]
    px.neighbors <- list(index=px.neighbors, seriesB=serie.intorno)
  }

  ### output
  list(description=list(vars=c(varY, varX), title=paste(titolo, range), subtitle=sottotitolo),
       series=serie, X=XX, ww.index=ww.index, ww.values=ww.values, px.neighbors=px.neighbors, n.NA=data.frame(n.NA), 
       p.axis=list(pixel=px, latit=latit, longit=longit, group=gruppi, adjacent=vicini.stretti),
       t.axis=list(t.points=seq(1, tt, by=vec.options$t_frequency), t.labels= substr(as.character(tempo), start=1, stop=10)[seq(1, tt, by=vec.options$t_frequency)]))
}




check.sdpd.series <- function(series, WW=NULL, XX=NULL, coordinates=NULL, model=NULL) 
{
	## This function receives a multivariate (spatio-temporal) time series and a spatial weight matrix and some regressors,
	## then it verifies if the structure of the dataset is correct
	## series is a matrix of dimension (pp, nn) where pp is the number of univariate time series and nn the number of time observations
	## WW is a spatial weight matrix of dimension (pp,pp)
	## XX is an array of dim=c(kk, pp, nn) which includes the values for kk exogenous regressors. If kk=1 then XX is a matrix of dim=(nn,pp)

	vec.error <- vec.warning <- character(20)
	n.error <- n.warning <- 0
	
	## checking validity of series
	if(is.list(series)){
	  dseries <- series$series
    if(is.null(series$px.neighbors)){
      n.error <- n.error + 1
      vec.error[n.error] <- "\n Note that px.neighbors is NULL!"
    }
	  px.neighbors <- series$px.neighbors
	  if(is.null(XX))
	    XX <- series$X
	  if(is.null(WW))
	    WW <- series$W
    if(is.null(WW))
      WW <- list(ww.index=series$ww.index, ww.values=series$ww.values)
    if(is.null(model))
      model <- series$model
  }
	else
	  dseries <- series

	if(is.matrix(dseries)|is.data.frame(dseries)){
	  dseries <- as.matrix(dseries)
	  nn <- dim(dseries)[2]
		pp <- dim(dseries)[1]
		if(is.null(dimnames(dseries)[[1]]))
		  dimnames(dseries)[[1]] <- seq(1, pp)
		if(is.null(dimnames(dseries)[[2]]))
		  dimnames(dseries)[[1]] <- seq(1, nn)
	}
	else{
	  n.error <- n.error + 1
	  vec.error[n.error] <- "The series is not a matrix or dataframe"
	}
	
	## checking validity of regressors
	if(is.null(XX)){
	  kk <- 0
	}
	else if(is.matrix(XX)|is.data.frame(XX)){
	  kk <- 1
	  if(dim(XX)[2]!=nn){
	    n.error <- n.error + 1
	    vec.error[n.error] <- "The regressor must have the same number of observations (=columns) as the series."
	  }
	  if(dim(XX)[1]!=pp){
	    n.error <- n.error + 1
	    vec.error[n.error] <- "The regressor must have the same number of locations (=rows) as the series."
	  }
	  XX <- as.matrix(XX)
	  XX <- apply(XX, 1, FUN=function(x){x-mean(x)})
	  XX <- t(XX)
	  n.warning <- n.warning + 1
	  vec.warning[n.warning] <- "The regressor has been mean-centered."
	  dimnames(XX) <- dimnames(dseries)
	}
	else if(is.array(XX) & length(dim(XX)==3)){
	  kk <- dim(XX)[1]
	  if(dim(XX)[3]!=nn){
	    n.error <- n.error + 1
	    vec.error[n.error] <- paste("The regressors must have the same number of observations as the series (=", nn, ").", sep="")
	  }
	  if(dim(XX)[2]!=pp){
	    n.error <- n.error + 1
	    vec.error[n.error] <- paste("The regressors must have the same number of locations as the series (=", pp, ").", sep="")
	  }
	  XX <- apply(XX, c(1,2), FUN=function(x){x-mean(x)})
	  XX <- aperm(XX, c(2,3,1))
	  dimnames(XX)[[3]] <- dimnames(dseries)[[2]]
	  dimnames(XX)[[2]] <- dimnames(dseries)[[1]]
	  if(is.null(dimnames(XX)[[1]]))
	    dimnames(XX)[[1]] <- paste("varX", seq(1, kk), sep="")
	  n.warning <- n.warning + 1
	  vec.warning[n.warning] <- "The regressors have been mean-centered."
	}
	else{
	  n.error <- n.error + 1
	  vec.error[n.error] <- "Something wrong with the regressor X."
	  kk <- 0
	  XX <- NULL
	}
	
	## checking validity of the model
	if(is.null(model))
	  model <- list(lambda.coeffs=c(T,T,T), beta.coeffs=rep(T, kk), fixed_effects=T, time_effects=F)
	if(is.null(model$lambda.coeffs)|length(model$lambda.coeffs)>3|length(model$lambda.coeffs)==0|sum(model$lambda.coeffs)==0|(!is.logical(model$lambda.coeffs))){
	  n.error <- n.error+1
	  vec.error[n.error] <- "There are problems with the lambda-coefficients in the model to be estimated."
	}
	else if(length(model$lambda.coeffs)<3){
	  temp <- rep(FALSE, 3)
	  temp[1:length(model$lambda.coeffs)] <- model$lambda.coeffs
	  model$lambda.coeffs <- temp
	  n.warning <- n.warning+1
	  vec.warning[n.warning] <- "Some of the lambda-coefficients have been added, please check if the model is OK."
	}
	if(is.null(names(model$lambda.coeffs)))
	  names(model$lambda.coeffs) <- c("lambda0", "lambda1", "lambda2")
	if(is.null(model$beta.coeffs)|length(model$beta.coeffs)==0|sum(model$beta.coeffs)==0|kk==0|(!is.logical(model$beta.coeffs))){
	  if((is.logical(model$beta.coeffs) & sum(model$beta.coeffs)>0) | kk>0){
	    n.warning <- n.warning+1
	    vec.warning[n.warning] <- "The beta coefficients have been removed due to some problems, please check the model."
	  }
	  model$beta.coeffs <- NULL
	}
	else if(length(model$beta.coeffs)!=kk){
	  n.error <- n.error+1
	  vec.error[n.error] <- "The number of beta-coefficients does not match with the number of regressors. Please check the data and the model."
	  model$beta.coeffs <- NULL
	}
	else if(sum(model$beta.coeffs)!=kk){
	  n.warning <- n.warning+1
	  vec.warning[n.warning] <- "Some regressors have been removed, please check the model."
	}
	kk <- sum(model$beta.coeffs)
	if(kk==0){
	  if(!is.null(XX)){
	    n.warning <- n.warning+1
	    vec.warning[n.warning] <- "The model has no exogenous regressors, so the covariates X has been removed."
	    XX <- NULL
	  }
  }
	else if(kk>1 & is.array(XX)){
	  names(model$beta.coeffs) <- dimnames(XX)[[1]]
	  XX <- XX[model$beta.coeffs,,]
	  model$beta.coeffs <- model$beta.coeffs[model$beta.coeffs]
	}
	else names(model$beta.coeffs) <- "varX1"
	
	if(is.null(model$fixed_effects) | !is.logical(model$fixed_effects)){
	  model$fixed_effects <- FALSE
	  n.warning <- n.warning+1
	  vec.warning[n.warning] <- "The model has not the fixed effects...please check if this is OK."
	}
	if(model$fixed_effects)
	  mu <- apply(dseries, 1, mean)
	else mu <- numeric(pp)
	
	if(is.null(model$time_effects)| !is.logical(model$time_effects))
	  model$time_effects <- FALSE
	if(model$time_effects){
	  time_effects <- apply(dseries, 2, mean)
	  dseries <- dseries - matrix(rep(time_effects, pp), nrow=pp, byrow = TRUE)
	}
	else time_effects <- numeric(nn)
	
	## checking validity of the spatial matrix
	if(is.null(WW)){
	  n.error <- n.error + 1
	  vec.error[n.error] <- "The spatial matrix W is missing."
	}
	else if(is.list(WW)){
	  if(is.null(WW$ww.index)|is.null(WW$ww.values)){
	    n.error <- n.error + 1
	    vec.error[n.error] <- "The spatial matrix W is missing or not complete."
	  }
	  else{
	    WW.temp <- matrix(0, nrow=pp, ncol=pp)
	    dimnames(WW.temp)[[1]] <- dimnames(WW.temp)[[2]] <- dimnames(dseries)[[1]]
	    for(ii in 1:pp){
	      indici <- as.character(WW$ww.index[ii,WW$ww.index[ii,]>0])
	      WW.temp[ii, indici] <- WW$ww.values[ii,WW$ww.index[ii,]>0]
	    }
	    WW <- WW.temp
	  }
	}
	else if(is.matrix(WW)){
	  if(dim(WW)[1]!=pp){
	    n.error <- n.error + 1
	    vec.error[n.error] <- "The spatial matrix has not the correct number of rows."
	  }
	  if(dim(WW)[2]!=pp){
	    n.error <- n.error + 1
	    vec.error[n.error] <- "The spatial matrix has not the correct number of columns."
	  }
	  dimnames(WW)[[1]] <- dimnames(WW)[[2]] <- dimnames(dseries)[[1]]
	}
	else{
	  n.error = n.error+1
	  vec.error[n.error] <- "Something wrong with the spatial matrix."
	} 
	if(sum(is.na(WW))>0){
	  n.error <- n.error + 1
	  vec.error[n.error] <- "The spatial matrix cannot have NA values."
	}
	if(sum(diag(WW))!=0 & var(diag(WW))!=0){
	  n.error <- n.error + 1
	  vec.error[n.error] <- "The spatial matrix has not zero diagonal."
	}
	indici.w <- apply(abs(WW), 1, sum)==0
	if(sum(indici.w)>0){
	  n.error <- n.error + 1
	  vec.error[n.error] <- "The spatial matrix has one (or more than one) zero-row(s)."
	}

	
	## checking the missing values	
	na <- sum(is.na(dseries))
	if(na>0){
	  n.warning = n.warning+1
	  vec.warning[n.warning] <- "The series has NA values."
	}
	if(kk==0)
	  naX <- 0
	else if(kk==1)
	  naX <- sum(is.na(XX))
	else if(kk>1)
	  naX <- apply(XX, 1, FUN=function(x){sum(is.na(x))})
	if(sum(naX)!=0){
	  n.warning = n.warning+1
	  vec.warning[n.warning] <- "There are some missing values in the covariates X."
	  na <- c(na, naX)
	  names(na) <- c("naY", paste("naX", seq(1,kk), sep=""))	  
	}

	## returning the structure of data
	list(series=dseries, WW=WW, XX=XX, intorno=px.neighbors, mu=mu, time_effects=time_effects, nn=nn, pp=pp, kk=kk, na=na, model=model, errors=vec.error[vec.error!=""], warnings=vec.warning[vec.warning!=""])
}



plot.sdpd.series <- function(serie.obj, ts.units=as.character(serie.obj$p.axis$pixel), t.axis=serie.obj$t.axis, differences=TRUE){
  dserie <- serie.obj$series
  nn <- dim(dserie)[2]
  pp <- dim(dserie)[1]
  indici <- seq(1, pp)
  names(indici) <- dimnames(serie.obj$series)[[1]]
  subtitle <- "time series (red) and its 8 nearest-neighbours (grey)"
  if(differences)
    subtitle <- paste("differences (black) between the ", subtitle, sep="")
  if(!is.null(serie.obj$new.serie))
    subtitle <- paste(subtitle, "; in blue the imputed missing values", sep="")
  if(is.character(ts.units) & ts.units[1]=="all")
    units <- seq(1, pp)
  else if(is.character(ts.units)){
    units <- na.omit(indici[ts.units])
  }
  else if(is.numeric(ts.units)){
    units <- seq(1, length(ts.units))
    ts.units <- as.character(ts.units)
  }
  for(ii in units){
    par(mfrow=c(1,1), las=2)
    cont <- 0
    offset <- diff(range(dserie[ii,], na.rm=T))*1.2
    if(is.matrix(serie.obj$p.axis$group))
      nn.gruppo <- serie.obj$p.axis$group[ii,2]
    else if(is.vector(serie.obj$p.axis$group))
      nn.gruppo <- serie.obj$p.axis$group[2]
    else
      nn.gruppo <- NULL
    plot.title <- paste(serie.obj$description$title, " for spatial unit i=", ts.units[ii], " (group=", nn.gruppo, ")", sep="")
    ylimit <- range(dserie[ii,], dserie[ii,]+offset*8, na.rm=T)
    cat("\n unit=", ts.units[ii], " (group=", nn.gruppo, ")", sep="")
    ts.plot(dserie[ii,], ylim=ylimit, ylab="Spatial units", xlab="", gpars = list(axes=F), col=2)
    title(main=paste(plot.title, "\n", subtitle, sep=""), cex.main=0.8)
    if(!is.null(serie.obj$new.serie)){
      lines(seq(1,nn), serie.obj$new.serie[,ii]+cont*offset, col="blue")
    }
    indici2 <- serie.obj$p.axis$adjacent[,1]==as.numeric(ts.units[ii])
    if(sum(indici2)>9){
      indici.eccedenti <- seq(1, length(indici2))[indici2]
      indici.eccedenti <- indici.eccedenti[10:length(indici.eccedenti)]
      indici2[indici.eccedenti] <- FALSE
    }
    vicini <- serie.obj$p.axis$adjacent[indici2,2]
    vicini <- vicini[vicini%in%dimnames(serie.obj$series)[[1]]]
    for(jj in indici[as.character(vicini)]){
      if(jj==ii)
        next
      cont <- cont+1
      lines(seq(1, nn), dserie[jj,]+cont*offset, col="grey", lwd=1)
      if(differences)
        lines(seq(1, nn), ylimit[1]+(dserie[jj,]-dserie[ii,])+cont*offset, col="black", lwd=1)
      if(!is.null(t.axis$t.points)){
        if(length(t.axis$t.points)!=length(t.axis$t.labels))
          t.axis$t.points <- NULL
      }
      if(is.null(t.axis$t.points))
        t.axis$t.points <- t.axis$t.labels <- seq(1, nn, by=nn%/%10)
      axis(1, at=t.axis$t.points, labels=t.axis$t.labels, cex.axis=0.6)
      box()  
      ### completamento con eventuali missing values imputati
      if(!is.null(serie.obj$new.serie)){
        lines(seq(1,nn), serie.obj$new.serie[,jj]+cont*offset, col="blue")
        serie1 <- ifelse(is.na(serie.obj$series[jj,]), serie.obj$new.serie[,jj], NA)
        serie2 <- ifelse(is.na(serie.obj$series[ii,]), serie.obj$new.serie[,ii], NA)
        lines(seq(1,nn), (serie1-serie2)+cont*offset, col="black")
      }
    }
    cont2 <- cont
    while(cont2+1<9){
      cont2 <- cont2+1
      text(1, mean(range(dserie[ii,]))+cont2*offset, "all NAs", col="grey", adj=0)
      lines(seq(1,nn), rep(mean(range(dserie[ii,]))+cont2*offset, nn), col="grey", lty=3)
    }
    etichette <- character(9)
    etichette[1:(cont+1)] <- vicini
    axis(2, at=mean(range(dserie[ii,], na.rm=T))+seq(0, 8)*offset, labels=etichette, cex.axis=0.6)
    if(!ii==units[length(units)]){
      cat("\n click on the plot window for the next panel....")
      pos <- locator(1)
    }
    else
      cat("\n panels are finished....")
  }
}



fit.sdpd.model <- function(series, W=NULL, X=NULL, coordinates=NULL, model=list(lambda.coeffs=c(T,T,T), beta.coeffs=NULL, fixed_effects=T, time_effects=F),
                           data.back=TRUE, vec.options=list(two.stage=FALSE, NAcovs="pairwise.complete.obs")) 
{
  ## dseries is a matrix of dimension (nn,pp) where pp is the number of univariate time dseries and data$nn the number of time observations
  ## W is a spatial weight matrix of dimension (pp,pp)
  ## X is an array of dim=c(kk,nn,pp) which includes the data for kk exogenous regressors. If kk=1 then X is a matrix of dim=(nn,pp)
  
  ## checking validity of parameters...
  data <- check.sdpd.series(series=series, WW=W, XX=X, coordinates=coordinates, model=model)
  
  if(length(data$errors)>0){
    cat("\n There are some errors....", data$errors)
    return(list(errors=data$errors, warnings=data$warnings))
  }
  COVs <- fit.sdpd.covs(series=data$series, X=data$XX, px.neighbors=data$intorno, kk=data$kk, nn=data$nn, pp=data$pp, vec.options=vec.options)

  ## estimating model parameters...
  fit <- fit.sdpd.coefficients(W=data$WW, COVs=COVs, mu=data$mu, model=data$model)

  ## estimating fitted values...
  res <- fit.sdpd.series(dseries=data$series, W=data$WW, X.centr=data$X, model=data$model, lambda.hat=fit$coeff.hat, time_effects=data$time_effects)
  
  ## returning estimation results
  if(data.back)
    data.back <- list(series=data$series, W=data$WW, X=data$XX, intorno=data$intorno)
  else
    data.back <- NULL
  list(coeff.hat=fit$coeff.hat, fitted=res$fitted, resid=res$resid, time_effects=data$time_effects, data=data.back, model=data$model, errors=data$errors, warnings=data$warning)
}


fit.sdpd.covs <- function(series, X=NULL, kk=0, px.neighbors=NULL, nn, pp, vec.options=list(NAcovs="pairwise.complete.obs")){
  
  if(is.null(px.neighbors)){
    seriesB <- series
    index <- matrix(rep(dimnames(series)[[1]], pp), byrow = T, nrow = pp)
    dimnames(index)[[1]] <- dimnames(series)[[1]]
  }
  else{
    seriesB <- rbind(series, px.neighbors$seriesB)
    index <- px.neighbors$index
  }
  cov12 <- cov(t(series)[2:nn,],t(seriesB)[-nn,], use=vec.options$NAcovs)
  cov11 <- cov(t(series), t(seriesB), use=vec.options$NAcovs)
  if(kk==0)
    covX <- NULL
  else if(kk==1)
    covX <- cov(t(X)[2:nn,],t(seriesB)[-nn,], use=vec.options$NAcovs)
  else if(kk>1){
    covX <- array(0, dim=c(dim(X)[1], dim(X)[2], dim(seriesB)[1]))
    dimnames(covX)[[1]] <- dimnames(X)[[1]]
    dimnames(covX)[[2]] <- dimnames(X)[[2]]
    dimnames(covX)[[3]] <- dimnames(seriesB)[[1]]
    for(jj in 1:kk)
      covX[jj,,] <- cov(t(X[jj,,2:nn]),t(seriesB)[-nn,], use=vec.options$NAcovs)
  }
  COVs <- list(index=index, cov11=cov11, cov12=cov12, covX=covX)
}


fit.sdpd.coefficients <- function (W, COVs, mu, model) 
{
  lambda.names <- names(model$lambda.coeffs)[model$lambda.coeffs]
  beta.names <- names(model$beta.coeffs)[model$beta.coeffs]
  fixed_effects.name <- c("fixed_effects")[model$fixed_effects]
  px <- dimnames(W)[[1]]
  data <- list(WW=W, pp=length(px), kk=length(beta.names))
  
  ## variable definition...
  lambda.hat	<- matrix(0, nrow=data$pp, ncol=sum(model$fixed_effects)+sum(model$lambda.coeffs)+sum(model$beta.coeffs))
  dimnames(lambda.hat)[[2]] <- c(lambda.names, beta.names, fixed_effects.name)
  dimnames(lambda.hat)[[1]] <- px
  ei <- numeric(data$pp); names(ei) <- px
  ## estimation of coefficients...
  invertible <- function(m) class(try(solve(m),silent=T))[1]=="matrix"
  if(data$kk==0){
    num.coeff <- sum(model$lambda.coeffs)
    for(ii in px){
      wi <- W[ii,]
      ei[px] <- 0; ei[ii] <- 1
      indici <- as.character(na.exclude(COVs$index[ii,]))
      Yi <- t(COVs$cov12[,indici])%*%ei
      Xi <- cbind(t(COVs$cov12[,indici])%*%wi, t(COVs$cov11[,indici])%*%ei, t(COVs$cov11[,indici])%*%wi)[,model$lambda.coeffs]
      if(!invertible(t(Xi)%*%Xi)){
        lambda.hat[ii,1:num.coeff] <- NA
        next
      }
      lambda.hat[ii,1:num.coeff] <- solve(t(Xi)%*%Xi)%*%t(Xi)%*%Yi
    }
  }
  else if(data$kk==1){
    num.coeff <- sum(model$lambda.coeffs)+1
    for(ii in px){
      wi <- W[ii,]
      ei[px] <- 0; ei[ii] <- 1
      indici <- as.character(na.exclude(COVs$index[ii,]))
      Yi <- t(COVs$cov12[,indici])%*%ei
      Xi <- cbind(t(COVs$cov12[,indici])%*%wi, t(COVs$cov11[,indici])%*%ei, t(COVs$cov11[,indici])%*%wi, t(COVs$covX[,indici])%*%ei)[,c(model$lambda.coeffs,T)]
      if(!invertible(t(Xi)%*%Xi)){
        lambda.hat[ii,1:num.coeff] <- NA
        next
      }
      lambda.hat[ii,1:num.coeff] <- (solve(t(Xi)%*%Xi)%*%t(Xi)%*%Yi)
    }
  }
  else if(data$kk>1){
    num.coeff <- sum(model$lambda.coeffs)+data$kk
    for(ii in px){
      wi <- W[ii,]
      ei[px] <- 0; ei[ii] <- 1
      indici <- as.character(na.exclude(COVs$index[ii,]))
      Yi <- t(COVs$cov12[,indici])%*%ei
      Xi <- cbind(t(COVs$cov12[,indici])%*%wi, t(COVs$cov11[,indici])%*%ei, t(COVs$cov11[,indici])%*%wi)[,model$lambda.coeffs]
      Xi <- cbind(Xi, t(COVs$covX[beta.names,ii,indici]))
      if(!invertible(t(Xi)%*%Xi)){
        lambda.hat[ii,1:num.coeff] <- NA
        next
      }
      lambda.hat[ii,1:num.coeff] <- (solve(t(Xi)%*%Xi)%*%t(Xi)%*%Yi)
    }
  }
  if(model$fixed_effects){
    ll0 <- ll1 <- ll2 <- matrix(0, ncol=data$pp, nrow=data$pp)
    if(model$lambda.coeffs[1]) ll0 <- diag(lambda.hat[,"lambda0"])%*%W
    if(model$lambda.coeffs[2]) ll1 <- diag(lambda.hat[,"lambda1"])
    if(model$lambda.coeffs[3]) ll2 <- diag(lambda.hat[,"lambda2"])%*%W
    B <- diag(rep(1, data$pp))-ll0-ll1-ll2
    lambda.hat[,"fixed_effects"] <- B%*%mu
  }
  
  ## estimation results...
  list(coeff.hat=lambda.hat)
}



fit.sdpd.series <- function(dseries, W, X.centr=NULL, model, lambda.hat, time_effects=NULL, resid=FALSE) 
{
  beta.names <- names(model$beta.coeffs)[model$beta.coeffs]
  px <- dimnames(dseries)[[1]]
  time <- dimnames(dseries)[[2]]
  data <- list(pp=length(px), nn=length(time), kk=length(beta.names))
  
  ## variable definition...
  ll0 <- ll1 <- ll2 <- matrix(0, nrow=data$pp, ncol=data$pp)
  Id <- diag(rep(1, data$pp))
  llk <- llc <- matrix(0, nrow=data$pp, ncol=data$nn)
  if(model$lambda.coeffs["lambda0"]) ll0 <- diag(lambda.hat[,"lambda0"])
  if(model$lambda.coeffs["lambda1"]) ll1 <- diag(lambda.hat[,"lambda1"])
  if(model$lambda.coeffs["lambda2"]) ll2 <- diag(lambda.hat[,"lambda2"])
  if(is.null(model$time_effects) | !model$time_effects | is.null(time_effects))
    time_effects <- numeric(data$nn)
  llv <- matrix(rep(time_effects, data$pp), byrow = TRUE, nrow=data$pp)
  if(model$fixed_effects){
    llc <- lambda.hat[,"fixed_effects"]%*%t(rep(1, data$nn))
  }
  if(data$kk==1){
    llk <- diag(lambda.hat[,beta.names[1]])%*%X.centr
  }
  else if(data$kk>1){
    for(jj in 1:data$kk) 
      llk <- llk + diag(lambda.hat[,beta.names[jj]])%*%X.centr[jj,,]
  }
  
  ## estimation results...
  if(resid){
    tempI  <- solve(Id-ll0%*%W)
    AA		<- tempI%*%(ll1 + ll2%*%W)
    eps.star1 	<- tempI%*%(llk + llc + dseries)
    for(tt in 2:data$nn)
      dseries[,tt] <- AA%*%(dseries)[,tt-1]+ eps.star1[,tt]
  }
  fitted <- ll0%*%W%*%dseries[,2:data$nn]+(ll1+ll2%*%W)%*%dseries[,-data$nn]+llk[,-1]+llc[,-1]+llv[,-1]
  fitted <- cbind(rep(NA, data$pp), fitted)
  resid	<- dseries - fitted

  dimnames(resid)[[1]] <- dimnames(fitted)[[1]] <- px
  dimnames(resid)[[2]] <- dimnames(fitted)[[2]] <- time
  
  ## return...
  list(series=dseries, fitted=fitted, resid=resid)
}



plot.sdpd.model <- function (res.fit, n.units="all", n.vars="all", which=c(1,2)[1], t.axis=list(t.labels=NULL, t.points=NULL), xlimit=NULL, ylimit=NULL, max.col=5, col.punti=1)
{
  if(which==1)
    plot1.sdpd.model(res.fit=res.fit, n.units=n.units, n.vars=n.vars, t.axis=t.axis, xlimit=xlimit, ylimit=ylimit, max.col=max.col, col.punti=col.punti)
}


plot1.sdpd.model <- function (res.fit, n.units="all", n.vars="all", t.axis=list(t.labels=NULL, t.points=NULL), xlimit=NULL, ylimit=NULL, max.col=5, col.punti=1) 
{
	## res.fit is an object with the following components:
	## "coeff.hat" "series"    "WW"        "XX"        "fitted"    "resid"     "errors"    "warnings"  "model" 
  
  ## definizioni variabili e dimensioni
  dserie <- res.fit$data$series
  XX <- res.fit$data$X
	nn <- dim(dserie)[2]
	pp <- dim(dserie)[1]
	alpha.hat <- res.fit$coeff.hat
	error <- NULL

	## definizione pannelli da rappresentare graficamente
	panels <- dimnames(res.fit$coeff.hat)[[2]]
	i.panels <- rep(FALSE, length(panels))
	if(is.logical(n.vars)){
    nn.p <- min(length(n.vars), length(i.panels))
	 	i.panels[1:nn.p] <- n.vars[1:nn.p]
	}
	else if(is.numeric(n.vars)&length(n.vars)==1){
	  nn.p <- min(length(i.panels), as.integer(n.vars))
	  i.panels[1:nn.p] <- TRUE
	}
	else if(is.numeric(n.vars)){
	  check <- as.integer(n.vars)%in%seq(1,length(i.panels))
	  n.vars <- as.integer(n.vars)[check]
	  nn.p <- min(length(n.vars), length(i.panels))
	  i.panels[n.vars[1:nn.p]] <- TRUE
	}
	else if(n.vars[1]=="all"){
	  n.vars <- dimnames(res.fit$coeff.hat)[[2]]
	  i.panels <- panels%in%n.vars
	}
	else if(is.character(n.vars)){
	  i.panels <- panels%in%n.vars
	}
	else return(error="Il valore passato all'argomento n.vars non segue il formato previsto")
	
	panels <- panels[i.panels]
	if(length(which(panels=="fixed_effects"))>0)
  	panels <- panels[-which(panels=="fixed_effects")]
	n.col <- min(max.col, length(panels))
  if(n.units[1]=="all")
    n.units <- seq(1, dim(res.fit$data$series)[1])
	if(is.character(n.units)|is.numeric(n.units)){
	  indici <- seq(1, dim(res.fit$data$series)[1])
	  names(indici) <- dimnames(res.fit$data$series)[[1]]
	  n.units <- indici[n.units]
	}
	else return(error="Il valore passato all'argomento n.units non segue il formato previsto")
	if(res.fit$model$fixed_effects)
	  fixed_effects.text <- "fixed effect (dashed grey) & "
	else
	  fixed_effects.text <- ""

		## ciclo principale per la costruzione dei grafici
	op <- par(no.readonly = TRUE)
	for(ii in n.units){
	  if(sum(is.na(res.fit$coeff.hat[ii,]))>0){
	    cat("\n There are missing estimated coefficients for this series ")
	    next
	  }
	  beta.cont <- 0
	  par(mfcol=c(2,n.col), mai=c(1, 0.8, 0.5, 0.5), las=2)
		for(panel in panels[1:n.col]){
		  xlimit <- ylimit <- NULL
		  if(panel=="lambda0") jj <- 1
		  else if(panel=="lambda1") jj <- 2
		  else if(panel=="lambda2") jj <- 3
		  else{
		    jj <- 4
		    beta.cont <- beta.cont+1
		    if(is.matrix(res.fit$data$X)){
		      titolo1 <- substitute(bold(str0*str1)*str2*hat(beta)[i] == y, list(str0="i=", str1=dimnames(dserie)[[1]][ii], str2=": ", y = round(alpha.hat[ii,panel], digits=6)))
		      XX <- res.fit$data$X
		      nomeX <- "X"
		    }
		    else if(is.array(res.fit$data$X)){
		      titolo1 <- substitute(bold(str0*str1)*str2*hat(beta)[i] == y, list(str0="i=", str1=dimnames(dserie)[[1]][ii], str2=": ", y = round(alpha.hat[ii,panel], digits=6)))
		      XX <- res.fit$data$X[panel,,]
		      nomeX <- panel
		    }
		  }
		  if(jj==4){
		    lag <- 0
		    Wdserie <- XX
			  yll <- expression(y[i*t])
			  xll <- substitute(str0[str1*str2], list(str0=nomeX, str1="i", str2="t"))
			  plot.title <- paste("Left axis: observed series (black) & ", nomeX, "'s signal (green)\n Right axis: ", fixed_effects.text, "residuals (solid grey)", sep="")
			  off.color <- 1
		  }
			else if(jj==3){
			  lag <- 1
				Wdserie <- res.fit$data$W%*%dserie
				yll <- expression(y[i*t])
				xll <- expression(bold(w)[i]*bold(y)[t-1])
				plot.title <- paste("Left axis: observed series (black) & spatial-dynamic signal (yellow)\n Right axis: ", fixed_effects.text, "residuals (solid grey)", sep="")
				titolo1 <- substitute(bold(str0*str1)*str2*hat(lambda)[x*i] == y, list(str0="i=", str1=dimnames(dserie)[[1]][ii], str2=": ", x = 2, y = round(alpha.hat[ii,panel], digits=6)))
				off.color <- 5
			}
			else if(jj==2){
			  lag <- 1
				Wdserie <- dserie
				yll <- expression(y[i*t])
				xll <- expression(y[i*(t-1)])
				plot.title <- paste("Left axis: observed series (black) & pure dynamic signal (blue)\n Right axis: ", fixed_effects.text, "residuals (solid grey)", sep="")
				titolo1 <- substitute(bold(str0*str1)*str2*hat(lambda)[x*i] == y, list(str0="i=", str1=dimnames(dserie)[[1]][ii], str2=": ", x = 1, y = round(alpha.hat[ii,panel], digits=6)))
				off.color <- 2
			}
			else{
			  lag <- 0
				Wdserie <- res.fit$data$W%*%dserie
				yll <- expression(y[i*t])
				xll <- expression(bold(w)[i]*bold(y)[t])
				plot.title <- paste("Left axis: observed series (black) & pure spatial signal (red)\n Right axis: ", fixed_effects.text, "residuals (solid grey)", sep="")
				titolo1 <- substitute(bold(str0*str1)*str2*hat(lambda)[x*i] == y, list(str0="i=", str1=dimnames(dserie)[[1]][ii], str2=": ", x = 0, y = round(alpha.hat[ii,panel], digits=6)))
				off.color <- 0
			}
			#### plot of spatial regression
		  if(is.null(xlimit))
				xlimit <- range(Wdserie[ii,], na.rm=T)
			if(is.null(ylimit))
				ylimit <- range(dserie[ii,], na.rm=T)
		  plot(Wdserie[ii,1:(nn-lag)], dserie[ii,(1+lag):nn], ylim=ylimit, xlim=xlimit, xlab="", ylab="", cex.lab=1.5, cex.axis=0.9, col=col.punti)
			title(xlab=xll, ylab=yll, cex.lab=1.5, cex.main=1.5, main=titolo1)
			lines(xlimit, xlimit*alpha.hat[ii,panel], col=2+off.color, lwd=1, lty=1)
			#### plot of spatial and residual estimated series
			fun.asse2 <- function(x, ylim1, ylim2){
			  y <- ylim1[1]+(x-ylim2[1])*range(ylim1)/range(ylim2)
			  y
			}
			ylimitb <- range(dserie[ii,], alpha.hat[ii,panel]*Wdserie[ii,1:(nn-lag)],na.rm=T)
			if(res.fit$model$fixed_effects)
			  ylimitc <- range(res.fit$resid[ii,], res.fit$coeff.hat[ii,"fixed_effects"], na.rm=T)
			else
			  ylimitc <- range(res.fit$resid[ii,], na.rm=T)
			dum <- 0
			if(abs(ylimitc[2]-ylimitb[2])<diff(ylimitb)*0.1 & abs(ylimitc[1]-ylimitb[1])<diff(ylimitb)*0.1)
			  ylimitb <- range(ylimitb, ylimitc)
			else if(ylimitc[2]<ylimitb[1]-diff(ylimitb)*0.1){
			  ylimitb[1] <- ylimitb[1]-diff(ylimitb)*0.1
			}
			else if(ylimitc[1]>ylimitb[2]+diff(ylimitb)*0.1){
			  ylimitb[2] <- ylimitb[2]+diff(ylimitb)*0.1
			}
			ts.plot(dserie[ii,(1+lag):nn], ylim=ylimitb, xlab="", ylab="", gpars = list(axes=F, cex.main=0.9), type="n", main=paste(plot.title))
			lines(seq(1, nn), fun.asse2(res.fit$resid[ii,], ylim1=ylimitc, ylim2=ylimitc), col="grey")
			abline(h=fun.asse2(0, ylim1=ylimitc, ylim2=ylimitc), col="grey")
			if(res.fit$model$fixed_effects)
			  abline(h=fun.asse2(res.fit$coeff.hat[ii,"fixed_effects"], ylim1=ylimitc, ylim2=ylimitc), col="grey", lty=2)
			lines(seq(1+lag, nn), dserie[ii,(1+lag):nn])
			lines(seq(1+lag, nn), alpha.hat[ii,panel]*Wdserie[ii,1:(nn-lag)], col=2+off.color, lwd=1)
			axis(2)
			#if(res.fit$model$fixed_effects)
			#  axis(4, at=c(seq(0, ylimitb[2], by=10), fun.asse2(res.fit$coeff.hat[ii,"fixed_effects"])), labels=c(seq(0, ylimitb[2], by=10), round(res.fit$coeff.hat[ii,"fixed_effects"], 2)), cex.axis=0.6, col.ticks="grey")
			#else
			#  axis(4, at=c(seq(0, ylimitb[2], by=10))-dum*ylimitc[1]+dum*ylimitb[1], labels=c(seq(0, ylimitb[2], by=10)), cex.axis=0.6, col.ticks="grey")
			if(!is.null(t.axis$t.points)){
				if(length(t.axis$t.points)!=length(t.axis$t.labels))
				error <- error + 1
				t.axis$t.points <- NULL
			}
			if(is.null(t.axis$t.points)){
			  t.axis$t.points <- seq(1, nn, by=nn%/%15)
			  t.axis$t.labels  <- dimnames(res.fit$data$series)[[2]][t.axis$t.points]
			}
			axis(1, at=t.axis$t.points, labels=t.axis$t.labels, cex.axis=0.8)
			box()
		}
	  cat("\n unit=", ii)
	  if(!ii==n.units[length(n.units)]){
	    cat("\n click on the plot window for the next panel....")
	    pos <- locator(1)
	  }
	  else
	    cat("\n panels are finished...")
	}
	if(length(error)>0)
  	list(error=error)
}

bootstrap.sdpd.model <- function(n.boot=399, boot.plot=TRUE){
  if(n.boot<200)
    return(error="n. repliche bootstrap insufficienti")
  else{
    ll0 <- ll1 <- ll2 <- Id <- diag(rep(1, pp))
    diag(ll0) <- diag(ll1) <- diag(ll2) <- 0
    mu <- numeric(pp)
    llk <- llc <- matrix(0, nrow=pp, ncol=nn)
    if(res.fit$model$lambda.coeffs["lambda0"]) ll0 <- diag(lambda.hat[,"lambda0"])
    if(res.fit$model$lambda.coeffs["lambda1"]) ll1 <- diag(lambda.hat[,"lambda1"])
    if(res.fit$model$lambda.coeffs["lambda2"]) ll2 <- diag(lambda.hat[,"lambda2"])
    if(res.fit$model$fixed_effects){
      llc <- lambda.hat[,"fixed_effects"]%*%t(rep(1, nn))
      mu <- apply(dserie, 1, mean)
    }
    if(kk>0){
      if(is.matrix(res.fit$data$X))
        llk <- diag(lambda.hat[,beta.names[1]])%*%res.fit$data$X
      else if(is.array(res.fit$data$X)){
        for(rr in beta.names)
          llk <- llk + diag(lambda.hat[,rr])%*%res.fit$data$X[rr,,]
      }
      else return(error="Something wrong with the X data matrix")
    } 
    boot.rep	<- array(0, dim=c(n.boot, pp, dim(lambda.hat)[2]))	
    devs.tsboot <- matrix(0, nrow=n.boot, ncol=pp)
    boot.ind 	<- matrix(sample(i.resid, size=(nn)*n.boot, replace = TRUE), nrow=n.boot)
    tempI  <- solve(Id-ll0%*%res.fit$data$W)
    AA		<- tempI%*%(ll1 + ll2%*%res.fit$data$W)
    
    ## bootstrap iterations...
    if(boot.plot) par(mfrow=c(3,1))
    for(bb in 1:n.boot){
      eps.star1 	<- tempI%*%(llk + llc + resid[,boot.ind[bb,]])
      yy.star1 		<- dserie
      if(type.boot=="markoviano"){
        for(tt in 2:nn)
          yy.star1[,tt] <- AA%*%(yy.star1)[,tt-1]+ eps.star1[,tt]
      }
      else if(type.boot=="regressive"){
        yy.star1[,2:nn] <- AA%*%yy.star1[,1:(nn-1)] + eps.star1[,2:nn]
      }				
      else return(error="tipo di ricampionamento bootstrap non implementato")
      
      COVs <- fit.sdpd.covs(series=yy.star1, X=res.fit$data$X, kk=kk, nn=nn, pp=pp)
      boot.rep[bb,,] <- fit.sdpd.coefficients(W=res.fit$data$W, COVs=COVs, mu=mu, model=res.fit$model)$coeff.hat
      devs.tsboot[bb,] <- apply(yy.star1-dserie, 1, sd)
      if(bb%%100==0 & boot.plot){
        cat("\n boot iterations:", bb-100+1, "-", bb, "...one of the bootstrapped time series is plotted for control")
        jji <- sample(1:pp, size=1)
        titolo <- paste("True series (red) vs bootstrap series (black=full or green=partial)\n core.points=", sum(abs(res.fit$data$W[jji,])>0), sep="")
        titolo <- paste(titolo, " - pixel=", dimnames(dserie)[[1]][jji], " - group=", label.index[jji], sep="")
        ts.plot(yy.star1[jji,], main=titolo, col=group.index[jji])
        lines(seq(1,nn), dserie[jji,], col=2)
      }
    }
  }
  boot.rep
}



check.sdpd.model <- function(res.fit, correzione=TRUE){
  
  pp <- dim(res.fit$data$series)[1]
  nn <- dim(res.fit$data$series)[2]
  kk <- sum(res.fit$model$beta.coeffs)
  mu <- apply(res.fit$data$series, 1, mean)
  ll0 <- ll1 <- ll2 <- matrix(0, ncol=pp, nrow=pp)
  
  ## calcoliamo autovalori delle componenti della matrice ridotta A
  coeff.hat <- res.fit$coeff.hat
  vettore1 <- vettore2 <- eigenA <- rep(0, pp)
  if("lambda0"%in%dimnames(res.fit$coeff.hat)[[2]]){
    ll0 <- diag(coeff.hat[,"lambda0"])%*%res.fit$data$W
    matrice1 <- solve(diag(rep(1, pp))-ll0)
    vettore1 <- eigen(matrice1)$values
  }
  else matrice1 <- diag(vettore1)
  if("lambda1"%in%dimnames(res.fit$coeff.hat)[[2]])
    ll1 <- diag(coeff.hat[,"lambda1"])
  if("lambda2"%in%dimnames(res.fit$coeff.hat)[[2]])
    ll2 <- diag(coeff.hat[,"lambda2"])%*%res.fit$data$W
  matrice2 <- ll1+ll2
  vettore2 <- eigen(matrice2)$values
  
  eigenA <- eigen(matrice1%*%matrice2)$values
  diagnostics <- cbind(vettore1, vettore2, Mod(eigenA))

  ## correzione dei coefficienti stimati, per migliorare la stazionarietà del processo stimato
  indici.correzione <- Mod(eigenA)>1
  if(sum(indici.correzione)>0){
    if("lambda1"%in%dimnames(res.fit$coeff.hat)[[2]]){
      indici.correzione <- res.fit$coeff.hat[,"lambda1"]>1
      if(sum(indici.correzione)>0){
        coeff.hat[indici.correzione,"lambda1"] <- 0
        ll1 <- diag(coeff.hat[,"lambda1"])
        if("lambda2"%in%dimnames(res.fit$coeff.hat)[[2]]){
          coeff.hat[indici.correzione,"lambda2"] <- 0
          ll2 <- diag(coeff.hat[,"lambda2"])%*%res.fit$data$W
        }
        matrice2 <- ll1+ll2
      }
      # else{
      #   indici.correzione <- sort(res.fit$coeff.hat[,"lambda0"], decreasing=TRUE, index.return=TRUE)$ix[1:sum( Mod(eigenA)>1)]
      #   indici.ordinamento <- rep(FALSE, pp); indici.ordinamento[indici.correzione] <- TRUE
      #   coeff.hat[indici.ordinamento,"lambda0"] <- 0
      #   matrice1 <- solve(diag(rep(1, pp))-diag(coeff.hat[,"lambda0"])%*%res.fit$data$W)
      # }
    }
    # else if("lambda0"%in%dimnames(res.fit$coeff.hat)[[2]]){
    #   indici.correzione <- sort(res.fit$coeff.hat[,"lambda0"], decreasing=TRUE, inder.return=TRUE)$ix[1:sum( Mod(eigenA)>1)]
    #   indici.ordinamento <- rep(FALSE, pp); indici.ordinamento[indici.correzione] <- TRUE
    #   coeff.hat[indici.ordinamento,"lambda0"] <- 0
    #   matrice1 <- solve(diag(rep(1, pp))-diag(coeff.hat[,"lambda0"])%*%res.fit$data$W)
    # }
    # indici.correzione <- rep(FALSE, pp)
    # indici.correzione[indici.ordinamento] <- TRUE
    if("fixed_effects"%in%dimnames(res.fit$coeff.hat)[[2]]){
      B <- diag(rep(1, pp))-ll0-ll1-ll2
      coeff.hat[,"fixed_effects"] <- B%*%mu
    }
  }
  eigenA <- eigen(matrice1%*%matrice2)$values
  
  ## restituzione risultati
  if(!correzione)
    coeff.hat <- res.fit$coeff.hat
  diagnostics <- cbind(indici.correzione, diagnostics, Mod(eigenA))
  dimnames(diagnostics)[[1]] <- dimnames(coeff.hat)[[1]]
  dimnames(diagnostics)[[2]] <- c("correction", "eigen1", "eigen2", "Mod.eigenA.pre", "Mod.eigenA.post")
  list(pp=pp, nn=nn, kk=kk, coeff.hat=coeff.hat, diagnostics=data.frame(diagnostics))
}


test.sdpd.model <- function (res.fit, model=NULL, correzione=FALSE, H0=c("zero", "constant", "grouped", "nospatial", "noautoregressive", "noX", "constrained")[1],
                             method=c("k-FDR", "percentile", "normal basic")[1],
                             group.index=rep(1, dim(res.fit$fitted)[1]), opts.plot=list(boot.plot=TRUE, ylimiti=NULL, label.index=NULL), 
                             n.boot=299, coeff.true=0) 
{
	## H0=("constant", "grouped", ....) denotes the kind of hypothesis tested under the null.
  if(is.null(model))
    model <- res.fit$model
  beta.names <- names(model$beta.coeffs)[model$beta.coeffs]

  data <- check.sdpd.model(res.fit, correzione=correzione)
  error	<- warning <- character(20)
  n.error	<- n.warning <- 0

  ### sample distribution approximation based on residual bootstrap
  if(n.boot>20){
    indici.tx <- apply(res.fit$resid, 2, FUN=function(x){sum(is.na(x))})
    resid <- res.fit$resid[,indici.tx==0]
    i.resid	<- seq(1,dim(resid)[2])
    boot.ind 	<- matrix(sample(i.resid, size=(data$nn)*n.boot, replace = TRUE), nrow=n.boot)
    boot.rep	<- array(0, dim=c(n.boot, data$pp, dim(res.fit$coeff.hat)[2]))	
	  devs.tsboot <- matrix(0, nrow=n.boot, ncol=data$pp)
    mu <- apply(res.fit$data$series, 1, mean)
    ## bootstrap iterations...
    for(bb in 1:n.boot){
      resid.boot <- resid[,boot.ind[bb,]]
      resid.boot[,1] <- mu
	    yy.star1 <- fit.sdpd.series(dseries=resid.boot, W=res.fit$data$W, X.centr=res.fit$data$X, model=model, lambda.hat=data$coeff.hat, resid=TRUE)$series
      COVs <- fit.sdpd.covs(series=yy.star1, X=res.fit$data$X, px.neighbors=res.fit$data$intorno, kk=data$kk, nn=data$nn, pp=data$pp)
      boot.rep[bb,,] <- fit.sdpd.coefficients(W=res.fit$data$W, COVs=COVs, mu=mu, model=model)$coeff.hat
      devs.tsboot[bb,] <- apply(yy.star1-res.fit$data$series, 1, sd)
      if(bb%%300==0 & opts.plot$boot.plot){
        if(is.null(opts.plot$ylimiti))
          opts.plot$ylimiti <- range(res.fit$data$series)
        cat("\n boot iterations:", bb-300+1, "-", bb, "...one of the bootstrapped time series is plotted for control")
        jji <- sample((1:data$pp)[group.index==1], size=1)
        titolo <- "True series (red) vs bootstrap series (black=full or green=partial)"
        titoloB <- NULL
        if(data$kk>=1){
          titolo <- paste(titolo, ", demeaned X1 series (blue)", sep="")
          titoloB <- paste(", beta1=", round(res.fit$coeff.hat[jji,beta.names[1]], digits=3), sep="")
        }
        titolo <- paste(titolo, " and cc (fixed line)", sep="")
        titolo <- paste(titolo, " - location=", dimnames(res.fit$data$series)[[1]][jji], sep="")
        if(!is.null(opts.plot$label.index))
          titolo <- paste(titolo, " - group=", opts.plot$label.index[jji], sep="")
        
        titolo <- paste(titolo, "\n core.points=", sum(abs(res.fit$data$W[jji,])>0), ", n.points=", sum(res.fit$data$intorno$index[jji,]>0, na.rm=T), sep="")
        titolo <- paste(titolo, "  (", sep="")
        if("lambda0"%in%dimnames(res.fit$coeff.hat)[[2]])
          titolo <- paste(titolo, "lambda0=", round(data$coeff.hat[jji,"lambda0"], digits=2), sep="")
        if("lambda1"%in%dimnames(res.fit$coeff.hat)[[2]])
          titolo <- paste(titolo, ", lambda1=", round(data$coeff.hat[jji,"lambda1"], digits=2), sep="")
        if("lambda2"%in%dimnames(res.fit$coeff.hat)[[2]])
          titolo <- paste(titolo, ", lambda2=", round(data$coeff.hat[jji,"lambda2"], digits=2), sep="")
        titolo <- paste(titolo, titoloB, ") eigen=", round(data$diagnostics$Mod.eigenA.pre[1], digits=3), " eigen.post=", round(data$diagnostics$Mod.eigenA.post[1], digits=3), sep="")
        if("lambda1"%in%dimnames(res.fit$coeff.hat)[[2]])
          titolo <- paste(titolo, ", #{|lambda1|>1}=", sum(ifelse(abs(res.fit$coeff.hat[,"lambda1"])>1, 1, 0)), sep="")
        ts.plot(yy.star1[jji,], main=titolo, col=group.index[jji], ylim=opts.plot$ylimiti, ylab="temperatures")
        lines(seq(1,data$nn), res.fit$data$series[jji,], col="red")
        abline(h=res.fit$coeff.hat[jji,"fixed_effects"])
        if(data$kk==1)
          lines(seq(1,data$nn), res.fit$data$X[jji,], col="blue", lty=2)
        else if(data$kk>1)
          lines(seq(1,data$nn), res.fit$data$X[beta.names[1],jji,], col="blue", lty=2)
      }
	  }
  
    results <- lambda.cons <- array(0, dim=c(data$pp, dim(res.fit$coeff.hat)[2]))
  	dimnames(results)[[1]] <- dimnames(lambda.cons)[[1]] <- dimnames(boot.rep)[[2]] <- dimnames(devs.tsboot)[[2]] <- dimnames(res.fit$coeff.hat)[[1]]
  	dimnames(results)[[2]] <- dimnames(lambda.cons)[[2]] <- dimnames(boot.rep)[[3]] <- dimnames(res.fit$coeff.hat)[[2]]

  	### definizione delle statistiche per le varie tipologie di ipotesi del test...

		if(H0=="zero"|H0==1){
			boot.cons <- boot.rep
			boot.cons[,,] <- 0
			lambda.cons[,] <- coeff.true
  	}
	  else if(H0=="constant"|H0==2){
			boot.cons <- apply(boot.rep, c(1,3), FUN=function(x){rep(mean(x), length(x))})
			boot.cons <- apply(boot.cons, c(1,3), FUN=function(x){x})
			lambda.cons[,] <- apply(res.fit$coeff.hat, 2, FUN=function(x){rep(mean(x), length(x))})
		}
		else if(H0=="grouped"|H0==3){
			fun.group <- function(x, index){
			  x.cons <- x
			  for(jj in 1:max(index))
				  x.cons[index==jj] <- rep(mean(x[index==jj], sum(index==jj)))
			  x.cons
			}
			boot.cons <- apply(boot.rep, c(1,3), FUN=fun.group, index=group.index)
			boot.cons <- apply(boot.cons, c(1,3), FUN=function(x){x})
			lambda.cons[,] <- apply(res.fit$coeff.hat, 2, FUN=fun.group, index=group.index)
  	}
		else if(H0=="nospatial"|H0==4){
			boot.cons <- boot.rep
			boot.cons[,,c("lambda0", "lambda2")] <- 0
			lambda.cons[,] <- res.fit$coeff.hat; lambda.cons[,c("lambda0", "lambda2")] <- 0
		}
		else if(H0=="noautoregressive"|H0==5){
			boot.cons <- boot.rep
			boot.cons[,,"lambda1"] <- 0
			lambda.cons[,] <- res.fit$coeff.hat; lambda.cons[,"lambda1"] <- 0
		}
		else if(H0=="noX"|H0==6){
			boot.cons <- boot.rep
			boot.cons[,,beta.names] <- 0
			lambda.cons[,] <- res.fit$coeff.hat; lambda.cons[,beta.names] <- 0
		}
  	else if(H0=="constrain"|H0==7){
  	  boot.cons <- boot.rep
  	  boot.cons[,,"lambda1"] <- -1*boot.rep[,,"lambda2"]
  	  boot.cons[,,"lambda2"] <- -1*boot.rep[,,"lambda1"]
  	  lambda.cons[,] <- 0
  	}
  	else{
			n.error <- n.error + 1
			error[n.error] <- paste("The null hypothesis", H0, "is not available...")
		}
		### summary of bootstrap distribution
		statistica 	<- res.fit$coeff.hat - lambda.cons
		boot.rep		<- boot.rep-boot.cons
    fun.BOOT <- function(x){
      # statistiche di sintesi del vettore di repliche bootstrap x
      nNAx <- sum(is.na(x))
      sdx <- sd(x, na.rm=T)
      mx <- mean(x, na.rm=T)
      if(nNAx==0)
        pvalue <- 0 # shapiro.test(x)$p.value
      else
        pvalue <- NA
      c(mx, sdx, pvalue, nNAx)
    }
    fun.BOOT3 <- function(x){
      if(!is.na(mean(x, na.rm=T))){
        if(mean(x, na.rm=T)>0)
          res <- ifelse(x<0, 1, 0)
        else
          res <- ifelse(x>0, 1, 0)
      }
      else res <- rep(NA, length(x))
      res
    }
    boot <- apply(boot.rep, c(2,3), fun.BOOT)
    devs.tsboot <- apply(devs.tsboot, 2, fun.BOOT)
    dist <- apply(boot.rep, c(2,3), FUN=function(x){x-mean(x, na.rm=T)})
    for(ii in 1:n.boot){
      dist[ii,,] <- dist[ii,,]+statistica
    }
    dist <- apply(dist, c(2,3), fun.BOOT3)
    pvalue <- apply(dist, c(2,3), mean)
    dimnames(boot)[[1]] <- dimnames(devs.tsboot)[[1]] <- c("bias.boot", "sd.boot", "pvSWnormaltest.boot", "NAs.boot")
    dimnames(pvalue)[[1]] <- dimnames(boot)[[2]]
    dimnames(pvalue)[[2]] <- dimnames(boot)[[3]]
    boot["bias.boot",,] <- boot["bias.boot",,] - res.fit$coeff.hat
  }
  else return(error="n. repliche bootstrap insufficienti")
  
	#### restituzione risultati
	list(pvalue=pvalue, diagnostics=data$diagnostics, coeff.H0=lambda.cons, H0=H0, method=method, coeff.hat=res.fit$coeff.hat, coeff.boot=boot, sdevs.tsboot=devs.tsboot, alpha=alpha, n.boot=n.boot, errors=error[error!=""])
}

