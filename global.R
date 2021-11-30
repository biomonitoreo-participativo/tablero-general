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
library(ggplot2)
library(ggthemes)
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
  filter(str_detect(areas_conservacion, "ACLAP"))

# Lectura de la capa de corredores_biologicos
corredores_biologicos <-
  st_read(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/geo/sinac/corredores-biologicos-simplificadas_100m.geojson",
    quiet = TRUE
  ) %>%
  filter(nombre_cb != "Los Santos") # ¡¡OJO: este es un filtro alambrado causando por el traslape entre el CB Los Santos y la RF Los Santos!!
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
# Creación de la columna de hora
registros_presencia_app <-
  registros_presencia_app %>%
  mutate(hora = NA)
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
# Conversión de la columna de fecha
detecciones <-
  detecciones %>%
  mutate(dateTimeCaptured = as_datetime(dateTimeCaptured, format = "%Y:%m:%d %H:%M:%OS"))
# Estaciones en dónde están ubicadas las cámaras
estaciones <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/biomonitoreo-participativo-datos/master/crtms/station.csv"
  )
# Detecciones georreferenciadas
detecciones_georreferenciadas <- inner_join(detecciones, estaciones)
# Eliminar registros sin datos en columnas esenciales
detecciones_georreferenciadas <-
  detecciones_georreferenciadas %>% drop_na(projectID, deploymentLocationID, species, dateTimeCaptured, longitude, latitude)
# Exclusión de especies no indicadoras
detecciones_georreferenciadas <-
  detecciones_georreferenciadas %>%
  subset(species %in% especies_indicadoras$especie)


#
# Agrupación de detecciones con la misma especie y ubicación y un máximo de 30 s de diferencia
#

detecciones_georreferenciadas_ordenadas <-
  detecciones_georreferenciadas %>%
  arrange(projectID, deploymentLocationID, species, dateTimeCaptured)

registros_presencia_camaras <-
  data.frame(
    projectID = character(),
    deploymentLocationID = character(),
    species = character(),
    dateTimeCaptured = character(),
    longitude = double(),
    latitude = double(),
    Organization = double()
  )
projectID_1 <- detecciones_georreferenciadas_ordenadas[1, "projectID"]
deploymentLocationID_1 <- detecciones_georreferenciadas_ordenadas[1, "deploymentLocationID"]
species_1 <- detecciones_georreferenciadas_ordenadas[1, "species"]
dateTimeCaptured_1 <- detecciones_georreferenciadas_ordenadas[1, "dateTimeCaptured"]
registros_presencia_camaras[1,] <-
  c(
    projectID_1,
    deploymentLocationID_1,
    species_1,
    format(dateTimeCaptured_1, "%Y-%m-%d %H:%M:%OS"),
    detecciones_georreferenciadas_ordenadas[1, "longitude"],
    detecciones_georreferenciadas_ordenadas[1, "latitude"],
    detecciones_georreferenciadas_ordenadas[1, "Organization"]
  )

for (row in 2:nrow(detecciones_georreferenciadas_ordenadas)) {
  projectID_2 <- detecciones_georreferenciadas_ordenadas[row, "projectID"]
  deploymentLocationID_2 <- detecciones_georreferenciadas_ordenadas[row, "deploymentLocationID"]
  species_2 <- detecciones_georreferenciadas_ordenadas[row, "species"]
  dateTimeCaptured_2 <- detecciones_georreferenciadas_ordenadas[row, "dateTimeCaptured"]
  
  # cat(row, abs(difftime(dateTimeCaptured_2, dateTimeCaptured_1, units='mins')), "\n")
  if (projectID_2 != projectID_1 |
      deploymentLocationID_2 != deploymentLocationID_1 |
      species_2 != species_1 |
      abs(difftime(dateTimeCaptured_2, dateTimeCaptured_1, units = 'mins') > 30.0)) {
    
    registros_presencia_camaras[nrow(registros_presencia_camaras) + 1,] <-
      c(
        projectID_2,
        deploymentLocationID_2,
        species_2,
        format(dateTimeCaptured_2, "%Y-%m-%d %H:%M:%OS"),
        detecciones_georreferenciadas_ordenadas[row, "longitude"],
        detecciones_georreferenciadas_ordenadas[row, "latitude"],
        detecciones_georreferenciadas_ordenadas[row, "Organization"]
      )
    
    projectID_1 <- projectID_2
    deploymentLocationID_1 <- deploymentLocationID_2
    species_1 <- species_2
    dateTimeCaptured_1 <- dateTimeCaptured_2
  }
}  

registros_presencia_camaras <-
  registros_presencia_camaras %>%
  mutate(dateTimeCaptured = as_datetime(dateTimeCaptured, format = "%Y-%m-%d %H:%M:%OS"))





# Creación de la columna de hora
registros_presencia_camaras <-
  registros_presencia_camaras %>%
  mutate(hora = hour(dateTimeCaptured))
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
      hora,
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
      hora,
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