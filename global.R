# Biomonitoreo participativo
# Tablero de control de datos generales
# Manuel Vargas (mfvargas@gmail.com)


#
#Paquetes
#

library(dplyr)
library(tidyr)
library(lubridate)
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

# Especies indicadoras
especies_indicadoras <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/indicadores/especies-indicadoras.csv"
  )


# Registros de presencia de especies de la app de biomonitoreo
registros_presencia_app <-
  st_read(
    "/vsicurl/https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/observaciones/app-biomonitoreo/occurrences.csv",
    options = c(
      "X_POSSIBLE_NAMES=decimalLongitude",
      "Y_POSSIBLE_NAMES=decimalLatitude"
    )
  )
# Exclusión de especies no indicadoras
registros_presencia_app <-
  registros_presencia_app %>%
  subset(scientificName %in% especies_indicadoras$especie)
# Otras operaciones de curación de datos
registros_presencia_app <-
  registros_presencia_app %>%
  mutate(eventDate = as.Date(as.POSIXct(as.double(eventDate) / 1000, origin =
                                          "1970-01-01"),
                             format = "%Y-%m-%d %H:%M:%OS"))


#
# Integración de los registros de presencia de especies
#

registros_presencia <-
  registros_presencia_app

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


# Listas de selección

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
