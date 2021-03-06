c
c     =====================================================
       subroutine qinit(meqn,mbc,mx,my,xlower,ylower,
     &                   dx,dy,q,maux,aux)
c     =====================================================
c
c     # Set initial conditions 
c     # for q (density, momentum x, momentum y and energy).
c
       implicit double precision (a-h,o-z)
       dimension q(meqn,1-mbc:mx+mbc,1-mbc:my+mbc)
       dimension aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)
       dimension p(1-mbc:mx+mbc)
       dimension dist(500), pressure(500)
       

       common /param/ gammagas, gammaplas, gammawat
       common /param/ pinfgas,pinfplas,pinfwat
       common /param/ omegas,omeplas,omewat
       common /param/ rhog,rhop,rhow
       common /param/ dx2,dy2

       dx2 = 1.0*dx
       dy2 = 1.0*dy
       pi = 4.d0*datan(1.d0)

      ! Write initial conditions
      p0 = 101325.d0 ! atmospheric pressure
      p = p0      
      c0 = sqrt(gammagas*p0/rhog) 
      
      ! Defines jump in energies to make pressure equal accross interfaces using Tammann EOS
      ! Steady state gas Energy
      Egas0 = (p0 + gammagas*pinfgas)/(gammagas - 1.d0)  
      ! Energy in water/plastic in gas-water-plastic interface arrangement
      EgwpWat = (Egas0*(gammagas - 1.d0) - gammagas*pinfgas
     & + gammawat*pinfwat)/(gammawat - 1.d0)         
      EgwpPlas = (EgwpWat*(gammawat - 1.d0) - gammawat*pinfwat
     & + gammaplas*pinfplas)/(gammaplas - 1.d0)   
      ! Energy in water/plastic in gas-plastic-water interface arrangement
      EgpwPlas = (Egas0*(gammagas - 1.d0) - gammagas*pinfgas
     & + gammaplas*pinfplas)/(gammaplas - 1.d0)         
      EgpwWat = (EgpwPlas*(gammaplas - 1.d0) - gammaplas*pinfplas
     & + gammawat*pinfwat)/(gammawat - 1.d0)   
      
      ! Set initial conditions in computational grid 
      !(constant pressure p0 everywhere and across interfaces)
      do 150 i=1-mbc,mx+mbc
        xcell = xlower + (i-0.5d0)*dx
        do 151 j=1-mbc,my+mbc
          ycell = ylower + (j-0.5d0)*dy
          p(i) = p0
          ! Adjust initial conditions depending if it's gas,PS or water
          if (aux(1,i,j) == gammagas) then
            q(1,i,j) = rhog*(p(i)/p0)**(1/gammagas)
            q(2,i,j) = (2/(gammagas - 1.0))*(-c0 + 
     & sqrt(gammagas*p(i)/q(1,i,j)))
            q(3,i,j) = 0.d0
            !q(2,i,j) = 0.d0
            q(4,i,j) = (p(i) + gammagas*pinfgas)/(gammagas - 1.0) +
     & (q(2,i,j)**2 + q(3,i,j)**2)/(2.0*q(1,i,j))
     
         else if (aux(1,i,j) == gammaplas) then
            q(1,i,j) = rhop
            q(2,i,j) = 0.d0
            q(3,i,j) = 0.d0
            ! make sure pressure jump is zero across interface using SGEOS (check correct order of interfaces)
            q(4,i,j) = 1.d0*EgwpPlas
     
         else if (aux(1,i,j) == gammawat) then
            q(1,i,j) = rhow
            q(2,i,j) = 0.d0
            q(3,i,j) = 0.d0
            ! make sure pressure jump is zero across interface using SGEOS (check correct order of interfaces)
            q(4,i,j) = 1.d0*EgwpWat

          end if
  151    continue	  
  150  continue
       return
       end

