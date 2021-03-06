install.packages('rsconnect')
#rsconnect::setAccountInfo(name='marcosch',
#                          token='446C7F1A6F4DA6465C37098FD8A28EE3',
#                          secret='G9N4Ix7UHtKH5JM/sGjGR78bW0tCLNHb35r0GJ2x')

library(shiny)
library(deSolve)
library(grid)
library(ggplot2)
library(dplyr)
library(tidyr)
SIR <- function(Tiempo, Estados, beta, gamma, delta = 0, mu = 0, Grafica = 0){
  if(length(Tiempo) == 1){                  # El parámetro "Tiempo" puede ser un vector o un sólo número, de ser un 
    Tiempo <- c(0:Tiempo)                   # dígito, se asignará un vector empezando en Tiempo[1] = 0
  }
  
  Condiciones <- c(Susceptibles = Estados[1],
                   Infectados   = Estados[2],
                   Recuperados  = Estados[3],
                   Poblacion    = sum(Estados)
  )
  
  Parametros <- c(B = beta, Y = gamma,
                  D = delta, M = mu
  )
  # Resolución de las ecuaciones diferenciales del modelo, función
  # llamada posteriormente con "ode" de la librería "deSolve"
  
  CalDif <- function(Tiempo, Estados, Parametros) {
    with(as.list(c(Estados, Parametros)), {
      dS <- (-1) * B * Susceptibles * Infectados + D - M * Susceptibles
      dI <-  B * Susceptibles * Infectados - Y * Infectados - M * Infectados
      dR <-  Y * Infectados - M * Recuperados
      Poblacion <- dS + dI + dR
      return(list(c(dS, dI, dR, Poblacion)))
    })
  }
  
  Datos <- ode(y = Condiciones,             # Obtención de resultados de las ecuaciones diferenciales ordinarias resueltas
               times = Tiempo,
               func = CalDif,
               parms = Parametros
  )   
  
  if(!delta){                               # De no ser agregada alguna tasa para dinámica vital, se descarta la
    Datos <- Datos[1:length(Datos[,1]),1:4] # información con respecto al número de población, esta se mantiene constante
  }
  if(Grafica){
    par(2,2)
    plot(Tiempo ,Datos[,2], lwd = 2,
         col = "orange", type = "l",
         main = "Modelo SIR",
         ylab = "Población",
         ylim = c(0, Datos[1,2] + Datos[1,3] + Datos[1,4])
    )
    grid(lty = "dotted")
    lines(Tiempo, Datos[,3], lwd = 2, col = "blue")
    lines(Tiempo, Datos[,4], lwd = 2, col = "black")
    legend(x = 0,y = -sum(Estados)/3, c("Susceptibles","Infectados", "Recuperados"),
           cex = 0.7, fill = c("orange", "blue", "black"), bty = "n", xpd = T
    )
  }
  Data<-data.frame(Datos)
  Data<-gather(Data, "group", "val", 2:5)
  
  if(Grafica){
    print(Data%>%ggplot2::ggplot(aes(x=time,y=val,color=group))+
            geom_smooth(method ="loess",formula = "y~x")+
            labs(title="Modelo SIR",x="Time",y="Size"))
    
  }
  
  return(Data)
  
}
#dat<-SIR(Tiempo=10,Estados=c(100,20,10),  beta=2.5,gamma=1, delta = 1,mu=.01,Grafica = 0)
#dat
#print(ggplot2::ggplot(dat,aes(x=time,y=val,color=group))+
#      geom_smooth(method ="loess",formula = "y~x")+
#      labs(title="Modelos SIR",x="Time",y="Size"))


ui <- fluidPage(
  titlePanel(title=h4("SIR MODEL", align="center")),
  sidebarPanel(
    sliderInput("S", "Susceptible:",min = 0, max = 100, 10),
    sliderInput("I", "Infected:",min = 0, max = 100, 10),
    sliderInput("R", "Recovered:",min = 0, max = 100, 10),
    sliderInput("num", "Time:",min = 2, max = 100, value=5),  
    sliderInput("beta", "beta:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("gamma", "gamma:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("delta", "delta:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("mu", "mu:",min = 0, max =2,value = 1, step = .01,round = FALSE)
  ),
  
  mainPanel(plotOutput("plot2")))

server <- function(input,output){
  dat <- reactive({
    test <- SIR(Tiempo=input$num,Estados=c(input$S,input$I,input$R),  beta=input$beta,gamma=input$gamma, delta =input$delta,mu=input$mu,Grafica = 0)
    print(test)
    test
  })
  
  output$plot2<-renderPlot({
    ggplot2::ggplot(dat(),aes(x=time,y=val,color=group))+
      geom_smooth(method ="loess",formula = "y~x")+
      labs(x="Time",y="Size")
  },height = 400,width = 600)}

shinyApp(ui, server)





SEIR <- function(Tiempo, Estados, beta, gamma, sigma, mu= 0, delta = 0, Grafica = 0){
  
  if(length(Tiempo) == 1){
    Tiempo <- c(0:Tiempo)
  }
  
  Condiciones <- c(Susceptibles = Estados[1],
                   Exposicion   = Estados[2],
                   Infectados   = Estados[3],
                   Recuperados  = Estados[4],
                   Poblacion    = sum(Estados)
  )
  
  Parametros <- c(B = beta, Y = gamma, Q = sigma, M = mu, D = delta)
  
  CalDif <- function(Tiempo, Estados, Parametros) {
    with(as.list(c(Estados, Parametros)), {
      dS <-  D * Poblacion - B * Susceptibles * Infectados - M * Susceptibles
      dE <-  B * Susceptibles * Infectados - Q * Exposicion - M * Exposicion 
      dI <-  Q * Exposicion - Y * Infectados - M * Infectados
      dR <-  Y * Infectados - M * Recuperados
      Poblacion <- dS + dE + dI + dR
      return(list(c(dS ,dE, dI, dR, Poblacion)))
    })
  }
  
  Datos <- ode(y = Condiciones,
               times = Tiempo,
               func = CalDif,
               parms = Parametros
  )
  
  if(!delta){
    Datos <- Datos[1:length(Datos[,1]),1:5]
  }
  
  if(Grafica){
    plot.new()
    plot(Tiempo ,Datos[,2], lwd = 2,
         col = "orange", type = "l",
         main = "Modelo SEIR",
         ylab = "Población",
         ylim = c(0 , Datos[1,2] + Datos[1,3] + Datos[1,4] + Datos[1,5])
    )
    grid(lty = "dotted")
    lines(Tiempo, Datos[,3], lwd = 2, col = "blue")
    lines(Tiempo, Datos[,4], lwd = 2, col = "black")
    lines(Tiempo, Datos[,5], lwd = 2, col = "red")
    legend(x = 0, y = -sum(Estados)/3,
           c("Susceptibles", "Expuestos","Infectados", "Recuperados"),
           cex = 0.65,
           fill = c("orange", "blue", "black", "red"), 
           xpd = TRUE, bty = "n"
    )
  }
  
  Data<-data.frame(Datos)
  Data<-gather(Data, "group", "val", 2:6)
  
  if(Grafica){
    print(Data%>%ggplot2::ggplot(aes(x=time,y=val,color=group))+
            geom_smooth(method ="loess",formula = "y~x")+
            labs(title="Modelo SEIR",x="Time",y="Size"))
    
  }
  
  return(Data)
}


ui <- fluidPage(
  titlePanel(title=h4("SEIR MODEL", align="center")),
  sidebarPanel(
    sliderInput("S", "Susceptible:",min = 0, max = 100, 10),
    sliderInput("E", "Exposed:",min = 0, max = 100, 10),
    sliderInput("I", "Infected:",min = 0, max = 100, 10),
    sliderInput("R", "Recovered:",min = 0, max = 100, 10),
    sliderInput("num", "Time:",min = 2, max = 100, value= 5),  
    sliderInput("beta", "beta:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("gamma", "gamma:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("delta", "delta:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("sigma", "sigma:",min = 0, max =2,value = 1, step = .01,round = FALSE),
    sliderInput("mu", "mu:",min = 0, max =2,value = 1, step = .01,round = FALSE)
  ),
  
  mainPanel(plotOutput("plot2")))

server <- function(input,output){
  dat <- reactive({
    test <- SEIR(Tiempo=input$num,Estados=c(input$S,input$E,input$I,input$R),  beta=input$beta,
                 gamma=input$gamma, delta =input$delta,mu=input$mu,sigma=input$sigma,Grafica = 0)
    print(test)
    test
  })
  
  output$plot2<-renderPlot({
    ggplot2::ggplot(dat(),aes(x=time,y=val,color=group))+
      geom_smooth(method ="loess",formula = "y~x")+
      labs(x="Time",y="Size")
  },height = 400,width = 600)}

shinyApp(ui, server)




SIS <- function(Tiempo, Estados, beta, gamma, Grafica = 0){
  
  if(length(Tiempo) == 1){
    Tiempo <- c(0:Tiempo)
  }
  
  Condiciones <- c(Susceptibles = Estados[1] ,
                   Infectados   = Estados[2]
  )
  
  Parametros <- c(B = beta, Y = gamma)
  
  CalDif <- function(Tiempo, Estados, Parametros) {
    with(as.list(c(Estados, Parametros)), {
      dS <- (-1) * B * Susceptibles * Infectados + Y * Infectados
      dI <-  B * Susceptibles * Infectados - Y * Infectados
      return(list(c(dS, dI)))
    })
  }
  
  Datos <- ode(y = Condiciones,
               times = Tiempo,
               func = CalDif,
               parms = Parametros
  )
  
  if(Grafica){
    plot.new()
    plot(Tiempo ,Datos[,2], lwd = 2,
         col = "orange", type = "l",
         main = "Modelo SIS",
         ylab = "Población",
         ylim = c(0, Datos[1,2] + Datos[1,3])
    )
    grid(lty = "dotted")
    lines(Tiempo, Datos[,3], lwd = 2, col = "blue")
    legend(x = 0, y = -sum(Estados)/3, c("Susceptibles","Infectados"),
           cex = 0.9, fill = c("orange", "blue"),
           xpd = TRUE, bty = "n"
    )
  }
  Data<-data.frame(Datos)
  Data<-gather(Data, "group", "val", 2:3)
  
  if(Grafica){
    print(Data%>%ggplot2::ggplot(aes(x=time,y=val,color=group))+
            geom_smooth(method ="loess",formula = "y~x")+
            labs(title="Modelo SIS",x="Time",y="Size"))
    
  }
  
  return(Data)
}


ui <- fluidPage(
 
  titlePanel(title=h4("SIS MODEL", align="center")),
  sidebarPanel(
    sliderInput("S", "Susceptible:",min = 0, max = 100, value=10),
    sliderInput("I", "Infected:",min = 0, max = 100, value=2),
    sliderInput("time", "Time:",min = 2, max = 100, value= 5),  
    sliderInput("beta", "beta:",min = 0, max =1,value = 0.5, step = .01,round = FALSE),
    sliderInput("gamma", "gamma:",min = 0, max =1,value = 0.5, step = .01,round = FALSE)
  ),
  
  mainPanel(plotOutput("plot2")))

server <- function(input,output){
  dat <- reactive({
    test <- SIS(Tiempo=input$time,Estados=c(input$S,input$I),  beta=input$beta,
                 gamma=input$gamma,Grafica = 0)
    print(test)
    test
  })
  
  output$plot2<-renderPlot({
    ggplot2::ggplot(dat(),aes(x=time,y=val,color=group))+
      geom_smooth(method ="loess",formula = "y~x")+
      labs(x="Time",y="Size")
  },height = 400,width = 600)}

shinyApp(ui, server)

Zombieland <- function(Tiempo, Estados, beta, alfa, dseta, Grafica = 0){
  
  if(length(Tiempo) == 1){
    Tiempo <- c(0:Tiempo)
  }
  
  Condiciones <- c(Susceptibles = Estados[1] ,
                   Zombies      = Estados[2] ,
                   Muertos      = Estados[3]
  )
  
  Parametros <- c(B = beta, A = alfa, Z = dseta)
  
  CalDif <- function(Tiempo, Estados, Parametros) {
    with(as.list(c(Estados, Parametros)), {
      dS <- (-1) * B * Susceptibles * Zombies
      dZ <-  (B - A) * Susceptibles * Zombies + Z * Muertos
      dM <- A * Susceptibles * Zombies - Z * Muertos
      return(list(c(dS, dZ, dM)))
    })
  }
  
  Datos <- ode(y = Condiciones,
               times = Tiempo,
               func = CalDif,
               parms = Parametros
  )
  
  if(Grafica){
    plot.new()
    plot(Tiempo ,Datos[,2], lwd = 2,
         col = "orange", type = "l",
         main = "¡¡¡ Zombies !!!",
         ylab = "Población",
         ylim = c(0, Datos[1,2] + Datos[1,3] + Datos[1,4])
    )
    grid(lty = "dotted")
    lines(Tiempo, Datos[,3], lwd = 2, col = "blue")
    lines(Tiempo, Datos[,4], lwd = 2, col = "black")
    legend(x = 0, y = -sum(Estados)/3, c("Susceptibles","Zombies", "Muertos"),
           cex = 0.8, fill = c("orange", "blue", "black"),
           xpd = TRUE, bty = "n"
    )
  }
  Data<-data.frame(Datos)
  Data<-gather(Data, "group", "val", 2:4)
  
  if(Grafica){
    print(Data%>%ggplot2::ggplot(aes(x=time,y=val,color=group))+
            geom_smooth(method ="loess",formula = "y~x")+
            labs(title="Zombies model",x="Time",y="Size"))
    
  }
  
  return(Data)
}

ui <- fluidPage(
  titlePanel(title=h4("Zombies MODEL", align="center")),
  sidebarPanel(
    sliderInput("S", "Susceptible:",min = 0, max = 100, value=10),
    sliderInput("Z", "Zombies:",min = 0, max = 100, value=2),
    sliderInput("D", "Deaths:",min = 0, max = 100, value=2),
    sliderInput("time", "Time:",min = 2, max = 100, value= 5),  
    sliderInput("beta", "beta:",min = 0, max =1,value = 0.5, step = .01,round = FALSE),
    sliderInput("alfa", "alfa:",min = 0, max =1,value = 0.5, step = .01,round = FALSE),
    sliderInput("dseta", "dseta:",min = 0, max =1,value = 0.5, step = .01,round = FALSE)
  ),
  
  mainPanel(plotOutput("plot2")))

server <- function(input,output){
  dat <- reactive({
    test <- Zombieland(Tiempo=input$time,Estados=c(input$S,input$Z,input$D),  beta=input$beta,
                alfa=input$alfa,dseta=input$dseta,Grafica = 0)
    print(test)
    test
  })
  
  output$plot2<-renderPlot({
    ggplot2::ggplot(dat(),aes(x=time,y=val,color=group))+
      geom_smooth(method ="loess",formula = "y~x")+
      labs(x="Time",y="Size")
  },height = 400,width = 600)}

shinyApp(ui, server)

