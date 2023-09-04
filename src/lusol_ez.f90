!*****************************************************************************************
!>
!  Wrapper for LUSOL. Will eventually be moved into a separate repo.

    module lusol_ez_module

    use lusol,           only: lu1fac, lu6sol
    use lusol_precision, only : ip, rp

    implicit none

    private

    public :: solve

    contains
!*****************************************************************************************

!*****************************************************************************************
!>
!  Wrapper for [[lu1fac]] + [[lu6sol]] to solve a linear system `A*x = b`.

    subroutine solve(n_cols,n_rows,n_nonzero,irow,icol,mat,b,x,istat)

    integer,intent(in) :: n_cols !! number of columns in A.
    integer,intent(in) :: n_rows !! number of rows in A.
    integer,intent(in) :: n_nonzero !! number of nonzero elements of A.
    integer,dimension(:),intent(in) :: irow, icol !! sparsity pattern (size is `n_nonzero`)
    real(rp),dimension(:),intent(in) :: mat !! matrix elements (size is `n_nonzero`)
    real(rp),dimension(:),intent(in) :: b !! right hand side (size is `m`)
    real(rp),dimension(:),intent(out) :: x !! solution !size is `n`
    integer,intent(out) :: istat !! status code

    integer(ip) :: nelem, n, m
    integer(ip) :: lena
    real(rp),dimension(:),allocatable :: a
    integer(ip),dimension(:),allocatable :: indc
    integer(ip),dimension(:),allocatable :: indr
    real(rp),dimension(:),allocatable :: w
    real(rp),dimension(:),allocatable :: v
    integer(ip) :: inform
    integer(ip) :: luparm(30)
    real(rp) :: parmlu(30)
    integer(ip),dimension(:),allocatable :: p, q,  &
                                            lenc, lenr,  &
                                            iploc, iqloc,  &
                                            ipinv, iqinv,  &
                                            locc, locr

    integer(ip),parameter :: nout = 6
    integer(ip),parameter :: lprint = 0
    integer(ip),parameter :: maxcol = 5
    integer(ip),parameter :: method = 0 ! TPP
    integer(ip),parameter :: keepLU = 1

    real(rp),parameter :: Ltol1 = 100.0_rp
    real(rp),parameter :: Ltol2 = 10.0_rp
    real(rp),parameter :: small = epsilon(1.0_rp)**0.8_rp
    real(rp),parameter :: Utol1 = epsilon(1.0_rp)**0.67_rp
    real(rp),parameter :: Utol2 = epsilon(1.0_rp)**0.67_rp
    real(rp),parameter :: Uspace = 3.0_rp
    real(rp),parameter :: dens1 = 0.3_rp
    real(rp),parameter :: dens2 = 0.5_rp

    integer(ip) :: mode = 5 ! for [[lu6sol]] : `w` solves `A w = v`.

    n = n_cols
    m = n_rows
    nelem = n_nonzero
    lena = 1 + max( 2*nelem, 10*m, 10*n, 10000 )

    allocate(a(lena))
    allocate(indc(lena))
    allocate(indr(lena))
    associate (n =>n_cols, m => n_rows)
        allocate(p(m)    , q(n)    , &
                 lenc(n) , lenr(m) , &
                 iploc(n), iqloc(m), &
                 ipinv(m), iqinv(n), &
                 locc(n) , locr(m))
        allocate(w(n_cols))
    end associate

    allocate(w(n_rows)) ! x
    allocate(v(n_cols)) ! b

    a = 0; indc=0; indr=0
    a(1:nelem) = mat
    indc(1:nelem) = irow    ! check these...seems to be right based on the comment
    indr(1:nelem) = icol    !

    ! settings (whould be inputs)
    luparm = 0
    luparm( 1) = nout
    luparm( 2) = lprint
    luparm( 3) = maxcol
    luparm( 6) = method
    luparm( 8) = keepLU

    parmlu = 0
    parmlu( 1) = Ltol1
    parmlu( 2) = Ltol2
    parmlu( 3) = small
    parmlu( 4) = Utol1
    parmlu( 5) = Utol2
    parmlu( 6) = Uspace
    parmlu( 7) = dens1
    parmlu( 8) = dens2

    call lu1fac( m    , n    , nelem, lena , luparm, parmlu, &
                 a    , indc , indr , p    , q     ,         &
                 lenc , lenr , locc , locr ,                 &
                 iploc, iqloc, ipinv, iqinv, w     , inform )

    write(*,*) 'lu1fac inform = ', inform

    v = b ! right hand side

    call lu6sol( mode, m, n, v, w,       &
                 lena, luparm, parmlu,   &
                 a, indc, indr, p, q,    &
                 lenc, lenr, locc, locr, &
                 inform )

    write(*,*) 'lu6sol inform = ', inform

    x = w ! solution
    istat = int(inform)

    end subroutine solve
!*****************************************************************************************

!*****************************************************************************************
    end module lusol_ez_module
!*****************************************************************************************