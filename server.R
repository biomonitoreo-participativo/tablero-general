shinyServer(function(input, output, session) {
    # filtrarAreasConservacion <- reactive({
    #     areas_conservacion_filtradas <-
    #         areas_conservacion
    #     
    #     # Filtrado por área de conservación
    #     if (input$selector_areas_conservacion != "Todas") {
    #         areas_conservacion_filtradas <-
    #             areas_conservacion_filtradas %>%
    #             filter(siglas_ac == input$selector_areas_conservacion)            
    #     }        
    #     
    #     return (areas_conservacion_filtradas)
    # })
    
    
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
                    filter(
                        registros_presencia,
                        grupos_nomenclaturales == input$selector_grupos_nomenclaturales
                    )
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
            
            areas_conservacion <-
                areas_conservacion %>%
                filter(siglas_ac == input$selector_areas_conservacion)            
        }
        
        # Filtrado por corredor biológico
        if (input$selector_corredores_biologicos != "Todos") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(corredor_biologico == input$selector_corredores_biologicos)
        }
        
        # Filtrado por fuente de datos
        if (input$selector_fuentes_datos != "Todas") {
            registros_presencia_filtrados <-
                registros_presencia_filtrados %>%
                filter(fuente_datos == input$selector_fuentes_datos)
        }        
        
        return(registros_presencia_filtrados)
    })
    
    # Función para filtrar corredores biológicos con base en los controles de entrada
    filtrarCorredoresBiologicos <- reactive({
        registros_presencia_filtrados <- filtrarRegistrosPresencia()
        corredores_biologicos_filtrados <- corredores_biologicos
        
        # Filtrado por grupo nomenclatural
        if (input$selector_grupos_nomenclaturales != "Todos" |
            input$selector_especies_indicadoras != "Todas" |
            input$selector_corredores_biologicos != "Todos" |
            input$selector_fuentes_datos != "Todas") {
            # Cantidad de especies en corredores biológicos
            corredores_biologicos_especies <-
                corredores_biologicos %>%
                st_join(registros_presencia_filtrados) %>%
                group_by(corredor_biologico) %>%
                summarize(cantidad_especies = n_distinct(scientificName, na.rm = TRUE)) %>%
                drop_na(corredor_biologico)
            # Agregar columna con cantidad de especies a la capa de corredores biológicos
            corredores_biologicos_filtrados <-
                corredores_biologicos_filtrados %>%
                inner_join(
                    select(
                        corredores_biologicos_especies,
                        corredor_biologico,
                        cantidad_especies
                    ),
                    by = c("nombre_cb" = "corredor_biologico")
                ) %>%
                rename(cantidad_especies = cantidad_especies.y)
        }
        
        return(corredores_biologicos_filtrados)
    })
    
    output$mapa_registros_presencia_resumen <- renderLeaflet({
        # areas_conservacion_filtradas <- filtrarAreasConservacion()
        registros_presencia_filtrados <- filtrarRegistrosPresencia()
        corredores_biologicos_filtrados <-
            filtrarCorredoresBiologicos()
        
        pal_corredores_biologicos_especies <-
            colorNumeric(palette = "YlGnBu",
                         domain = corredores_biologicos_filtrados$cantidad_especies)
        
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
                weight = 4.0,
                fillOpacity = 0.0,
                popup = paste0(
                    "<strong>Área de conservación: </strong>",
                    areas_conservacion$nombre_ac
                )
            ) %>%
            addPolygons(
                data = corredores_biologicos_filtrados,
                group = "Corredores biológicos",
                color = "green",
                stroke = TRUE,
                fillColor = ~ pal_corredores_biologicos_especies(cantidad_especies),
                weight = 2.0,
                fillOpacity = 0.8,
                popup = paste0(
                    "<strong>Corredor biológico: </strong>",
                    corredores_biologicos_filtrados$nombre_cb,
                    "<br>",
                    "<strong>Cantidad de especies: </strong>",
                    corredores_biologicos_filtrados$cantidad_especies
                )
            ) %>%
            addLegend(
                position = "bottomright",
                pal = pal_corredores_biologicos_especies,
                values = corredores_biologicos_filtrados$cantidad_especies,
                labFormat = labelFormat(digits = 0),
                group = "Corredores biológicos",
                title = "Cantidad de especies"
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
                    "<strong>Fecha: </strong>",
                    registros_presencia_filtrados$eventDate,
                    "<br>",
                    "<strong>Área de conservación: </strong>",
                    registros_presencia_filtrados$area_conservacion,
                    "<br>",
                    "<strong>Corredor biológico: </strong>",
                    registros_presencia_filtrados$corredor_biologico,
                    "<br>",
                    "<strong>Fuente de los datos: </strong>",
                    registros_presencia_filtrados$fuente
                )
            ) %>%
            addLayersControl(
                baseGroups = c(
                    "OpenStreetMap",
                    "Stamen Toner Lite",
                    "CartoDB Dark Matter",
                    "Imágenes de ESRI"
                ),
                overlayGroups = c(
                    "Áreas de conservación",
                    "Corredores biológicos",
                    "Registros de presencia"
                )
            ) %>%
            addScaleBar(position = "bottomleft",
                        options = scaleBarOptions(imperial = FALSE)) %>%
            addMouseCoordinates() %>%
            addSearchOSM() %>%
            addResetMapButton()
    })
    
    output$tabla_registros_presencia_resumen <- renderDT({
        registros_presencia_filtrados <- filtrarRegistrosPresencia()
        
        registros_presencia_filtrados %>%
            st_drop_geometry() %>%
            select(scientificName,
                   locality,
                   eventDate,
                   corredor_biologico,
                   area_conservacion,
                   fuente) %>%
            datatable(
                rownames = FALSE,
                colnames = c("Especie", "Localidad", "Fecha", "CB", "AC", "Fuente"),
                extensions = c("Buttons"),
                options = list(
                    pageLength = 5,
                    searchHighlight = TRUE,
                    lengthMenu = list(
                        c(5, 10, 15, 25, 50, 100,-1),
                        c(5, 10, 15, 25, 50, 100, "Todos")
                    ),
                    dom = 'Bfrtlip',
                    language = list(url = "//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json"),
                    buttons = list(
                        list(extend = 'copy', text = 'Copiar'),
                        list(extend = 'csv', text = 'CSV'),
                        list(extend = 'csv', text = 'Excel'),
                        list(extend = 'pdf', text = 'PDF')
                    )
                )
            )
    })
    
    output$grafico_corredores_biologicos_especies_resumen <- renderPlotly({
        corredores_biologicos_filtrados <- filtrarCorredoresBiologicos()
        
        corredores_biologicos_filtrados %>%
            st_drop_geometry() %>%
            filter(cantidad_especies >= 1) %>%
            top_n(n = 20, wt = cantidad_especies) %>%
            mutate(nombre_cb = factor(nombre_cb, levels = unique(nombre_cb)[order(cantidad_especies, decreasing = TRUE)])) %>%
            arrange(desc(cantidad_especies)) %>%
            plot_ly(
                x = ~ nombre_cb,
                y = ~ cantidad_especies,
                type = "bar",
                name = "Proyectos",
                text = ~ cantidad_especies,
                textposition = 'auto',
                marker = list(color = "#2c7fb8")
            ) %>%
            layout(
                yaxis = list(title = "Cantidad de especies"),
                xaxis = list(title = "Corredor biológico"),
                barmode = 'group',
                hovermode = "compare"
            ) %>%
            config(locale = 'es')        
    })
    
})
