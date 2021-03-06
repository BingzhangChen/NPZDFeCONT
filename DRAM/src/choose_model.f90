SUBROUTINE choose_model
USE bio_MOD
implicit none
integer             :: i
namelist /Model/    Stn, Model_ID, nutrient_uptake, grazing_formulation, bot_bound
character(len=10), parameter :: format_string = "(A5,I0)"

! open the namelist file and read station name.
open(namlst,file='Model.nml',status='old',action='read')
read(namlst,nml=Model)
close(namlst)

if (Model_ID     == NPZDdisc) then
  if(taskid==0) &
     write(6,*) 'Inflexible NPZD discrete model selected!'
  NPHY    = 20
else if (Model_ID== NPZDdiscFe) then
  if(taskid==0) write(6,*) 'Inflexible NPZD discrete model with Iron selected!'
  NPHY    = 20
  do_IRON = .TRUE.
else if (Model_ID== Geiderdisc) then
  if(taskid==0) write(6,*) 'Geider discrete model selected!'
  NPHY    = 20
else if (Model_ID== EFTdisc) then
  if(taskid==0) write(6,*) 'Flexible discrete model selected!'
  NPHY    = 20
else if (Model_ID== EFTdiscFe) then
  if(taskid==0) write(6,*) 'Flexible discrete model selected!'
  NPHY    = 20
  do_IRON = .TRUE.
else if (Model_ID==NPZDFix) then
  if(taskid==0) write(6,*) 'Inflexible NPZD model selected!'
  NPHY = 1
  do_IRON = .FALSE.
else if (Model_ID==NPZDN2) then
  if(taskid==0) write(6,*) 'NPZD model with N2 fixation selected!'
  NPHY = 1
  N2fix= .true.
else if (Model_ID==NPZDFixIRON) then
  if(taskid==0) write(6,*) 'Inflexible NPZD model with Iron selected!'
  do_IRON = .TRUE.
  NPHY    = 1
else if (Model_ID==Geidersimple) then
  if(taskid==0) write(6,*) 'Geider simple model selected!'
  NPHY = 1
else if (Model_ID==GeiderDroop) then
  if(taskid==0) write(6,*) 'Geider-Droop model (variable N:C and Chl:C ratio) selected!'
  NPHY    = 1
  DO_IRON = .FALSE.
  imu0    =  1
  igmax   =  imu0   + 1  
  imz     =  igmax  + 1
  irhom   =  imz    + 1
  iwDET   =  irhom  + 1
  iaI0    =  iwDET  + 1
  NPar    =  iaI0

else if (Model_ID==GeidsimIRON) then
  if(taskid==0) write(6,*) 'Geider simple model with Iron selected!'
  do_IRON = .TRUE.
  NPHY    = 1
else if (Model_ID==NPclosure) then
  if(taskid==0) write(6,*) 'Nutrient-Phytoplankton (NP) closure model selected!'
  NPHY    = 1
  DO_IRON = .FALSE.
  imu0    = 1
  iIopt   = imu0  +1
  iaI0_C  = iIopt +1
  iKN     = iaI0_C+1
  iDp     = iKN   +1
  iwDET   = iDp   +1  ! Index for phytoplankton sinking rate
  ibeta   = iwDET +1  ! Beta: ratio of total variance to mean concentration
  NPar    = ibeta
else if (Model_ID==EFTsimple) then
  if(taskid==0) write(6,*) 'Flexible simple model selected!'
  NPHY    = 1
  DO_IRON = .FALSE.
  igmax   =  1  
  imz     =  igmax  + 1
  iA0N    =  imz    + 1
  iwDET   =  iA0N   + 1
  iaI0    =  iwDET  + 1
  iQ0N    =  iaI0   + 1
  NPar    =  iQ0N

else if (Model_ID==EFTsimIRON) then
  if(taskid==0) write(6,*) 'Flexible simple model with Iron selected!'
  do_IRON = .TRUE.
  NPHY = 1
else if (Model_ID==EFTcont) then
  if(taskid==0) write(6,*) 'Flexible continous model selected!'
  NPHY = 1
else if (Model_ID==NPZDcont) then
  if(taskid==0) write(6,*) 'Continuous size (CITRATE) model selected!'
  NPHY    = 1
  DO_IRON = .TRUE.
  imu0    =  1
  iKPHY   =  imu0   + 1  
  imz     =  iKPHY  + 1
  iKN     =  imz    + 1
  iwDET   =  iKN    + 1
  iaI0_C  =  iwDET  + 1
  ialphaI =  iaI0_C + 1
  iVTR    =  ialphaI+ 1
  iKFe    =  iVTR    +1
  NPar    =  iKFe

else if (Model_ID==CITRATE3) then
  if(taskid==0) write(6,*) &
    'Continuous size three trait model selected!'
  NPHY    = 1
  DO_IRON = .TRUE.
  imu0    =  1
  iKPHY   =  imu0   + 1  
  imz     =  iKPHY  + 1
  iwDET   =  imz    + 1
  iVTRL   =  iwDET  + 1
  iVTRT   =  iVTRL  + 1
  iVTRI   =  iVTRT  + 1
  iKFe    =  iVTRI  + 1
  NPar    =  iKFe
else if (Model_ID==EFT2sp .OR. Model_ID==NPZD2sp) then
  if(taskid==0) write(6,*) 'Two species phytoplankton model selected!'
  NPHY = 2
else if (Model_ID==NPPZDD .OR. Model_ID==EFTPPDD) then
  if(taskid==0) write(6,*) 'Two phytoplankton two detritus model selected!'
  NPHY = 2
endif

allocate(iPHY(NPHY))
allocate(iCHL(NPHY))
allocate(oPHY(NPHY))
if (Model_ID == GeiderDroop) then
    allocate(iPHYC(NPHY))
    allocate(oPHYC(NPHY))
    allocate(oD_PHYC(NPHY))
endif
allocate(oCHL(NPHY))
allocate(omuNet(NPHY))
allocate(oSI(NPHY))
if (Model_ID .ne. NPclosure) then
   allocate(oGraz(NPHY))
   allocate(oLno3(NPHY))
endif
allocate(oD_PHY(NPHY))
allocate(oD_CHL(NPHY))
allocate(otheta(NPHY))
allocate(oQN(NPHY))
if (N2fix) allocate(oQp(NPHY))

do i=1,NPHY
   iPHY(i) = i + iNO3
enddo 

if (Model_ID .eq. NPclosure) then
    iVNO3  = iPHY(NPHY) + 1
    iVPHY  = iVNO3      + 1
    iCOVNP = iVPHY      + 1
    NVAR   = iCOVNP
else
    iZOO   = iPHY(NPHY)+1
endif
if (Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
   iZOO2= iZOO +1
   iDET = iZOO2+1
else
   iDET = iZOO+1
endif

if (Model_ID==Geiderdisc .or. Model_ID==Geidersimple .or. &
    Model_ID==GeidsimIRON.or. Model_ID==GeiderDroop) then
   do i=1,NPHY
      iCHL(i) = i + iDET
   enddo 
   if (Model_ID==GeiderDroop) then
      do i=1,NPHY
         iPHYC(i) = i + iCHL(NPHY)
      enddo 
      NVAR = iPHYC(NPHY)
   else
      NVAR = iCHL(NPHY)
   endif
else if(Model_ID==EFTcont .or. Model_ID==NPZDcont) then
   iDETFe=iDET  + 1   ! Detritus in iron
   iPMU = iDETFe+ 1
   iVAR = iPMU  + 1
   NVAR = iVAR 
   if (Model_ID == NPZDcont) then
      ifer = iVAR + 1
      NVAR = ifer
   endif
elseif (Model_ID==CITRATE3) then
  iDETFe= iDET  + 1   ! Detritus in iron
   iPMU = iDETFe+ 1
   iVAR = iPMU  + 1
   iMTo = iVAR  + 1
   iVTo = iMTo  + 1
   iMIo = iVTo  + 1
   iVIo = iMIo  + 1
   ifer = iVIo  + 1
   NVAR = ifer
else if(Model_ID==NPPZDD .or. Model_ID==EFTPPDD) then
   iDET2= iDET + 1
   NVAR = iDET2
else if(Model_ID==NPZDN2) then
   iDETp = iDET + 1
   iPO4  = iDETp+ 1
   iDIA  = iPO4 + 1
   NVAR  = iDIA
else if(Model_ID.ne.NPclosure) then
   NVAR = iDET
endif

allocate(Vars(NVAR,nlev))
Vars(:,:)=0d0

if (Model_ID==Geiderdisc .or. Model_ID==Geidersimple .or. &
    Model_ID==GeidsimIRON) then
    NVsinkterms = 1 + NPHY * 2  ! Include phyto and Chl
else if (Model_ID==GeiderDroop) then
    NVsinkterms = 1 + NPHY * 3  ! Include phyto, PHYC, and Chl
else if (Model_ID==NPPZDD .or. Model_ID==EFTPPDD .or. Model_ID==NPZDN2) then
    NVsinkterms = 2 + NPHY
else if (Model_ID==NPclosure) then
    NVsinkterms = NPHY*2
else
    NVsinkterms = 1 + NPHY
endif

allocate(Windex(NVsinkterms))
do i=1,NPHY
   Windex(i)=iPHY(i)
   select case(Model_ID)
   case(Geiderdisc, Geidersimple, GeidsimIron, GeiderDroop)
      Windex(i+NPHY)=iCHL(i)
      if (Model_ID == GeiderDroop) &
      Windex(i+NPHY*2)=iPHYC(i)
   case(NPclosure)
      Windex(1+NPHY)=iVPHY
   case default
      stop "Model_ID is incorrect!"
   end select
enddo

if (Model_ID==NPPZDD .or. Model_ID==EFTPPDD) then

   Windex(NVsinkterms-1)=iDET
   Windex(NVsinkterms)  =iDET2

elseif (Model_ID==NPZDN2) then
   Windex(NVsinkterms-1)=iDET
   Windex(NVsinkterms)  =iDETp

elseif (Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
   Windex(NVsinkterms-1)=iDET
   Windex(NVsinkterms)  =iDETFe
else
   Windex(NVsinkterms)=iDET
endif

! Output array matrices (the order must be consistent with Vars)
do i=1,NPHY
   oPHY(i) =i+oNO3
enddo

IF (Model_ID .eq. NPclosure) then
    oVNO3  =oPHY(NPHY)+1
    oVPHY  =oVNO3     +1
    oCOVNP =oVPHY     +1
    oCHL(1)=oCOVNP    +1
ELSE
    oZOO   =oPHY(NPHY)+1
    if (Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
        oZOO2=oZOO +1
        oDET =oZOO2+1
    else
        oDET =oZOO+1
    endif
    if(Model_ID==EFTcont .or. Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
       oDETFe=oDET+1
       oPMU=oDETFe+1
       oVAR=oPMU+1
       if (do_IRON) then
          if (Model_ID==CITRATE3) then
           oMTo = oVAR+1
           oVTo = oMTo+1
           oMIo = oVTo+1
           oVIo = oMIo+1
           ofer = oVIo+1
          else
           ofer = oVAR+1
          endif
          oFescav = ofer   + 1
          odstdep = oFescav+ 1
          do i=1,NPHY
             oCHL(i) = i + odstdep
          enddo 
       else
          do i=1,NPHY
             oCHL(i) = i + oVAR
          enddo 
       endif
    else if (Model_ID == NPPZDD .or. Model_ID==EFTPPDD) then
       oDET2=oDET+1
       do i=1,NPHY
          oCHL(i) = i + oDET2
       enddo 
    else if (Model_ID == NPZDN2) then
       oDETp=oDET+1
       oPO4 =oDETp+1
       oDIA =oPO4 +1
       oPOP =oDIA +1
       oDIAu=oPOP +1
       do i=1,NPHY
          oCHL(i) = i + oDIAu
       enddo 
    else
      do i=1,NPHY
         oCHL(i) = i + oDET
      enddo 
    endif

    if (Model_ID == GeiderDroop) then
      do i=1,NPHY
         oPHYC(i) = i + oCHL(NPHY)
      enddo 
    endif
ENDIF
! The above must match with i** indeces   
!=======================================
if (Model_ID == GeiderDroop) then
   oPHYt=oPHYC(NPHY)+1
else
   oPHYt=oCHL(NPHY)+1
endif

oCHLt=oPHYt+1

if (     Model_ID==Geiderdisc.or. Model_ID==NPZDdisc  &
    .or. Model_ID==EFTdisc   .or. Model_ID==CITRATE3  &
    .or. Model_ID==EFTcont   .or. Model_ID==NPZDcont) then
   do i=1,4
      oCHLs(i)=oCHLt+i
   enddo
endif

if (Model_ID==Geiderdisc .or. Model_ID==NPZDdisc &
.or.Model_ID==CITRATE3   .or. Model_ID==EFTdisc  &
.or.Model_ID==EFTcont    .or. Model_ID==NPZDcont) then
   do i=1,NPHY
      omuNet(i)= oCHLs(4) + i
   enddo
else
   do i=1,NPHY
      omuNet(i)= oCHLt + i
   enddo
end if

if (Model_ID .ne. NPclosure) then
   do i=1,NPHY
      oGraz(i) = omuNet(NPHY) + i
   enddo
   do i=1,NPHY
      oLno3(i) = oGraz(NPHY)  + i
   enddo
   do i=1,NPHY
      oSI(i)   = oLno3(NPHY)  + i
   enddo
else
   do i=1,NPHY
      oSI(i)   = omuNet(NPHY) + i
   enddo
endif

do i=1,NPHY
   oQN(i)=oSI(NPHY)+i
enddo

if (N2fix) then
   do i=1,NPHY
      oQp(i)=oQN(NPHY)+i
   enddo
   do i=1,NPHY
      otheta(i)=oQp(NPHY)+i
   enddo
else
   do i=1,NPHY
      otheta(i)=oQN(NPHY)+i
   enddo
endif

if (Model_ID .eq. NPclosure) then
   oPPt  =otheta(1)+1
   oPAR_ =oPPt     +1
else
   oZ2N  =otheta(NPHY)+1
   oD2N  =oZ2N+1
   oPPt  =oD2N+1
   oPON  =oPPt+1
   oPAR_ =oPON+1
endif
omuAvg   =oPAR_+1

! The diffusion output order must be consistent with the tracer order!
oD_NO3=omuAvg+1
do i=1,NPHY
   oD_PHY(i)=oD_NO3+i
enddo

If (Model_ID .eq. NPclosure) then
    oD_VNO3 = oD_PHY(NPHY)+1
    oD_VPHY = oD_VNO3     +1
    oD_COVNP= oD_VPHY     +1
    Nout    = oD_COVNP
Else
    oD_ZOO  = oD_PHY(NPHY)+1
    if (Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
        oD_ZOO2=oD_ZOO+1
        oD_DET =oD_ZOO2+1
    else
        oD_DET =oD_ZOO+1
    endif
    if (Model_ID==Geiderdisc .or. Model_ID==Geidersimple .or. Model_ID==GeidsimIRON .or. Model_ID==GeiderDroop) then
       do i=1,NPHY
          oD_CHL(i)=oD_DET+1
       enddo
       if (Model_ID == GeiderDroop) then
          do i=1,NPHY
             oD_PHYC(i)=oD_CHL(NPHY)+1
          enddo
          Nout=oD_PHYC(NPHY)
       else
          Nout=oD_CHL(NPHY)
       endif
    else if(Model_ID==NPPZDD .or. Model_ID==EFTPPDD) then
       oD_DET2=oD_DET+1
       Nout=oD_DET2
    else if(Model_ID==EFTcont .or. Model_ID==NPZDcont) then
       oD_DETFe=oD_DET+1
       oD_PMU=oD_DETFe+1
       oD_VAR=oD_PMU+1
       oD_fer=oD_VAR+1
       od2mu =oD_fer+1
       odmudl=od2mu +1
       od3mu =odmudl+1
       od4mu =od3mu +1
       oMESg =od4mu +1
       oMESgMIC=oMESg+1
       odgdl1=oMESgMIC+1
       odgdl2=odgdl1  +1
       od2gdl1=odgdl2 +1
       od2gdl2=od2gdl1+1
       odVAR =od2gdl2 +1
       Nout  =odVAR
    else if(Model_ID==CITRATE3) then
       oD_DETFe=oD_DET+1
       oD_PMU=oD_DETFe+1
       oD_VAR=oD_PMU+1
       oD_MTo=oD_VAR+1
       oD_VTo=oD_MTo+1
       oD_MIo=oD_VTo+1
       oD_VIo=oD_MIo+1
       oD_fer=oD_VIo+1
       od2mu =oD_fer+1
       odmudl=od2mu +1
       odmudT=odmudl+1
       od2mudT2=odmudT+1
       odmudI=od2mudT2+1
       od2mudI2=odmudI+1
       oMESg =od2mudI2 +1
       oMESgMIC=oMESg+1
       odgdl1=oMESgMIC+1
       odgdl2=odgdl1  +1
       od2gdl1=odgdl2 +1
       od2gdl2=od2gdl1+1
       Nout   =od2gdl2
    else if(Model_ID==NPZDN2) then
       oD_DETp=oD_DET +1
       oD_PO4 =oD_DETp+1
       oD_DIA =oD_PO4+1
       Nout   =oD_DIA
    else
       Nout   =oD_DET
    endif
Endif

allocate(Varout(Nout,nlev))
IF (AllocateStatus /= 0) STOP "*** Error in allocating Varout ***"
allocate(Labelout(Nout+ ow ))

Labelout(oTemp  )='Temp'
Labelout(oPAR   )='PAR '
Labelout(oAks   )='Aks '
Labelout(oDust  )='Dust'
Labelout(ow     )='w   '
Labelout(oNO3+ow)='NO3 '
do i=1,NPHY
   write(Labelout(oPHY(i)  +ow),  format_string) 'PHY',i
   write(Labelout(oSI(i)   +ow),  format_string) 'SI_',i
   write(Labelout(oQN(i)   +ow),  format_string) 'QN_',i
   if(N2fix) write(Labelout(oQP(i)+ow), format_string) 'QP_',i
   if (Model_ID .ne. NPclosure) &
   write(Labelout(oLno3(i) +ow),  format_string) 'Lno',i
   write(Labelout(otheta(i)+ow),  format_string) 'The',i
   write(Labelout(oCHL(i)  +ow),  format_string) 'CHL',i
   if (Model_ID .eq. GeiderDroop) then
      write(Labelout(oPHYC(i) +ow),  format_string) 'PHYC',i
   endif
enddo

IF (Model_ID==NPclosure) THEN
    Labelout(oVPHY   + ow) = 'VPHY'
    Labelout(oVNO3   + ow) = 'VNO3'
    Labelout(oCOVNP  + ow) = 'COVNP'
    Labelout(oD_VPHY + ow) = 'D_VP'
    Labelout(oD_VNO3 + ow) = 'D_VN'
    Labelout(oD_COVNP+ ow) = 'DC_NP'
ELSE
    Labelout(oZOO    + ow) = 'ZOO'
    Labelout(oD_DET  + ow) = 'D_DET'
    Labelout(oZ2N    + ow) = 'Z2N'
    Labelout(oD2N    + ow) = 'D2N'
    Labelout(oD_ZOO  + ow) = 'D_ZOO'

    if (Model_ID==NPZDcont .or. Model_ID==CITRATE3) then
        Labelout(oZOO  +ow)='MIC'
        Labelout(oZOO2 +ow)='MES'
    endif
    Labelout(oDET +ow)='DET'
    if (Model_ID==NPPZDD  .or. Model_ID==EFTPPDD) Labelout(oDET2 +ow)='DET2'
    !
    if (Model_ID==NPZDN2) then
        Labelout(oDETp +ow) ='DETp'
        Labelout(oPO4  +ow) ='DIP'  ! Consistent with data file
        Labelout(oPOP  +ow) ='POP'
        Labelout(oDIA  +ow) ='DIA'
        Labelout(oDIAu +ow) ='uDIA'
        Labelout(oD_DETp+ow)='DDETp'
        Labelout(oD_PO4 +ow)='D_DIP'
        Labelout(oD_DIA +ow)='D_DIA'
    endif
    if (Model_ID==EFTcont .or. Model_ID==NPZDcont .or.&
        Model_ID==CITRATE3) then
        Labelout(oDETFe+ow)   ='DETFe'
        Labelout(oPMU  +ow)   ='PMU'
        Labelout(oVAR  +ow)   ='VAR'
        Labelout(odmudl+ow)   ='dmudl'
        Labelout(od2mu +ow)   ='d2mu '
        Labelout(oD_DETFe+ow) ='DDETF'
        if (Model_ID .ne. CITRATE3) then
           Labelout(odVAR +ow)='dVAR'
           Labelout(od3mu +ow)='d3mu'
           Labelout(od4mu +ow)='d4mu'
        else
           Labelout(oD_MIo+ow)='D_MIo'
           Labelout(oMIo  +ow)='MIo'
           Labelout(oMTo  +ow)='MTo'
           Labelout(oVIo  +ow)='VIo'
           Labelout(oVTo  +ow)='VTo'
           Labelout(oD_VIo+ow)='D_VIo'
           Labelout(oD_VTo+ow)='D_VTo'
           Labelout(oD_MTo+ow)='D_MTo'
           Labelout(odmudT+ow)='dmudT'
           Labelout(odmudI+ow)='dmudI'
           Labelout(od2mudT2+ow)='d2mudT2'
           Labelout(od2mudI2+ow)='d2mudI2'
        endif
        Labelout(oD_PMU+ow)='D_PMU'
        Labelout(oD_VAR+ow)='D_VAR'
        if (do_IRON) then
           Labelout(ofer   +ow)='Fer'
           Labelout(odstdep+ow)='DtDep'
           Labelout(oFescav+ow)='Fescv'
           Labelout(oD_fer +ow)='D_Fe'
        endif
    endif
ENDIF
Labelout(oPHYt+ow)='PHY_T'
Labelout(oCHLt+ow)='CHL_T'

do i=1,NPHY
   write(Labelout(omuNet(i) + ow), format_string) 'muN',i
   if (Model_ID .ne. NPclosure) write(Labelout(oGraz(i)  + ow), format_string) 'Gra',i
   write(Labelout(oD_PHY(i) + ow), format_string) 'D_P',i
   if (Model_ID==GeidsimIRON .or.Model_ID==Geiderdisc .or. &
       Model_ID==Geidersimple.or.Model_ID==GeiderDroop) then
      write(Labelout(oD_CHL(i) + ow), format_string) 'DCH',i
   endif
   if (Model_ID==GeiderDroop) then
      write(Labelout(oD_PHYC(i) + ow), format_string) 'DPC',i
   endif
enddo

Labelout(oPPt  + ow)='NPP'
if (oPON > 0) Labelout(oPON  + ow)='PON'
Labelout(oPAR_ + ow)='PAR_'
Labelout(omuAvg+ ow)='muAvg'
Labelout(oD_NO3+ ow)='D_NO3'
if (Model_ID .eq. NPZDcont .or. Model_ID .eq. CITRATE3) then
    Labelout(oD_ZOO + ow)='D_MIC'
    Labelout(oD_ZOO2+ ow)='D_MES'
    Labelout(oMESg  + ow)='MESg '
    Labelout(oMESgMIC+ow)='MEgMI'
    Labelout(odgdl1 + ow)='dgdl1'
    Labelout(odgdl2 + ow)='dgdl2'
    Labelout(od2gdl1+ ow)='d2gd1'
    Labelout(od2gdl2+ ow)='d2gd2'
endif
if(Model_ID==NPPZDD.or.Model_ID==EFTPPDD) Labelout(oD_DET2+ow)='DDET2'
if(Model_ID==Geiderdisc.or.Model_ID==NPZDdisc &
  .or.Model_ID==EFTdisc .or.&
      Model_ID==EFTcont .or.&
      Model_ID==NPZDCONT.or. Model_ID==CITRATE3) then
   do i=1,4
      write(Labelout(oCHLs(i) +ow), format_string) 'CHLs',i
   enddo
endif

if (taskid == 0) then
   do i = 1, Nout+ow
      write(6,*) 'Labelout(',i,') = ',trim(Labelout(i))
   enddo
endif

! Initialize parameters
! Indices for parameters that will be used in MCMC                 
! For EFT models, the affinity approach not used for now
! Need to have tradeoffs for maximal growth rate (mu0) and Kn
! Common parameters:
IF ( Model_ID .ne. NPZDcont.and. Model_ID .ne. EFTsimple .and. Model_ID .ne. NPclosure &
.and. Model_ID.ne.CITRATE3 .and. Model_ID .ne. GeiderDroop) THEN
  imu0    =  1
  igmax   =  imu0  + 1
  iKPHY   =  igmax + 1  
  if (Model_ID == EFT2sp .OR. Model_ID==EFTPPDD .OR. Model_ID==NPZD2sp .OR. Model_ID==NPPZDD) then
    imu0B   =  iKPHY + 1  ! The ratio of mu0 of the second species to the first
    iaI0B   =  imu0B + 1  ! The ratio of aI0 of the second species to the first
    if (Model_ID==NPZD2sp .OR. Model_ID==NPPZDD) then
       ibI0B=  iaI0B  + 1
       imz  =  ibI0B  + 1
    else
       iaI0 =  iaI0B  + 1
       imz  =  iaI0   + 1
    endif
  else if(Model_ID==NPZDN2) then
         imz  =  iKPHY  + 1
  else if(Model_ID==NPZDdisc .or. Model_ID==NPZDFix) then
        imz   =  iKPHY  + 1
  else
      iaI0    =  iKPHY  + 1
      imz     =  iaI0   + 1
  endif

  if (nutrient_uptake .eq. 1) then
     iKN     =  imz    + 1
     if (Model_ID==NPZD2sp .or. Model_ID==NPPZDD) then
        iKN2 =  iKN    + 1
        iQ0N =  iKN2   + 1
     else if (Model_ID==NPZDN2) then
       ! iKP  =  iKN    + 1
       iKPnif=  iKN    + 1
       iLnifp=  iKPnif + 1
       iRDN_P=  iLnifp + 1
        iQ0N =  iRDN_P + 1
     else
        iQ0N =  iKN    + 1
     endif
  elseif (nutrient_uptake.eq.2) then
     if (Model_ID==NPZD2sp .or. Model_ID==NPZDFix .or. Model_ID==NPPZDD .or. Model_ID==NPZDcont .or. Model_ID==NPZDN2) then
        if (taskid==0) write(6,*) 'We do not use affinity-based equation for NPZD model!'
        stop
     endif
     iA0N    =  imz   + 1
     if (Model_ID==EFT2sp .or. Model_ID == EFTPPDD) then
        iA0N2 =iA0N+1   ! The ratio of A0N of the second species to the first  
       ialphaG=iA0N2+1
        iQ0N  =ialphaG+1
     else   
        iQ0N = iA0N + 1
     endif
  endif
  
  if (Model_ID == NPPZDD .or. Model_ID == EFTPPDD) then
     itau   = iQ0N  +1
     iwDET2 = itau  +1
     iwDET  = iwDET2+1
  else
     iwDET  = iQ0N  +1
  endif

  if (Model_ID==NPZDFix .or.Model_ID==NPZD2sp    .or.Model_ID==NPPZDD  &
  .or.Model_ID==NPZDdisc.or.Model_ID==NPZDFixIRON&
  .or.Model_ID==NPZDN2) then
     iaI0_C  =  iwDET    + 1
     if (Model_ID==NPZDFix .or. Model_ID==NPZDN2) then
        NPar = iaI0_C
     else if (Model_ID ==NPZD2sp .or. Model_ID == NPPZDD) then
        iRL2 = iaI0_C + 1
      ialphaG= iRL2   + 1
        NPar = ialphaG
     else if (Model_ID == NPZDFixIRON) then
        iKFe = iaI0_C  + 1
        NPar = iKFe
     else
        ialphamu=iaI0_C+1
        ibetamu =ialphamu+1
        ialphaI =ibetamu+1
        ialphaG =ialphaI
        if (nutrient_uptake.eq.1) then
           ialphaKN=ialphaG+1
             NPar   =ialphaKN
        elseif(nutrient_uptake.eq.2) then
           ialphaA  =ialphaG+1
             NPar   =ialphaA
        endif
     endif
  
  else if(Model_ID==Geiderdisc.or.Model_ID==EFTdisc.or.Model_ID==EFTcont) &
  then
     ialphaI     =iwDET   + 1
     ialphaG     =ialphaI + 1
     ialphamu    =ialphaG + 1
     if (nutrient_uptake.eq.1) then
         ialphaKN   =ialphamu+1
             NPar   =ialphaKN
     elseif(nutrient_uptake.eq.2) then
         ialphaA     =ialphamu+1
              NPar   =ialphaA
     endif
  else if (Model_ID==GeidsimIRON .or. Model_ID==EFTsimIRON) then
    iKFe = iQ0N + 1
    NPar = iKFe
  else if (Model_ID==EFT2sp .or. Model_ID==EFTPPDD) then
    iRL2 = iwDET + 1 ! The grazing preference on the second species (lower grazing impact)
    NPar = iRL2
  else
    NPar = iwDET
  endif
ENDIF

if (taskid==0) write(6,'(I2,1x,A20)') NPar,'parameters in total to be estimated.'
allocate(params(NPar))
allocate(ParamLabel(NPar))

if (imu0 > 0) then
   ParamLabel(imu0) = 'mu0hat '
   params(imu0)     = log(0.8)
endif

if (irhom > 0) then
   ParamLabel(irhom)= 'rhomax'
   params(irhom)    = 1.  !Unit: mol N (mol C)-1 d-1
endif

if (imz > 0) ParamLabel(imz)  = 'mz'

if (igmax > 0) then
   ParamLabel(igmax)= 'gmax'
   params(igmax)    = 1.35
endif

if (iKPHY > 0) then
    ParamLabel(iKPHY)= 'KPHY'
    params(iKPHY)    = 0.25
endif

if (Model_ID .eq. NPZDN2) then
   params(imz)   = 0.15*16d0
elseif (imz > 0) then
   params(imz)   = 0.15
endif

if(Model_ID==EFT2sp .or. Model_ID==EFTPPDD .or.  Model_ID==NPZD2sp .or. Model_ID==NPPZDD) then
   ParamLabel(imu0B)='mu0B'
   params(imu0B)    =0.3
endif

if(Model_ID==NPZDdisc.or.Model_ID==Geiderdisc.or.  &
   Model_ID==EFTdisc .or.Model_ID==EFTcont) then

   ParamLabel(ialphamu) = 'alphamu'
   ParamLabel(ialphaI)  = 'alphaI'

   params(ialphamu) = 0.2
   params(ialphaI ) = -0.1

   if (nutrient_uptake.eq.1) then

     ParamLabel(ialphaKN)= 'alphaKN'
         params(ialphaKN)= 0.27

   else if (nutrient_uptake.eq.2) then
     ParamLabel(ialphaA) = 'alphaA'
     params(ialphaA)     = -0.3
   endif
endif
if (Model_ID.eq.NPZDcont) then
    ParamLabel(ialphaI)='alphaI'
    params(ialphaI)    =-.1
endif
if (Model_ID.eq.NPZD2sp .OR. Model_ID.eq.NPPZDD) then
   ParamLabel(ibI0B)='bI0B'
      params(ibI0B) = -8d0
endif

if (nutrient_uptake .eq. 1) then
  if(iKN > 0) then
  ParamLabel(iKN)  = 'KN'
     params(iKN )  = log(1.2)
  endif
  if (Model_ID .eq. NPZDN2) then
   !ParamLabel(iKP)  = 'KP'
  ParamLabel(iKPnif)= 'KPnif'
   !   params(iKP)   = .05
      params(iKPnif)= 1D-3
  ParamLabel(iLnifp)= 'Lnifp'
      params(iLnifp)= 0.17*16.
      params(iKPHY) = .5/16d0
  ParamLabel(iRDN_P)= 'RDNp'
      params(iRDN_P)= 0.15
  endif
  if (Model_ID .eq. NPZD2sp .or. Model_ID.eq.NPPZDD) then
   ParamLabel(iKN2) = 'KN2'
      params(iKN2)  = 1D0
  endif
else if (nutrient_uptake .eq. 2) then
   ParamLabel(iA0N    ) = 'A0N    '
   params(iA0N)         = 1d-1  ! A0N = 10**params(iA0N)
  if (Model_ID .eq. EFT2sp .or. Model_ID .eq. EFTPPDD) then
     ParamLabel(iA0N2)='A0N2'   
     params(iA0N) = 7d1
     params(iA0N2)= -1d0  ! It is a ratio after log10 transformation
  endif
endif

if (Model_ID .eq. EFT2sp .or. Model_ID .eq. EFTPPDD .or. Model_ID .eq. NPZD2sp .or. Model_ID.eq.NPPZDD) then
   ParamLabel(iaI0B)='aI0B'
   ParamLabel(iRL2)='RL2'
   params(iaI0B)=0.3  ! A ratio after log transformation
   params(iRL2) =0.5
endif

if(Model_ID.eq.NPZD2sp .OR. Model_ID.eq.EFTdisc .OR. &
   Model_ID.eq.EFT2sp  .OR. &
   Model_ID.eq.NPPZDD  .OR. Model_ID.eq.EFTPPDD) then
   ParamLabel(ialphaG)='alphaG'
   params(ialphaG)    =1D-30
endif
!
ParamLabel(iwDET) = 'wDET   '
params(iwDET)     = -1.0  ! wDET = 10**params(iwDET)
!
if (Model_ID == NPPZDD .or. Model_ID == EFTPPDD) then
   ParamLabel(iwDET2)= 'wDET2'
   params(iwDET2)=1d0

   ParamLabel(itau)= 'Tau'
   params(itau)=5D-3
endif
!
if(Model_ID==CITRATE3) then
  ParamLabel(iVTRL)='VTRL'
  params(iVTRL)    =0.08
  ParamLabel(iVTRT)='VTRT'
  params(iVTRT)    =0.01
  ParamLabel(iVTRI)='VTRI'
  params(iVTRI)    =0.08
endif
if (Model_ID==NPclosure) then
  ParamLabel(ibeta)='beta'
  ParamLabel(iIopt)='Iopt'
  ParamLabel(iDp)  ='DPHY'
  params(ibeta)    =log(1.1)
  params(iDp)      =log(0.2)
  params(iIopt)    =log(1d2)  ! log(Iopt)
endif
if(Model_ID==NPZDdisc.or.Model_ID==NPZD2sp &
 .or.Model_ID==NPPZDD.or.Model_ID==NPZDFix &
 .or. Model_ID==NPZDFixIRON .or. Model_ID==NPZDcont &
 .or. Model_ID==NPZDN2      .or. Model_ID==NPclosure) then
  ParamLabel(iaI0_C)='aI0_C'
  params(iaI0_C)    =log(0.055)
  if (Model_ID == NPZDcont) then
     ParamLabel(iVTR)='VTR'
     params(iVTR)    =0.01
   endif
endif

if (iKFe > 0) then
    ParamLabel(iKFe)='KFe'
         params(iKFe)=0.08
endif

if (iQ0N > 0) then
ParamLabel(iQ0N   ) = 'Q0N    '
   params(iQ0N)     = 0.06
endif

if (iaI0 > 0) then
ParamLabel(iaI0    ) = 'aI0'
   params(iaI0   )   = 0.2      ! aI0_Chl, Chl-specific P-I slope
endif

if (Model_ID==NPZDdisc.or.Model_ID==Geiderdisc.or.  &
    Model_ID==EFTdisc) then
    call assign_PMU
endif
end subroutine choose_model
