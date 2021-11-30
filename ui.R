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
            menuSubItem(text = "Gráficos registros presencia", tabName = "tab_graficos_registros_presencia")
        )
    )),
    dashboardBody(tabItems(
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
        tabItem(
            tabName = "tab_mapa_registros_presencia",
            fluidRow(column(
                width = 12,
                box(
                    title = "Registros de presencia de especies indicadoras",
                    leafletOutput(outputId = "mapa_registros_presencia", height = 700),
                    width = NULL
                )
            ))
        ),
        tabItem(
            tabName = "tab_tabla_registros_presencia",
            fluidRow(column(
                width = 12,
                box(
                    title = "Registros de presencia de especies indicadoras",
                    DTOutput(outputId = "tabla_registros_presencia"),
                    width = NULL
                )
            ))
        ),
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
        )
    ))
)