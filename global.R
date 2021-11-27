#Paquetes

library(dplyr)
library(sf)
library(DT)
library(plotly)
library(leaflet)
library(leaflet.extras)
library(shiny)
library(shinydashboard)


# Lectura de conjuntos de datos

# Taxones indicadores
taxones_indicadores <-
  read.csv(
    "https://raw.githubusercontent.com/biomonitoreo-participativo/datos/master/indicadores/taxones/taxones-indicadores.csv"
  )


# Opciones para listas de selección

# Taxones indicadores
opciones_taxones_indicadores <- unique(taxones_indicadores$taxon)
opciones_taxones_indicadores <- sort(opciones_taxones_indicadores)
opciones_taxones_indicadores <- c("Todas", opciones_taxones_indicadores)

