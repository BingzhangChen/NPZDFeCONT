Module BIO_MOD
implicit none
public

! Number of stations to run
integer, parameter :: Nstn        = 1

! Number of vertical layers
integer, parameter :: nlev        = 30  

! Options of biological models
integer, parameter :: EFTdisc     = 1
integer, parameter :: EFTcont     = 2
integer, parameter :: Geiderdisc  = 3
integer, parameter :: NPZDcont    = 4
integer, parameter :: EFTsimple   = 5
integer, parameter :: Geidersimple= 6
integer, parameter :: NPZDFix     = 7
integer, parameter :: NPZDdisc    = 8
integer, parameter :: EFTsimIRON  = 9
integer, parameter :: NPZDFixIRON = 10
integer, parameter :: GeidsimIRON = 11
integer, parameter :: NPZDdiscFe  = 12
integer, parameter :: EFTdiscFe   = 13
integer, parameter :: EFTPPDD     = 14
integer, parameter :: EFT2sp      = 15
integer, parameter :: NPZD2sp     = 16
integer, parameter :: NPPZDD      = 17

! Parameters for phytoplankton size fractional Chl
real, parameter :: pi=3.1415926535897932384633D0
real, parameter :: PMU_min = log(1d1*pi/6d0*0.6**3)
real, parameter :: PMU_max = log(1d1*pi/6d0*4d1**3)
real, parameter :: PMU_1   = log(1d1*pi/6d0)
real, parameter :: PMU_3   = log(1d1*pi/6d0*3d0**3)
real, parameter :: PMU_10  = log(1d1*pi/6d0*1d1**3)

integer         :: AllocateStatus
integer         :: N_MLD   ! vertical grid index at the bottom of MLD

real     :: Temp(nlev), PAR(nlev), dtdays, Ntot, PARavg 
real     :: DFe(nlev)                           ! Dissolved iron concentration
real     :: Z_r(1:nlev), Z_w(0:nlev), Hz(nlev)  ! Grid variables
real     :: I_zero
integer  :: NVAR, Nout, iZOO, iDET, iDET2, iPMU, iVAR, ifer
integer  :: NVsinkterms,NPHY, NPar
integer  :: oZOO, oDET, oDET2,oPON, oFER, oZ2N, oD2N, oPHYt,oCHLt,oPPt,omuAvg
integer  :: oPMU, oVAR, odmudl,odgdl,od2mu,od3mu,od4mu,od2gdl
integer  :: oD_NO3,oD_ZOO,oD_DET,oD_DET2,oD_PMU,oD_VAR,oD_fer,oPAR_
integer  :: oCHLs(4)   ! Four size fractions of CHL

! Indices for parameters used in DRAM
integer  :: imu0,iaI0,igmax,iKN,iKFe, ialphamu, ibetamu,ialphaKN
integer  :: imu0B, iaI0B, iA0N2, iRL2,iKN2,ibI0B, itau
integer  :: iEp,iEz,izetaN,izetaChl, iaI0_C 
integer  :: ialphaI,iA0N,ialphaA,ialphaG,ialphaK, ialphaFe
integer  :: ikp,iQ0N,ialphaQ,iPenfac,iLref,iwDET,iwDET2,irdN,imz
integer  :: ithetamin,iQNmin, iVTR, idustsol
integer, allocatable :: iPHY(:), oPHY(:),oTheta(:),oQN(:)
integer, allocatable :: iCHL(:), oCHL(:),omuNet(:),oD_PHY(:),oD_CHL(:)
integer, allocatable :: oGraz(:),oSI(:), oLno3(:)
integer, allocatable :: Windex(:)
real,    allocatable :: Vars(:,:),Varout(:,:), params(:)
character(LEN=6), allocatable :: ParamLabel(:)
!  Indices for external forcing variables
integer, parameter :: etemp      = 1
integer, parameter :: eNO3       = 2
integer, parameter :: eAks       = 3
integer, parameter :: ew         = 4
integer, parameter :: ePAR       = 5
integer, parameter :: eDust      = 6     ! Dust
integer, parameter :: eFer       = 7     ! Fer
integer, parameter :: TNFo       = eFer  ! TOtal number of forcings

! Total of observation times in forcing data
character(LEN=5), parameter :: LabelForc(TNFo) = (/'temp','NO3','Aks','wROMS','par', 'Dust', 'fer'/)
integer,          parameter :: NFobs(TNFo)     = (/    12,   12, 36,     12,  12,   12,      12 /)

! Fixed Model parameters:
real, parameter :: PMUmax =1.5D1, VARmax=50D0
real, parameter :: Femin  =0.02
real            :: K0Fe   =0.08,alphaFe=0.14
real, parameter :: GGE    =0.3, unass =0.24
real, parameter :: thetm  =0.65
real, parameter :: RMchl0 =0.1
real            :: alphamu,     betamu=0d0

!Temperature senstivity tuned by the algorithm
real, parameter :: Ep     =0.5, Ez    =0.6 
real :: KFe    =0.08     !Unit: nM. Gregg (2003) used ~0.1 nM for phyto

!These two parametes also to be tuned by the algorithm
real :: zetaChl=0.8, zetaN =0.6

! Size and weights for discrete models
real, allocatable          :: PMU_(:)
real, allocatable          :: wtCHL(:,:)  ! weight for each size class
! Indices for state variables
integer, parameter :: iNO3=1,oTemp=1,oPAR=2,oAks=3,oDust=4,oNO3=1,ow=5
integer            :: nutrient_uptake=1, grazing_formulation=3   
logical, parameter :: kill_the_winner=.TRUE.
logical            :: do_IRON        =.FALSE.
logical            :: singlerun      =.FALSE.
logical            :: FavorNPP       =.FALSE.

! Output indices:
character(LEN=10), allocatable  :: Labelout(:)  

integer,   parameter :: namlst=8
character(LEN=3)     :: Stn(Nstn)

! Model options:
integer              :: Model_ID = EFTdisc

! Local variables:
real :: INGES,gbar,EGES,Zmort,RES
real :: pp_ZP, pp_NZ, pp_ND, pp_DZ, tf_p, tf_z

CONTAINS
!========================================================
! Calculate total nitrogen in the system
subroutine Cal_TN
implicit none
integer :: i,k

Ntot = 0d0

do k = 1,nlev
   do i = 1,iDET
      Ntot = Ntot + Vars(i,k) * Hz(k)
   enddo
enddo

end subroutine Cal_TN
!========================================================
subroutine assign_PMU
implicit none
integer :: i
real    :: dx
integer :: AllocateStatus
! Calculate the average size 
allocate(PMU_(NPHY), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"
PMU_(:)    = 0d0

allocate(wtCHL(4,NPHY), STAT = AllocateStatus)
IF (AllocateStatus /= 0) STOP "*** Not enough memory ***"

wtCHL(:,:) = 0d0

PMU_(1)= PMU_min
dx     = (PMU_max-PMU_min)/dble(NPHY-1)

do i=2,NPHY
   PMU_(i) = PMU_(i-1)+dx
enddo

! Calculate the weight for each size class 
! (largest size class being the first to be consistent with observational data)
do i=1,NPHY
   if (PMU_(i) .le. PMU_1) then
      wtCHL(4,i) = 1d0  ! < 1 um
   elseif (PMU_(i) .le. PMU_3) then
      wtCHL(3,i) = 1d0  ! 1-3 um
   elseif (PMU_(i) .le. PMU_10) then
      wtCHL(2,i) = 1d0  ! 3-10 um
   else
      wtCHL(1,i) = 1d0  ! >10 um
   endif
enddo
end subroutine assign_PMU
!========================================================
real function TEMPBOL(Ea,tC)
implicit none
!DESCRIPTION:
!The temperature dependence of plankton rates are fomulated according to the Arrhenuis equation. 
! tC: in situ temperature
! Tr: reference temperature
!
!INPUT PARAMETERS:
real, intent (in) :: Ea, tC
! boltzman constant constant [ eV /K ]
real, parameter   :: kb = 8.62d-5, Tr = 15D0

TEMPBOL = exp(-(Ea/kb)*(1D0/(273.15 + tC)-1D0/(273.15 + Tr)))
return 
end function TEMPBOL
!====================================================
real function ScaleTrait( logsize, star, alpha ) 
implicit none
real, intent(IN) :: logsize, star, alpha

! Calculate the size-scaled value of a trait
! for the given log (natural, base e) of cell volume as pi/6*ESD**3 (micrometers). 

ScaleTrait = star * exp( alpha * logsize )

return
end function ScaleTrait
!====================================================
real function PenAff( logsize, alpha, Pfac, lmin ) 
implicit none
real, intent(IN) :: logsize, alpha, Pfac, lmin 

!A 'penalty' function to reduce the value of affinity for nutrient at very small cell sizes
!in order to avoid modeling unrealistically small cell sizes.  This is needed because affnity
!increases with decreasing cell size, which means that under low-nutrient conditions, without
!such a penalty, unrealistically small cell sizes could be predicted.
!This penalty function becomes zero at logsize = lmin.   
   
  PenAff = 1.0 - exp(Pfac*alpha*(logsize - lmin))
end function PenAff
!====================================================
real function grazing(Hollingtype, Ksat, Prey)
implicit none
real,    intent(in) :: Ksat, Prey
integer, intent(in) :: Hollingtype
! kp relates to the capture coefficient
SELECT CASE(Hollingtype)
  ! Holling Type I
  case (1)
    grazing = min(Prey/2.0/Ksat,1.0)
  ! Holling Type II
  case (2)
    grazing = Prey/(Ksat + Prey)  
  ! Holling Type III
  case (3) 
    grazing = min(Prey*Prey/(Ksat*Ksat + Prey*Prey), 1D0)
 ! Ivlev
  case (4)
 !To be consistent with other functions  
    grazing = 1d0-exp(-log(2d0)*Prey/Ksat) 

END SELECT
return
end function grazing
!===================================================
END Module BIO_MOD
