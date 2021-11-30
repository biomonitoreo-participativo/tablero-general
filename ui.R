dashboardPage(
    dashboardHeader(title = "Biomonitoreo participativo"),
    dashboardSidebar(sidebarMenu(
        menuItem(
            text = "Filtros de datos",
            selectInput(
                inputId = "selector_areas_conservacion",
                label = "Área de conservación",
                choices = opciones_areas_conservacion,
                selected = "ACLAP"
            ),
            selectInput(
                inputId = "selector_grupos_nomenclaturales",
                label = "Grupo de especies",
                choices = opciones_grupos_nomenclaturales
            ),
            selectInput(
                inputId = "selector_especies_indicadoras",
                label = "Especie indicadora",
                choices = opciones_especies_indicadoras
            ),
            selectInput(
                inputId = "selector_corredores_biologicos",
                label = "Corredor biológico",
                choices = opciones_corredores_biologicos
            ),
            selectInput(
                inputId = "selector_fuentes_datos",
                label = "Fuente de datos",
                choices = opciones_fuentes_datos
            ),
            startExpanded = TRUE,
            menuSubItem(text = "Resumen", tabName = "tab_resumen"),
            menuSubItem(text = "Mapa registros presencia", tabName = "tab_mapa_registros_presencia"),
            menuSubItem(text = "Tabla registros presencia", tabName = "tab_tabla_registros_presencia"),
            menuSubItem(text = "Gráficos registros presencia", tabName = "tab_graficos_registros_presencia"),
            menuSubItem(text = "Gráficos cámaras trampa", tabName = "tab_graficos_camaras_trampa_horas")
        )
    )),
    dashboardBody(
        tags$head(
            tags$script(
                '
              // Este bloque de código JavaScript permite ampliar el largo de un box de shinydashboard.
              // Está basado en:
              // https://stackoverflow.com/questions/56965843/height-of-the-box-in-r-shiny
              // Define function to set height of "map" and "map_container"
              setHeight = function() {
                var window_height = $(window).height();
                var header_height = $(".main-header").height();
                var boxHeight = window_height - header_height - 30;
                $("#box_graficos_camaras_trampa_horas").height(boxHeight - 20);
                $("#box_graficos_camaras_trampa_horas").height(boxHeight - 20);
                // $("#box_graficos_camaras_trampa_horas").height(boxHeight - 20);
                $("#box_graficos_camaras_trampa_horas").height(boxHeight - 40);
                $("#box_graficos_camaras_trampa_horas").height(boxHeight - 40);
              };
              // Set input$box_height when the connection is established
              $(document).on("shiny:connected", function(event) {
                setHeight();
              });
              // Refresh the box height on every window resize event
              $(window).on("resize", function(){
                setHeight();
              });
            '
            )
        ),        
        tabItems(
        tabItem(tabName = "tab_resumen",
                fluidRow(
                    column(
                        width = 6,
                        box(
                            title = "Registros de presencia de especies indicadoras",
                            leafletOutput(outputId = "mapa_registros_presencia_resumen", height = 475),
                            width = NULL
                        )
                    ),
                    column(
                        width = 6,
                        box(
                            title = "Registros de presencia de especies indicadoras",
                            DTOutput(outputId = "tabla_registros_presencia_resumen", height = 475),
                            width = NULL
                        )
                    )
                ), fluidRow(column(
                    width = 12,
                    box(
                        title = "Cantidad de especies indicadoras en corredores biológicos",
                        plotlyOutput(outputId = "grafico_corredores_biologicos_especies_resumen", height = 200),
                        width = NULL
                    )
                ))),
        tabItem(tabName = "tab_mapa_registros_presencia",
                fluidRow(column(
                    width = 12,
                    box(
                        title = "Registros de presencia de especies indicadoras",
                        leafletOutput(outputId = "mapa_registros_presencia", height = 700),
                        width = NULL
                    )
                ))),
        tabItem(tabName = "tab_tabla_registros_presencia",
                fluidRow(column(
                    width = 12,
                    box(
                        title = "Registros de presencia de especies indicadoras",
                        DTOutput(outputId = "tabla_registros_presencia"),
                        width = NULL
                    )
                ))),
        tabItem(
            tabName = "tab_graficos_registros_presencia",
            fluidRow(column(
                width = 12,
                box(
                    title = "Cantidad de especies indicadoras en corredores biológicos",
                    plotlyOutput(outputId = "grafico_corredores_biologicos_especies", height = 200),
                    width = NULL
                )
            )),
            fluidRow(column(
                width = 12,
                box(
                    title = "Estacionalidad (registros de presencia)",
                    plotlyOutput(outputId = "grafico_estacionalidad_registros", height = 200),
                    width = NULL
                )
            )),
            fluidRow(column(
                width = 12,
                box(
                    title = "Estacionalidad (especies)",
                    plotlyOutput(outputId = "grafico_estacionalidad_especies", height = 200),
                    width = NULL
                )
            ))
        ),
        tabItem(tabName = "tab_graficos_camaras_trampa_horas",
                fluidRow(
                    box(
                        id = "box_graficos_camaras_trampa_horas",
                        title = "Distribución de los registros de cámaras en las horas del día",
                        plotOutput(outputId = "graficos_camaras_trampa_horas"),
                        width = 12
                    )
                ))
    ))
)