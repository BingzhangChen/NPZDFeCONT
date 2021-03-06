plot_v_n <- function(Stn = 'S1', Models = c('NPZDcont_sRun'),
                     VARS=c('DIN','CHL','NPP','PON','DIP','POP'), BOTH=T, 
                     COLS=2:(length(Models)+1)){
 #  if (Stn == 'K2'){
 #     FigNo = 6
 #  }else if (Stn == 'S1'){
 #     FigNo = 7
 #  }else if (Stn == 'HOT'){
 #     FigNo = 13
 #  }

   fname <- paste0(Models,collapse='_')
   fname <- paste0(Stn, fname,'V_NChlPP.pdf')
   Dmax  <- 150
   pdf(fname, width=2*length(VARS),height=8,paper='a4')
   
   op <- par(font.lab = 1,
                family ="serif",
                mar    = c(2,2,1.5,0.5),
                mgp    = c(2.3,1,0),
                oma    = c(4,4,4,0),
                mfcol  = c(4,length(VARS))   ) 
   
   j <- 0
   for (Var in VARS){
     if (Var == 'CHL'){
       Varname  <- bquote(.(Var)~' (mg '*m^-3*')')
     }else if (Var == 'NPP'){
       Varname  <- bquote(.(Var)~' (mg C '*m^-3*' '*d^-1*')')
     }else if (Var == 'muN1'){
       Varname  <- bquote('µ ( '*d^-1*')')
     }else if (Var == 'C_Chl'){
       Varname  <- expression(paste("Chl:C "*' (gChl '*molC^-1*')'))
     }else if (Var == 'PHY1'){
       Varname  <- expression(paste("PHY "*'(mmol '*m^-3*')'))
     }else if (Var == 'N2P'){
       Varname  <- 'N:P (mol:mol)'
     }else if (Var == 'VPHY'){
       Varname  <- bquote(italic(V)[P] * ' (mmol '*m^-3*')'^2)
     }else if (Var == 'VNO3'){
       Varname  <- bquote(italic(V)[N] * ' (mmol '*m^-3*')'^2)
     }else if (Var == 'COVNP'){
       Varname  <- bquote(italic(COV)[NP] * ' (mmol '*m^-3*')'^2)
     }else{
       Varname  <- bquote(.(Var) ~ ' (mmol '*m^-3*')')
     }
   
       #Read observational data
       dat <- paste0(Stn,'_',Var,'.dat')
       dat <- read.table(dat,header=T)
       #Average into 4 seasons
       DOYs    <- seq(0,360,length.out=5)
       seasons <- c('Winter','Spring','Summer','Fall')
       for (i in 1:4){
         if (i == 4) {
            par(mar=c(4,2,1.5,0.5))
         }else{
            par(mar=c(2,2,1.5,0.5))
         }
         j    <- j+1
         dat_ <- dat[dat$DOY > DOYs[i] & dat$DOY <= DOYs[i+1],]
         dat_ <- dat_[dat_$Depth <= Dmax,]
         xmax <- max(dat_[,3])
         if (Stn == 'HOT'){
            if(Var == 'CHL'){
              xmax <- .5
            } else if (Var == 'NPP'){
              xmax <- 12
            } else if (Var == 'NO3'){
              xmax <- 10
            } else if (Var == 'PON'){
              xmax <- .6
            } else if (Var == 'DIP'){
              xmax <- .4
            }
         }else if(Stn == 'S1'){
            if(Var == 'CHL'){
              xmax <- 1
            } else if (Var == 'NO3'){
              xmax <- 8
            } else if (Var == 'PON'){
              xmax <- 1.3
            } else if (Var == 'NPP'){
              xmax <- 30
            }
         }
         plot(dat_[,3],-dat_$Depth,xlim=c(0,xmax),ylim=c(-Dmax,0),
              xlab=Varname,ylab='',pch=16,cex=.5,cex.lab=1.2)
         mtext(paste(letters[j],')',seasons[i]),adj=0)
   
        # if (i==1) mtext(Stn,adj=.7)
         ii = 0
         for (model in Models){
            ii    <- ii+1
            if (BOTH){
             DIR  <- paste0('~/working/FlexEFT1D/DRAM/',model,'/BOTH_TD/')
            } else{
             DIR  <- paste0('~/working/FlexEFT1D/DRAM/',model,'/',Stn,'/')
            }
            #Get modeled data
            if (Var == 'CHL'){
             Chl  <- getData(DIR,Stn, 'CHL')
            }else if (Var == 'DIN'){
             Chl  <- getData(DIR,Stn, 'NO3')
            }else if(Var == 'NPP'){
             Chl  <- getData(DIR, Stn, 'NPP')
            }else if(Var == 'C_Chl'){
             Chl  <- getData(DIR, Stn,'The1')
            }else if(Var == 'N2P'){
             NO3  <- getData(DIR,Stn, 'NO3')
             PO4  <- getData(DIR,Stn, 'PO4')
             Chl$days  <- NO3$days
             Chl$depth <- NO3$depth
             Chl$data  <- NO3$data/PO4$data
            }else{
             Chl  <- getData(DIR,Stn,Var)
            }
             days    = Chl$days
            depth    = Chl$depth
             Chl     = Chl$data
             d_per_y = 360
             #Get the data of the final year
             w   <- (nrow(Chl)-d_per_y+1):nrow(Chl)
             Chl <- Chl[w,]
             Chl <- sapply(1:ncol(Chl), function(x)as.numeric(as.character(Chl[,x])))
             #Read model results:
             mdoy  <- 1:nrow(Chl)
             k     <- which(mdoy > DOYs[i] & mdoy <= DOYs[i+1])
             Chl_  <- Chl[k,]
             #Calculate quantiles:
             cff   <- sapply(1:ncol(Chl_),function(k)quantile(Chl_[,k], probs=c(0.025,0.5,0.975)))
             matlines(t(cff), depth, lty=c(2,1,2), lwd=c(.3,1.5,.3), col=COLS[ii])
         }
         
         if (Var == 'DIN' && i == 1 && length(Modnames) > 1){
            legend('topright',Modnames,col=COLS,lty=1)
         }
       }
     }   
     mtext('Depth (m)',side = 2, outer=TRUE, line=1)
     if (Stn == 'HOT') Stn = 'ALOHA'
     #mtext(paste('Fig.', FigNo,'. Model fittings to vertical profiles of DIN, CHL, NPP, and PON at',Stn),side=1,outer=T, line=2,adj=0)
     VARS <- paste0(VARS, collapse = ' ')
     mtext(paste('Model fittings to vertical profiles of ', VARS, ' at ',Stn),side=1,outer=T, line=2,adj=0)
     #mtext(Sys.time(), side = 3, outer=TRUE, line=2)
   dev.off()
 } 

