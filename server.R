shinyServer(function(input, output, session) {
    filtrarRegistrosPresencia <- reactive({
        registros_presencia_filtrados <-
            registros_presencia
        
        # Filtrado por grupo nomenclatural
        if (input$selector_grupos_nomenclaturales != "Todos") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(grupos_nomenclaturales == input$selector_grupos_nomenclaturales)
            
            if (input$selector_especies_indicadoras == "Todas") {
                # Lista ordenada de especies del grupo
                especies_grupo <-
                    filter(registros_presencia, grupos_nomenclaturales == input$selector_grupos_nomenclaturales)
                lista_especies_grupo <-
                    unique(especies_grupo$scientificName)
                lista_especies_grupo <- sort(lista_especies_grupo)
                lista_especies_grupo <-
                    c("Todas", lista_especies_grupo)
                
                updateSelectInput(
                    session,
                    "selector_especies_indicadoras",
                    label = "Especies indicadoras",
                    choices = lista_especies_grupo,
                    selected = "Todas"
                )
            }
        }        
        
        # Filtrado por especie
        if (input$selector_especies_indicadoras != "Todas") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(scientificName == input$selector_especies_indicadoras)
        }        

        # Filtrado por área de conservación
        if (input$selector_areas_conservacion != "Todas") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(area_conservacion == input$selector_areas_conservacion)
        }           
                
        # Filtrado por corredor biológico
        if (input$selector_corredores_biologicos != "Todos") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(corredor_biologico == input$selector_corredores_biologicos)
        }               

        return(registros_presencia_filtrados)
    })            
    
    output$mapa_registros_presencia_resumen <- renderLeaflet({
        registros_presencia_filtrados <- filtrarRegistrosPresencia()
        
        # Mapa Leaflet con capas de ...
        leaflet() %>%
            addTiles(group = "OpenStreetMap") %>%
            addProviderTiles(providers$Stamen.TonerLite, group = "Stamen Toner Lite") %>%
            addProviderTiles(providers$CartoDB.DarkMatter, group = "CartoDB Dark Matter") %>%
            addProviderTiles(providers$Esri.WorldImagery, group = "Imágenes de ESRI") %>%
            addPolygons(
                data = areas_conservacion,
                group = "Áreas de conservación",
                color = "brown",
                stroke = TRUE,
                weight = 2.0,
                fillOpacity = 0.0,
                popup = paste0(
                    "<strong>Área de conservación: </strong>",
                    areas_conservacion$nombre_ac
                )
            ) %>%                        
            addPolygons(
                data = corredores_biologicos,
                group = "Corredores biológicos",
                color = "green",
                stroke = TRUE,
                weight = 1.0,
                fillOpacity = 0.0,
                popup = paste0(
                    "<strong>Corredor biológico: </strong>",
                    corredores_biologicos$nombre_cb
                )
            ) %>%            
            addCircleMarkers(
                data = registros_presencia_filtrados,
                group = "Registros de presencia",
                stroke = TRUE,
                radius = 4,
                fillColor = 'red',
                fillOpacity = 1,
                label = paste0(
                    registros_presencia_filtrados$scientificName,
                    ", ",
                    registros_presencia_filtrados$locality,
                    ", ",
                    registros_presencia_filtrados$eventDate
                ),
                popup = paste0(
                    "<strong>Especie: </strong>",
                    registros_presencia_filtrados$scientificName,
                    "<br>",
                    "<strong>Localidad: </strong>",
                    registros_presencia_filtrados$locality,
                    "<br>",
                    "<strong>Fecha y hora: </strong>",
                    registros_presencia_filtrados$eventDate,
                    "<br>",
                    "<strong>Área de conservación: </strong>",
                    registros_presencia_filtrados$area_conservacion,                    
                    "<br>",
                    "<strong>Corredor biológico: </strong>",
                    registros_presencia_filtrados$corredor_biologico
                )
            ) %>%
            addLayersControl(
                baseGroups = c(
                    "OpenStreetMap",
                    "Stamen Toner Lite",
                    "CartoDB Dark Matter",
                    "Imágenes de ESRI"
                ),
                overlayGroups = c("Áreas de conservación", "Corredores biológicos", "Registros de presencia")
            ) %>%
            addScaleBar(position = "bottomleft",
                        options = scaleBarOptions(imperial = FALSE)) %>%
            addMouseCoordinates() %>%
            addSearchOSM() %>%
            addResetMapButton()
    })
    
})
