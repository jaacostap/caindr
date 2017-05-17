# iacirc.cl -- Script to set up tasks in the IACIRC package
#                        
#

if (caindr.motd) 
 type caindr$caindr.motd
;
 
#Load the necessary packages

#digiphotx

#daophotx

#artdata
#stsdas.motd=no
#stsdas
#stsdas.motd=yes
#analysis
#dither

nproto

package caindr

task csubditsky  = caindr$csubditsky.cl
task csubditsky_quad  = caindr$csubditsky_quad.cl
task csuboffsky  = caindr$csuboffsky.cl
task cbadpix     = caindr$cbadpix.cl
task cmkflat     = caindr$cmkflat.cl
task coverview   = caindr$coverview.cl
task calldiff    = caindr$calldiff.cl
task ctotreduc   = caindr$ctotreduc.cl

task cicomb_cub  = caindr$cicomb_cub.cl

task cstatistic  = caindr$cstatistic.cl

task cdispstars  = caindr$cdispstars.cl
task cmarkstar   = caindr$cmarkstar.cl
task cimcentroid = caindr$cimcentroid.cl

task cshiftwcs   = caindr$cshiftwcs.cl 


task cflatcub = caindr$cflatcub.cl

task ccnoicor = caindr$ccnoicor.cl
task cremsurf = caindr$cremsurf.cl

task cstackcube = caindr$cstackcube.cl

task cwcsedit  = caindr$cwcsedit.cl

# The following tasks are hidden tasks

#task finout  = iacircx$src/finout.cl
#task irheadup = iacircx$src/irheadup.cl
#hidetask finout
#hidetask irheadup

task cfilename = caindr$cfilename.cl
hidetask cfilename


keep


clbye()
