def  dscramble_frame(image):
  
  quad_size = 128*128L
  quad1lin = lonarr(quad_size)
  quad2lin = lonarr(quad_size)
  quad3lin = lonarr(quad_size)
  quad4lin = lonarr(quad_size)

  ## fill 1-D arrays
  for i=0,127 do begin
    i0 = i*128
    i1 = i0+127 
    quad1lin(i0:i1) = reverse(im[0:127,128+i])
    quad2lin(i0:i1) = reverse(im[128:255,128+i])
    quad3lin(i0:i1) = reverse(im[128:255,i])
    quad4lin(i0:i1) = reverse(im[0:127,i])
  endfor 

  ## now shift pixels
  
  ## reshape to 2-D array
  
  
def fixcentcol(image):
    
    
from astropy.io import fits 

## read fits cube


## correct each frame of the cube


## write the corrected cube       
  
  
  