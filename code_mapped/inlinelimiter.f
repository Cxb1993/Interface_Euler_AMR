c
c
c     =====================================================
      subroutine limiter(maxm,meqn,mwaves,mbc,mx,wave,s,mthlim,
     &                    maux,aux1,aux2,aux3)
c     =====================================================
c
c     # Apply a limiter to the waves.  
c
c
c     # Modified by Mauricio del Razo (maojrs) in 2016 to include 
c     # transmission based limiters and the modified minmod limiter.
c
c     # Version of December, 2002.
c 
c     # Modified from the original CLAWPACK routine to eliminate calls 
c     # to philim.  Since philim was called for every wave at each cell
c     # interface, this was adding substantial overhead in some cases.
c
c     # The limiter is computed by comparing the 2-norm of each wave with
c     # the projection of the wave from the interface to the left or
c     # right onto the current wave.  For a linear system this would
c     # correspond to comparing the norms of the two waves.  For a 
c     # nonlinear problem the eigenvectors are not colinear and so the 
c     # projection is needed to provide more limiting in the case where the
c     # neighboring wave has large norm but points in a different direction
c     # in phase space.
c
c     # The specific limiter used in each family is determined by the
c     # value of the corresponding element of the array mthlim.
c     # Note that a different limiter may be used in each wave family.
c
c     # dotl and dotr denote the inner product of wave with the wave to
c     # the left or right.  The norm of the projections onto the wave are then
c     # given by dotl/wnorm2 and dotr/wnorm2, where wnorm2 is the 2-norm
c     # of wave.
c
      implicit double precision (a-h,o-z)
      dimension mthlim(mwaves)
      dimension wave(meqn, mwaves, 1-mbc:maxm+mbc)
      dimension    s(mwaves, 1-mbc:maxm+mbc)
      
      dimension aux1(maux,1-mbc:maxm+mbc)
      dimension aux2(maux,1-mbc:maxm+mbc)
      dimension aux3(maux,1-mbc:maxm+mbc)

c
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ omegas,omeplas,omewat
      common /param/ rhog,rhop,rhow
c
      do 200 mw=1,mwaves
         if (mthlim(mw) .eq. 0) go to 200
         dotr = 0.d0
         ! Loop over every edge of the cells
         do 190 i = 0, mx+1
            wnorm2 = 0.d0
            dotl = dotr
            dotr = 0.d0
            do 5 m=1,meqn
               wnorm2 = wnorm2 + wave(m,mw,i)**2
               dotr = dotr + wave(m,mw,i)*wave(m,mw,i+1)
    5          continue
            if (i.eq.0) go to 190
            if (wnorm2.eq.0.d0) go to 190
c
            if (s(mw,i) .gt. 0.d0) then
                r = dotl / wnorm2
              else
                r = dotr / wnorm2
            endif
              
            ! Implement limiter choice of theta at interface 
            ! (required for transmission based limiters)
            gammal = aux2(1,i-1)
            gammar = aux2(1,i)
            if ((gammal*gammar .eq. gammagas*gammawat)) then
                ! Calculate sounds speeds and impedances
                ! Densities
                rhol = aux2(4,i-1)
                rhor = aux2(4,i)
                ! Normal velocities
                ul = aux2(5,i-1)/rhol
                ur = aux2(5,i)/rhor
                ! Transverse velocities
                vl = aux2(6,i-1)/rhol
                vr = aux2(6,i)/rhor                
                ! Internal energies
                enel = aux2(7,i-1) 
                ener = aux2(7,i) 
                ! Kinetc energies 
                enekl = 0.5*(ul**2 + vl**2)/rhol
                enekr = 0.5*(ur**2 + vr**2)/rhor
                ! Obtain parameters from aux array
                pinfl = aux3(2,i-1)
                pinfr = aux2(2,i)
                ! Calculate pressures
                pl = (gammal - 1)*(enel - enekl) - gammal*pinfl
                pr = (gammar - 1)*(ener - enekr) - gammar*pinfr
                ! Calculate speeds c
                cl = dsqrt(gammal*(pl + pinfl)/rhol)
                cr = dsqrt(gammar*(pr + pinfr)/rhor)
                ! Calculate impedances
                zl = rhol*cl
                zr = rhor*cr
                
                !  Apply tranmission based limiter (use r=0 for contact discontinuity)
                if (mw .ne. 2) then 
                     !r = 0
                     ! Use wave 1 because we only need the alpha.
                     if (s(mw,i) .gt. 0.d0) then
                         alm = wave(1,mw,i-1)
                         al  = wave(1,mw,i)
                         r = (alm/al)*2*cl/(cl+cr)
                     else
                         al  = wave(1,mw,i)
                         alp = wave(1,mw,i+1)
                         r = (alp/al)*2*cr/(cl+cr) 
                     endif
                else
                    r = 0
                end if

            end if
            
            ! ADDED THIS AS MODIFIED MINMOD
            ! Limiters inside water (remove oscillaions when AMR refinement level is high)
            ! Reduces limiter to a first order TVD limiter in many cases
            ! Mostly required on the non-mapped grid (mapped grids add enough numerical diffusion)
             if (gammal*gammar .eq. gammawat*gammawat) then
                 r = r/3.0
             end if
            
            
c
            go to (10,20,30,40,50) mthlim(mw)
c
   10       continue
c           --------
c           # minmod
c           --------
            wlimitr = dmax1(0.d0, dmin1(1.d0, r))
            go to 170
c
   20       continue
c           ----------
c           # superbee
c           ----------
            wlimitr = dmax1(0.d0, dmin1(1.d0, 2.d0*r), dmin1(2.d0, r))
            go to 170
c
   30       continue
c           ----------
c           # van Leer
c           ----------
            wlimitr = (r + dabs(r)) / (1.d0 + dabs(r))
            go to 170
c
   40       continue
c           ------------------------------
c           # monotinized centered
c           ------------------------------
            c = (1.d0 + r)/2.d0
            wlimitr = dmax1(0.d0, dmin1(c, 2.d0, 2.d0*r))
            go to 170
c
   50       continue
c           ------------------------------
c           # Beam-Warming
c           ------------------------------
            wlimitr = r
            go to 170

c           Need to panfully modify clawpack to implement. Artificial implementation above  
c   60       continue
c           --------
c           # modified minmod (TVD, only first order)
c           --------
c            wlimitr = dmax1(0.d0, dmin1(1.d0, r/3.0))
c            go to 170
            
c
  170       continue
c
c           # apply limiter to waves:
c
            do 180 m=1,meqn
               wave(m,mw,i) = wlimitr * wave(m,mw,i)
  180          continue

  190       continue
  200    continue
c
      return
      end
