
bool_update <- FALSE
bool_dynamic <- TRUE

## build the list and objects with technical settings for estimations
vec.options <-list(px.core=1, px.neighbors=3, t_frequency=12, na.rm=T, groups=1, NAcovs="pairwise.complete.obs")
NBOOT <- 999
CORREZIONE <- TRUE
size.point <- 0.5
pars_alpha <- 0.1

pars_list <- list()
captions_list <- list()
objects_to_save <- NULL

  
  ## Each component of the list is associated to a variable
  ## Each component of the list contains:
  ## - a list with the colors set for the palettes of the maps.
  ## - a list with a "fixed" range for the variable, to help comparisons between different plots.
  ## - a list with a unit of measure for each variable, to label the color legend.
  ## - other components can be added, if necessary....
  
pars_list$maximum_air_temperature_adjusted <- list(
    colori=c("blue","red"),
    limiti=NULL,
    unit="K"
)
pars_list$mean_air_temperature_adjusted <- list(
    colori=c("blue", "red"),
    limiti=NULL,
    unit="K"
)
pars_list$minimum_air_temperature_adjusted <- list(
    colori=c("blue", "red"),
    limiti=NULL,
    unit="K"
)
pars_list$mean_relative_humidity_adjusted <- list(
    colori=c("white","darkblue"),
    limiti=NULL,
    unit="value"
)
pars_list$accumulated_precipitation_adjusted <- list(
    colori=c("white","darkblue"),
    limiti=NULL,
    unit="value"
)
pars_list$mean_wind_speed_adjusted <- list(
    colori=c("white", "beige", "darkgreen"),
    limiti=NULL,
    unit="value"
)
pars_list$black_sky_albedo_all_mean <- list(
    colori=c("black", "green","yellow", "white"),
    limiti=c(0,100),
    unit="value"
)
pars_list$LST_h18 <- list(
    colori=c("blue", "red"),
    limiti=NULL,
    unit="K"
)





