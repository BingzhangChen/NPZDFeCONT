        !COMPILER-GENERATED INTERFACE MODULE: Tue Oct 10 17:23:06 2017
        MODULE CALCYSSE__genmod
          INTERFACE 
            SUBROUTINE CALCYSSE(PARS,MODVAL,SSQE)
              USE MOD_1D
              REAL(KIND=8), INTENT(IN) :: PARS(NPAR)
              REAL(KIND=8), INTENT(OUT) :: MODVAL(ANOBS)
              REAL(KIND=8), INTENT(OUT) :: SSQE(NDTYPE*2)
            END SUBROUTINE CALCYSSE
          END INTERFACE 
        END MODULE CALCYSSE__genmod
