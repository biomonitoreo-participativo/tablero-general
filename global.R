# Biomonitoreo participativo
# Tablero de control de datos generales
# Manuel Vargas (mfvargas@gmail.com)


#
# Paquetes
#

library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(sf)
library(DT)
library(plotly)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(shiny)
library(shinydashboard)


#
# Lectura de conjuntos de datos
#

# Lectura de la capa de áreas de conservación
areas_conservacion <-
  st_read(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/geo/sinac/areas-conservacion-simplificadas_100m.geojson",
    quiet = TRUE
  ) %>%
  filter(siglas_ac == "ACLAP") # ¡¡OJO: este es un filtro alambrado que hay que eliminar cuando se habilite el cambio de AC!!
# Transformación del CRS
areas_conservacion <- 
  areas_conservacion %>%
  st_transform(4326)

# Especies indicadoras
especies_indicadoras <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/indicadores/especies-indicadoras.csv"
  ) %>%
  filter(str_detect(grupos_indicadoras, "ACLAP"))

# Lectura de la capa de corredores_biologicos
corredores_biologicos <-
  st_read(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/geo/sinac/corredores-biologicos-simplificadas_100m.geojson",
    quiet = TRUE
  )
# Transformación del CRS
corredores_biologicos <-
  corredores_biologicos %>%
  st_transform(4326)

# Registros de presencia de especies de la app de biomonitoreo
registros_presencia_app <-
  st_read(
    "/vsicurl/https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/observaciones/app-biomonitoreo/occurrences.csv",
    options = c(
      "X_POSSIBLE_NAMES=decimalLongitude",
      "Y_POSSIBLE_NAMES=decimalLatitude"
    )
  )
# Asignación de CRS
st_crs(registros_presencia_app) = 4326
# Exclusión de especies no indicadoras
registros_presencia_app <-
  registros_presencia_app %>%
  subset(scientificName %in% especies_indicadoras$especie)
# Conversión de la columna de fecha
registros_presencia_app <-
  registros_presencia_app %>%
  mutate(eventDate = as.Date(as.POSIXct(as.double(eventDate) / 1000, origin =
                                          "1970-01-01"),
                             format = "%Y-%m-%d %H:%M:%OS"))
# Adición de columna de fuente de datos
registros_presencia_app <-
  registros_presencia_app %>%
  mutate(fuente = "App de biomonitoreo")


# Registros de presencia de especies de las cámaras trampa
# Detecciones de especies en las cámaras
detecciones <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/biomonitoreo-participativo-datos/master/crtms/detection.csv"
  )
# Estaciones en dónde están ubicadas las cámaras
estaciones <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/biomonitoreo-participativo-datos/master/crtms/station.csv"
  )
# Registros de presencia
registros_presencia_camaras <- inner_join(detecciones, estaciones)
# Eliminar registros sin coordenadas
registros_presencia_camaras <-
  registros_presencia_camaras %>% drop_na(longitude, latitude)
# Exclusión de especies no indicadoras
registros_presencia_camaras <-
  registros_presencia_camaras %>%
  subset(species %in% especies_indicadoras$especie)
# Conversión de la columna de fecha y creación de la columna de hora
registros_presencia_camaras <-
  registros_presencia_camaras %>%
  mutate(dateTimeCaptured = as_datetime(dateTimeCaptured, format = "%Y:%m:%d %H:%M:%OS")) %>%
  mutate(hourCaptured = hour(dateTimeCaptured))
# Adición de columna de fuente de datos
registros_presencia_camaras <-
  registros_presencia_camaras %>%
  mutate(fuente = "Cámaras trampa")
# Conversión a objeto sf
registros_presencia_camaras <-
  registros_presencia_camaras %>% st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)


#
# Integración de los registros de presencia de especies
#

# Integración de registros de la app de biomonitoreo
registros_presencia <-
  rbind(
    select(
      registros_presencia_app,
      scientificName,
      locality,
      eventDate,
      fuente,
      decimalLongitude,
      decimalLatitude,
      geometry
    ),
    select(
      registros_presencia_camaras,
      scientificName = species,
      locality = deploymentLocationID,
      eventDate = dateTimeCaptured,
      fuente,
      decimalLongitude = longitude,
      decimalLatitude = latitude,
      geometry
    )
  )

# Exclusión de registros con coordenadas en 0 (ESTO DEBERÍA HACERSE FILTRANDO LOS PUNTOS QUE NO ESTÁN DENTRO DE COSTA RICA)
registros_presencia <-
  registros_presencia %>%
  filter(!(decimalLongitude == 0 | decimalLatitude == 0))

# Adición de columna de grupos nomenclaturales
registros_presencia <-
  registros_presencia %>%
  left_join(
    select(especies_indicadoras, especie, grupos_nomenclaturales),
    by = c("scientificName" = "especie")
  )

# Adición de columna de área de conservación
registros_presencia <-
  registros_presencia %>%
  st_join(select(areas_conservacion, area_conservacion = siglas_ac))

# Adición de columna de corredor biológico
registros_presencia <-
  registros_presencia %>%
  st_join(select(corredores_biologicos, corredor_biologico = nombre_cb))


#
# Capas para mapas de coropletas
#

# Cantidad de especies en corredores biológicos
corredores_biologicos_especies <-
  corredores_biologicos %>%
  st_join(registros_presencia) %>%
  group_by(corredor_biologico) %>%
  summarize(cantidad_especies = n_distinct(scientificName, na.rm = TRUE)) %>%
  drop_na(corredor_biologico)
# Agregar columna con cantidad de especies a la capa de corredores biológicos
corredores_biologicos <-
  corredores_biologicos %>%
  inner_join(
    select(corredores_biologicos_especies, corredor_biologico, cantidad_especies),
    by = c("nombre_cb" = "corredor_biologico")
  )


#
# Listas de selección
#

# Áreas de conservación
opciones_areas_conservacion <-
  unique(registros_presencia$area_conservacion)
opciones_areas_conservacion <-
  sort(opciones_areas_conservacion)
# ¡¡OJO: falta agregar la opción de "Todas" cuando se habilite el cambio de AC!!

# Grupos nomenclaturales
opciones_grupos_nomenclaturales <-
  unique(especies_indicadoras$grupos_nomenclaturales)
opciones_grupos_nomenclaturales <-
  sort(opciones_grupos_nomenclaturales)
opciones_grupos_nomenclaturales <-
  c("Todos", opciones_grupos_nomenclaturales)

# Especies indicadoras
opciones_especies_indicadoras <-
  unique(especies_indicadoras$especie)
opciones_especies_indicadoras <- sort(opciones_especies_indicadoras)
opciones_especies_indicadoras <-
  c("Todas", opciones_especies_indicadoras)

# Corredores biológicos
opciones_corredores_biologicos <-
  unique(registros_presencia$corredor_biologico)
opciones_corredores_biologicos <-
  sort(opciones_corredores_biologicos)
opciones_corredores_biologicos <-
  c("Todos", opciones_corredores_biologicos)

# Fuente de datos
opciones_fuentes_datos <-
  unique(registros_presencia$fuente)
opciones_fuentes_datos <-
  sort(opciones_fuentes_datos)
opciones_fuentes_datos <-
  c("Todas", opciones_fuentes_datos)