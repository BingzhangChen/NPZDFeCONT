PROGRAM AMAssim
USE sub_mod
implicit none
real(4) :: start,finish,t2,t1
logical :: there
! All parameters varied in an Identical Twin Test assimilation.
integer :: i,j,k,row,col
integer :: Readfile   = NO  ! Read parameter set from "enssig" and "enspar", and start from Subpcurr
real, allocatable  :: enspar1(:,:)    ! scratch matrix to store previous runs of parameters
integer            :: NR_enspar=100
integer            :: N_cvm
namelist /MCMCrun/ nruns, EnsLen, NDays, Readfile, NR_enspar
      
call cpu_time(start) 

!  open the namelist file and read station name.
open(namlst,file='Model.nml',status='old',action='read')
read(namlst,nml=MCMCrun)
close(namlst)

!Initialize the Arrays of model parameters with the biological model chosen
call SetUpArrays

! Initialize the 1D model:
call Model_setup

! Initialize the random number generator with a seed
call sgrnd(17001)

! An initial guess that is some factor times the inital parameter estimates 
subpguess = Npv

!  Set current to guess
subpcurr  = subpguess
subppro   = subpguess
subppro2  = subpguess

! A very large, negative number for very low probability
BestLogLike = -1d12  
startrun    = 0
      
! Estimate the priors based on initial parameter values
call EstimatePriors(PriorCvm, InvPriorCvm, error)

! Set the labels for the standard deviations for each type of observation 
call SetSigmaLabels
      
! Take the intial Covariance matrix to be the Prior Covariance Matrix
! (these are in compacted form)
! PriorCvm is the prior covariance matrix generated by the subroutine EstimatePriors 
! Cvm is the Covariance Matrix for parameters
Cvm = PriorCvm

write(6, *) 'Initial Covariance matrix = '
do row = 1, Np2Vary
   write(6,3000) (Cvm(row*(row-1)/2+col), col = 1, row )
end do

Rwtold = 1d0  ! Set the initial weight equal to One
      
! Set the Proposal covariance matrix, by scaling the Parameter Covariance matrix
Pcvm = Cvm*Spcvm/Np2Vary  ! Np2Vary = d in p. 11 of Laine 2008

! Add a small term to the diagonal entries, so that the matrix will not be singular. 
do k = 1, Np2Vary
   Pcvm(k*(k+1)/2) = Pcvm(k*(k+1)/2) + CvEpsilon*Spcvm/Np2Vary
enddo

! Calculate the Cholesky factor for Pcvm, which is called Rchol here. 
! The Pcvm and Rchol will not vary until the burn-in finishes.
call cholesky(Pcvm,Np2Vary,Np2Vary*(Np2Vary+1)/2,Rchol,nullty,error)
   
write(6, *) 'Initial Proposal Covariance matrix = '

DO row = 1, Np2Vary
   write(6,3000) (Pcvm(row*(row-1)/2+col), col = 1, row )
End do

write(6, *) 'Cholesky factor for Proposal Covariance matrix = '
DO row = 1, Np2Vary
   write(6,3000) ( Rchol(row*(row-1)/2+col), col = 1, row )
Enddo

! Reset subpmean to Zero for the new run
subpmean     = 0d0
subpcurrmean = 0d0
sigmamean    = 0d0

IF(nruns .gt. 1) THEN
  ! Read the ensemble files
  IF (Readfile) then
     inquire(FILE=epfn,exist=there)
     if (.not. there) then
        write(6,*) 'Cannot find the file ',epfn,'! Quit!'
        stop
     else
     ! Read the enspar file
       i = NPar+2
       allocate(enspar1(NR_enspar,i))
       enspar1(:,:) = 0d0
       call Readcsv(epfn,NR_enspar,i, enspar1)

     ! Calculate CVM (Take the final N_cvm chains, otherwise Pcvm too large)
       N_cvm = NR_enspar-BurnInt
       if (NR_enspar > N_cvm) then
          k = NR_enspar-N_cvm+1
          Rwtold=real(N_cvm)
       else
          k = 1
          Rwtold=real(NR_enspar)
       endif

       do i=k,NR_enspar
          do j=1,NPar
             Apvcurr(j)=enspar1(i,j+2)
          enddo

          subpcurr = Npv_(Apvcurr)

          call UpdateCVM(Cvm,subpcurrmean,dble(i-k+1),subpcurr,subpcurrmean,Cvm)
       enddo

       write(6, *) 'Updated Covariance matrix = '
       do row = 1, NPar
          write(6,3000) (Cvm(row*(row-1)/2+col), col = 1, row )
       end do

       Pcvm = Cvm*Spcvm/NPar
     ! add a small term to the diagonal entries,
     ! so that the matrix will not be singular. 
       do k = 1, NPar
         Pcvm(k*(k+1)/2)=Pcvm(k*(k+1)/2) + CvEpsilon*Spcvm/NPar
       enddo

       write(6, *) 'Updated Proposal Covariance matrix = '
       DO row = 1, Np2Vary
          write(6,3000) (Pcvm(row*(row-1)/2+col), col = 1, row )
       End do

       startrun=NR_enspar

     ! Obtain current position:
       do i = 1, NPar
          Apvcurr(i) = enspar1(NR_enspar,i+2)
       enddo

       subpcurr    = Npv_(Apvcurr)
       subppro     = subpcurr
       subpbest    = subpcurr
       jrun        = enspar1(NR_enspar,1)
       CurrLogLike = enspar1(NR_enspar,2)
       deallocate(enspar1)

       ! Write out current parameters:
       do i = 1, Np2Vary
          write(6,101) ParamLabel(i), subpcurr(i), Apvcurr(i)
       enddo

     ! Read the enssig file (containing two stations)
       i=2+NDTYPE*Nstn*2
       allocate(enspar1(NR_enspar,i))
       enspar1(:,:) = 0d0
       call Readcsv(esfn,NR_enspar,i, enspar1)

       do i=1,NDTYPE * Nstn
          sigma(i)=enspar1(NR_enspar,2       +i)
           SSqE(i)=enspar1(NR_enspar,2+NDTYPE*Nstn+i)
       enddo

       sigmabest= sigma
       CurrSSqE = SSqE
       deallocate(enspar1)
     endif
ELSE 
     ! Create new ensemble files
     ! Parameter Ensemble file (only one file needed)
       open(epfint,file=epfn,status='replace',action='write')
       write(epfint,1800) (ParamLabel(i), i = 1, Np2Vary)
       close(epfint)

     ! Sigma (standard error) Ensemble file (One file needed)
       open(esfint,file=esfn,status='replace',action='write')
       write(esfint,1900)  (SigmaLabel(i), i = 1,NDTYPE*Nstn), &
                           ( SSqELabel(i), i = 1,NDTYPE*Nstn)
       close(esfint)
    
     ! Output Ensemble files to store the ensemble of simulated values
     ! Be consistent with subroutine modelensout
       open(eofint, file=eofn,status='replace',action='write')
       write(eofint,'(5(A8))')  'RunNo   ',   &
                                'DOY     ',   &
                                'Depth   ',   &
                                'Name    ',   &
                                'Value   '
       close(eofint)
  ENDIF
ENDIF

! First, one simulation, to initialize all routines
! This avoids the problem that
! Parameter Values will be read from the data file on the initial run;
! if they are different than the values in this program for Assimilated Params,
! this could return a much different cost. 
! If the cost with the Values in the Parm file is much lower,
! the assimilation may almost never accept any new parameter sets)

AMacc       = 0
DRacc       = 0
MeanLogLike = 0d0
write(6, *) ' Testing running time for each model run:'
! Write output 
! run with the Best Parameters, writing to the best output file
call cpu_time(t1)
open(bofint, file=bofn,action='write',status='replace')
savefile = .FALSE.
call model(bofint, subppro, SSqE )
CurrLogLike = CalcLogLike(SSqE,sigma,subppro)
write(6, 1001) CurrLogLike
close(bofint)
call cpu_time(t2)
print '("One model run takes ",f8.3," seconds.")', t2-t1 
CurrSSqE = SSqE
!------------------------------------------
!	HERE STARTS THE MAIN LOOP
!------------------------------------------
! The counter for the jth run
jrun        = startrun + 1

! Total number of runs
nruns       = nruns + startrun
AMacc       = 0
DRacc       = 0
BestLogLike = CurrLogLike 
sdev(:)     = 0 !Variance of parameters

call MCMC_adapt
write(6, *) ' Finished the main loop for assimilation! '
write(6, *)
write(6, *) ' Final Proposal Covariance matrix = '
DO row = 1, Np2Vary
   write(6,3000) ( Pcvm( row*(row-1)/2 + col ), col = 1, row )
ENDDO

write(6, *) ' Writing the last entry in',          &
            ' the ensembles of simulated values.'
!$ write output ot Ensemble file for simulated values

savefile=.TRUE.
call modelensout(eofint, jrun, subpcurr, dumE)
close(eofint)

!	end of main loop...now we are basically finished and
!	just produce a few summary statistics
 if( nruns .gt. 1 ) then
   ! Write the Ensemble of Parameters for each Incubation simulated.
   ! Write Ensemble file(s) (Run #, Cost and Parameters)
   ! Open enspar for writing
   open(epfint,file=epfn,status='old',&
        action='write',position='append')
   ! Open enssig for writing
   open(esfint,file=esfn,status='old',&
        action='write',position='append')

   cffpar= Apv_(subpcurr)
   write(epfint,1850) jrun, CurrLogLike, (cffpar(i), i = 1, Np2Vary)
   write(esfint,1850) jrun, CurrLogLike, &
                      (sigma(i),   i = 1, NDTYPE*Nstn), &
                      (CurrSSqE(i),i = 1, NDTYPE*Nstn)
   close(epfint)
   close(esfint)
 endif
 call write_bestpar
 call write_bestsigma  
      
101  format(A8, 2(1x, 1pe12.2))
1001 format(/,'LogL = ',1pe13.3,/)
1010 format(5x,' i = ',i4,', read the following line:')
1050 format(/,'Starting the main loop to Assimilate ',/) 
1200 format(a15,1x,i16)
1210 format('** % 1st Accept. = ',1x,1f8.2,                         &
            '     ** % 2nd Accept. = ',1f8.2)
1220 format(a25,1x,1pe11.3)
1300 format('*** LogL:    New ',1pe11.3,'     Curr ',1pe11.3,  &
           '     Best ',1pe11.3)
1310 format('*** LogL:    New ',1pe11.3,'     Curr ',1pe11.3,  &
           '     Best ',1pe11.3,'     Mean ',1pe11.3)

1320 format(    a15,1x,1pe20.13,4(1x,1pe20.3), /) 

1350 format('LogL:    New ',f10.1,'   Curr ',f10.1,'   Best ',f10.1, &
           '   acceptance = ',f10.2,' %',/,                          &
           ' with Subpcurr  = ',100(f11.5,/,70x) )
1800 format('Run        LogL     ', 100(a15) )
1850 format(i9,1x,100(1pe12.3,2x))
1900 format('Run        LogL     ', 100(a12,2x) )
3000 format(5x,<NPar>(1pe8.1,1x))
call cpu_time(finish)
print '("Time = ",f8.3," hours.")', (finish-start)/3600.0 
END PROGRAM AMAssim
