! RING INCLUSION MAPPING FROM COMPUTATIONAL TO PHYSICAL DOMAIN FUNCTION
! Mauricio del Razo's extension of the paper:
! D. A. Calhoun, C. Helzel, and R. J. LeVeque, Logically rectangular grids and finite volume
! methods for pdes in circular and spherical domains, SIAM review, (2008), pp. 723-752.
! Changes here have to also be included in mapc2p.py
     
  !=====================================================
  subroutine mapc2p(xc,yc,xp,yp,rsqr,rcirp,routp)
  !=====================================================
     ! Maps unit square to square grid of rdius rsqr
     ! with anulus inclusion in the ring rcir and rout
     ! rsqr = r2, rcir = inner circle, rout = outer circle
     ! on input,  (xc,yc) is a computational grid point
     ! on output, (xp,yp) is corresponding point in physical space

     implicit none
     REAL (kind=8)   :: xc,yc,xp,yp,rsqr,rcirp,routp
     REAL (kind=8)   :: dd,D,R,center,rat,rat2
     
     REAL (kind=8)   :: xci,yci,xsqr,rcir,rout

     
    !# Get local variables from global
    rcir = rcirp
    rout = routp
     
    ! If outside of square of radius xsqr, do nothing to the grid
    xsqr = 1.0*rsqr
    if (dabs(xc) .ge. xsqr .or. dabs(yc) .ge. xsqr) then
    	xp = 1.0*xc
    	yp = 1.0*yc
    else

		! Scale computational grid accordingly, map xsqr to unit square
		xci = xc/xsqr
		yci = yc/xsqr
		  
		! Calculate D,R, center for inner, middle and outer region
		dd = max(dabs(xci),dabs(yci),1e-10)
		dd = min(0.999999,dd)
		D = rsqr*dd/dsqrt(2.d0)
		rat = rcir/rsqr
		rat2 = rout/rsqr
		if (dd .le. rat) then ! Can use 0.5 instead
		    R = rcir 
		else if (dd .le. rat2) then ! Can use 0.75 instead
		    R =  rsqr*dd
		else
		    R = rout*((1.d0-rat2)/(1-dd))**(1.d0/rat2 + 1.d0/2.d0)
		    D = rout/dsqrt(2.d0) + (dd-rat2)*(rsqr-rout/dsqrt(2.d0))/(1.d0-rat2)
		end if
		center = D - dsqrt(R**2 - D**2)

		! Do mapping (see paper) Have two do for the 3 sections from the diagonals
		xp = (D/dd)*dabs(xci)
		yp = (D/dd)*dabs(yci)
		if (dabs(xci) .ge. dabs(yci)) then
		    xp =  center + dsqrt(R**2 - yp**2)
		else if (dabs(yci) .ge. dabs(xci)) then
		    yp = center + dsqrt(R**2 - xp**2)
		end if
	  
		! Give corresponding sign
		xp = dsign(xp,xci)
		yp = dsign(yp,yci)
		
		! Uncomment to return no mapped grid at all 
		!xp = 1.0*xc
		!yp = 1.0*yc
      end if
     return
     end   
