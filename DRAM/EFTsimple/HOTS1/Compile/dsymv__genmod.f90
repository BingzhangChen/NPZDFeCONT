        !COMPILER-GENERATED INTERFACE MODULE: Tue Oct 10 17:22:58 2017
        MODULE DSYMV__genmod
          INTERFACE 
            SUBROUTINE DSYMV(UPLO,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
              INTEGER(KIND=4) :: LDA
              CHARACTER(LEN=1) :: UPLO
              INTEGER(KIND=4) :: N
              REAL(KIND=8) :: ALPHA
              REAL(KIND=8) :: A(LDA,*)
              REAL(KIND=8) :: X(*)
              INTEGER(KIND=4) :: INCX
              REAL(KIND=8) :: BETA
              REAL(KIND=8) :: Y(*)
              INTEGER(KIND=4) :: INCY
            END SUBROUTINE DSYMV
          END INTERFACE 
        END MODULE DSYMV__genmod
