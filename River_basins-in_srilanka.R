libs <- c(
  "tidyverse", "sf",
  "giscoR", "magick"
)

installed_libraries <- libs %in% rownames(
  installed.packages()
)

if (any(installed_libraries == FALSE)) {
  install.packages(
    libs[!installed_libraries]
  )
}

invisible(
  lapply(
    libs, library,
    character.only = TRUE
  )
)
# 1. GET COUNTRY BORDERS
#-----------------------
print("GET COUNTRY BORDERS")

get_country_borders <- function() {
  country_borders <- giscoR::gisco_get_countries(
    resolution = "3",
    country = "Sri Lanka"  # or use ISO3 code: "LKA"
  )
  return(country_borders)
}

country_borders <- get_country_borders()

# 2. GET BASINS
#---------------
print("GET BASINS")
# https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_as_lev03_v1c.zip

get_basins <- function() {
  url <- "https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_as_lev03_v1c.zip"
  file_name <- "hybas_as_lev03_v1c.zip"
  
  download.file(
    url = url,
    destfile = file_name,
    mode = "wb"
  )
  
  unzip(file_name)
}

get_basins()
print("basin downloaded")

list.files()

print("load basin")
load_basins <- function() {
  print("loading filenames")
  filenames <- list.files(
    pattern = ".shp$",
    full.names = TRUE
  )
  print(filenames)
  asia_basin <- sf::st_read(
    filenames
  )
  
  return(asia_basin)
}

asia_basin <- load_basins()
print("basin loaded")

# Reproject to a suitable projected CRS
asia_basin_proj <- sf::st_transform(asia_basin, 32644)
country_borders_proj <- sf::st_transform(country_borders, 32644)

print("Intersect Basin with only the wanted Country Boundary.")
sf::sf_use_s2(FALSE)  # Disable s2 if you want (optional)

srilanka_basin <- asia_basin_proj |>
  sf::st_intersection(
    country_borders_proj
  ) |>
  dplyr::select(
    HYBAS_ID
  )


# 3. GET RIVERS DATA
#-------------------
get_rivers <- function() {
  url <- "https://data.hydrosheds.org/file/HydroRIVERS/HydroRIVERS_v10_as.gdb.zip"
  file_name <- "asia-rivers.zip"
  
  options(timeout = 300)  # increase timeout to 5 minutes
  
  download.file(url = url, destfile = file_name, mode = "wb")
  unzip(file_name)
  
  # After unzip, folder HydroRIVERS_v10_as.gdb should exist
}

get_rivers()
print("Getting Rivers")

# List layers inside the gdb folder
layers <- sf::st_layers("HydroRIVERS_v10_as.gdb")
print(layers)

# Choose appropriate layer (usually rivers layer)
# For example, read the first layer
asia_rivers <- sf::st_read("HydroRIVERS_v10_as.gdb", layer = layers$name[1])

print("Rivers loaded")

srilanka_rivers <- asia_rivers |>
  sf::st_intersection(country_borders) |>
  dplyr::select(ORD_FLOW)


# 4. DETERMINE BASIN FOR EVERY RIVER
#-----------------------------------

# Match CRS
srilanka_rivers_proj <- sf::st_transform(srilanka_rivers, 32644)
srilanka_basin_proj <- sf::st_transform(srilanka_basin, 32644)

# Intersection
srilanka_river_basin <- sf::st_intersection(
  srilanka_rivers_proj,
  srilanka_basin_proj
)


# 5. RIVER WIDTH
#---------------

unique(srilanka_river_basin$ORD_FLOW)

srilanka_river_basin_width <- srilanka_river_basin |>
  dplyr::mutate(
    width = dplyr::case_when(
      ORD_FLOW == 1 ~ 0.8,
      ORD_FLOW == 2 ~ 0.7,
      ORD_FLOW == 3 ~ 0.6,
      ORD_FLOW == 4 ~ 0.45,
      ORD_FLOW == 5 ~ 0.35,
      ORD_FLOW == 6 ~ 0.25,
      ORD_FLOW == 7 ~ 0.2,
      ORD_FLOW == 8 ~ 0.15,
      ORD_FLOW == 9 ~ 0.1,
      TRUE ~ 0
    )
  ) |>
  sf::st_as_sf()

# 6. PLOT
#--------

unique(
  srilanka_river_basin_width$HYBAS_ID
)

install.packages("ggspatial")
library(ggspatial)
library(ggplot2)

p <- ggplot() +
  geom_sf(
    data = srilanka_river_basin_width,
    aes(
      color = factor(ORD_FLOW),  # <— map color straight from ORD_FLOW
      size = width,
      alpha = width
    )
  ) +
  scale_color_manual(
    name = "River Basin",
    values = hcl.colors(
      n = length(unique(srilanka_river_basin_width$ORD_FLOW)),
      palette = "Zissou 1",
      rev = TRUE
    )
  ) +
  scale_size(
    name = "River Width",
    range = c(.2, 1)
  ) +
  scale_alpha(
    name = "Opacity",
    range = c(.4, 1)
  ) +
  theme_void() +
  theme(
    # Move legend to bottom‐right inside the panel
    legend.position     = "none",
    plot.title = element_text(
      size = 16,
      face = "bold",
      color = "white",
      hjust = 0.5,
      margin = margin(t = 20, b = 10)
    ),
    plot.caption = element_text(
      size = 10,
      color = "white",
      hjust = 0.5,
      vjust = 1,
      margin = margin(t = 10, b = 20)
    ),
    plot.margin = unit(c(0, 0, 0, 0), "lines"),
    plot.background = element_rect(
      fill = "black",
      color = NA
    ),
    panel.background = element_rect(
      fill = "black",
      color = NA
    )
  ) +
  labs(
    title = "River Basins of Sri Lanka",
    caption = "Prepared by Lavanya Baskaran - Source: ©World Wildlife Fund, Inc. (2006-2013) HydroSHEDS database http://www.hydrosheds.org",
    x = NULL, y = NULL
  )

print(p)

ggsave("srilanka_river_basins.png", plot = p, width = 10, height = 8, dpi = 300)
getwd()


