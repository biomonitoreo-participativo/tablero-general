dashboardPage(
    dashboardHeader(title = "Biomonitoreo participativo"),
    dashboardSidebar(sidebarMenu(
        menuItem(
            text = "Filtros de datos",
            selectInput(
                inputId = "selector_grupos_nomenclaturales",
                label = "Grupos de especies",
                choices = opciones_grupos_nomenclaturales
            ),            
            selectInput(
                inputId = "selector_especies_indicadoras",
                label = "Especies indicadoras",
                choices = opciones_especies_indicadoras
            ),
            startExpanded = TRUE,
            menuSubItem(text = "Resumen", tabName = "tab_resumen")
        )
    )),
    dashboardBody(tabItems(
        tabItem(tabName = "tab_resumen",
                fluidRow(column(
                    width = 6,
                    box(
                        title = "Registros de presencia de especies",
                        leafletOutput(outputId = "mapa_registros_presencia_resumen", height = 500),
                        width = NULL
                    )
                ),))
    ))
)