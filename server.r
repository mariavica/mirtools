shinyServer(function(input, output) {
   library(ggplot2)
   #versions.mirnas <- read.table("https://raw.githubusercontent.com/mariavica/mirtools/master/data/miRBase_conversions.csv",header=TRUE,sep="\t")
   #totrow<-nrow(versions.mirnas)
   #totcol<-ncol(versions.mirnas)
   load("mirbase_conversions.RData")
   
   species_name<-c("Homo sapiens","Mus musculus","Rattus norvegicus","Caenorhabditis elegans",
     "Drosophila melanogaster","Danio rerio","Aedes aegypti", "Apis mellifera", "Arabidopsis thaliana", 
     "Bombyx mori", "Bos taurus", "Caenorhabditis briggsae", "Canis familiaris", "Chlamydomonas reinhardtii",
     "Drosophila pseudoobscura", "Epstein Barr virus", "Fugu rubripes", "Gallus gallus", "Human cytomegalovirus",
     "Kaposi sarcoma-associated herpesvirus", "Monodelphis domestica", "Mouse gammaherpesvirus 68",
     "Macaca mulatta", "Oryza sativa", "Populus trichocarpa", "Pan troglodytes", "Schmidtea mediterranea",
     "Tetraodon nigroviridis", "Vitis vinifera", "Xenopus tropicalis", "Zea mays")
   prefix<-c("hsa-","mmu-","rno-","cel-",
      "dme-","dre-","aae-","ame-","ath-",
      "bmo-","bta-","cbr-","cfa-","cre-",
      "dps-","ebv-","fru-","gga-","hcmv-",
      "kshv-","mdo-","mghv-",
      "mml-","osa-","ptc-","ptr-","sme-",
      "tni-","vvi-","xtr-","zma-")

    maketable <- reactive( if (input$mirname!=""  | !is.null(input$csvfile) )  {
      
      perc <- function (x,target) {
        return(length(which((target %in% x) == TRUE)) / length(target) *100)
      }
      
      versions.mirnas<-versions.mirnas[,-1]
      
      if (!is.null(input$csvfile)) {
        
        inFile<-input$csvfile
        
        uploadedm<-read.csv(inFile$datapath)
        
        mymirnas<-unlist(strsplit(as.character(uploadedm[,1]),c("\\,|\\ |\\\n")))
      }
      

      if (input$mirname!="") {
        mymirnas<-unlist(strsplit(as.character(input$mirname),c("\\,|\\ |\\\n")))
      }

      
      if (input$species!="(Not specified)") {
        specie<-which(species_name %in% input$species)
        sel<-c(grep("^miR",mymirnas),grep("^let",mymirnas))
        mymirnas[sel]<-paste(prefix[specie],mymirnas[sel],sep="")
        mymirnas[sel]<-gsub(paste(prefix[specie],prefix[specie],sep=""),prefix[specie],mymirnas[sel])
      } 

      
      if (input$capitalise) {
        ### put everyting in not capitals, except from the combination "miR"
        for (i in 1:length(letters)) {
          mymirnas<-gsub(LETTERS[i],letters[i],mymirnas)
        }
        mymirnas<-gsub("mir","miR",mymirnas)

        #### other common erros
        mymirnas<-gsub("[hH][aA][sS]","hsa",mymirnas)
      }

      mymirnas<-mymirnas[which(mymirnas!="")]
      #print(mymirnas)
      
      a<-apply(versions.mirnas,2,perc,mymirnas)
      
      dat<-data.frame(x=names(a),y=a)
      
      dat$x<-factor(gsub("miRBase_","",dat$x))
      dat$x<-relevel(dat$x,"9.2")
      dat$x<-relevel(dat$x,"9.1")
      dat$x<-relevel(dat$x,"9.0")
      dat$x<-relevel(dat$x,"8.2")
      dat$x<-relevel(dat$x,"8.1")
      dat$x<-relevel(dat$x,"8.0")
      dat$x<-relevel(dat$x,"7.1")
      dat$x<-relevel(dat$x,"7.0")
      dat$x<-relevel(dat$x,"6.0")
      #print(dat)
      
      maxs<-which(dat$y==max(dat$y))
      proposedversion<-dat[maxs[length(maxs)] ,"x"]	
      
      
      if (input$mirfrom != "I don't know") {
        selectedversion<-input$mirfrom
      } else {
        selectedversion<-proposedversion
      }
      
      #print(paste("miRBase_",selectedversion,sep=""))
      
      mymirnas<-as.character(mymirnas)
      mytrans<-data.frame(mymirnas)
      
      for (i in 1:nrow(mytrans)) {
        if (mymirnas[i] %in% versions.mirnas[,paste("miRBase_",selectedversion,sep="")] ) {
          mytrans[i,2]<-as.character(versions.mirnas[ which(  (versions.mirnas[,paste("miRBase_",selectedversion,sep="")] %in%  mymirnas[i])  ), c(paste("miRBase_",as.character(input$mirto),sep="")) ])
          
        } else {
          
          if (mymirnas[i] %in% as.vector(as.matrix(versions.mirnas))) {
            
            if (input$forceTranslation) {
                  coincidences <- which(t(versions.mirnas)==mymirnas[i])
                  #print(coincidences)
                  rowmir <- ceiling(coincidences[length(coincidences)]/(totcol-1))
                  #print(rowmir)
                  
                  mytrans[i,2]<-as.character(versions.mirnas[rowmir, c(paste("miRBase_",as.character(input$mirto),sep="")) ])
            }
            
            else {
            
            coincidences <- which(versions.mirnas==mymirnas[i])
            version <- colnames(versions.mirnas)[ceiling(coincidences[length(coincidences)]/totrow)]
            
             mytrans[i,2]<-as.character(paste("Not found in miRBase_",selectedversion," (found in ", version,")", sep=""))
             
            }
             
          } else {
            mytrans[i,2]<-paste("Unknown miRNA")
          }
          
        }
      }
      
      colnames(mytrans)<-c((paste("miRBase_",as.character(selectedversion),sep="")),c(paste("miRBase_",as.character(input$mirto),sep="")))
      
      
      return(list(mytrans,proposedversion,dat,max(dat$y)))
    })
    
    output$text1 <- renderText( if (input$mirname!=""  | !is.null(input$csvfile)) {
      paste("Most of your miRNAs are from version: ",maketable()[[2]]," (",round(maketable()[[4]],2),"%)\n",sep="")
    })  
    
    output$percent <- renderPlot({
      datp<-maketable()[[3]]
      qplot(x=datp$x, y=datp$y, fill=datp$x) + geom_bar(stat="identity") +
        guides(fill=FALSE) + xlab("miRBase version") + ylab("Coincidence (%)")
    })

    output$translated<-renderTable(maketable()[[1]])
    
    output$downloadTranslated <- downloadHandler( filename="translated.csv", content=function (file){ write.table(maketable()[[1]], file, row.names=FALSE, sep="\t", quote=FALSE) })
    

    
})
