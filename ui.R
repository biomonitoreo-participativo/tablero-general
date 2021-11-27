dashboardPage(
    dashboardHeader(title = "Biomonitoreo participativo"),
    dashboardSidebar(
        text = h3("Filtros de datos"), 
        selectInput(
            inputId = "selector_taxones_indicadores",
            label = "Especie indicadora",
            choices = opciones_taxones_indicadores
        )        
    ),
    dashboardBody()
)