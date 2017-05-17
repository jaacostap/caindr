# cshiftwcs - generate file with shift between images of a file
# Author : Jose Acosta (jap@ll.iac.es)
# Version: 7. Apr. 2011
##############################################################################
procedure cshiftwcs(input,output)

string	input	{prompt="List of input images"}
string	output	{prompt="Output file containing shifts"}
bool	verbose	{no,prompt="Verbose"}
bool 	surfcom	{no,prompt="Common area among imput files?"}
bool    chkcom  {no,prompt="Check if there is common area?"} 
bool	addimnam {no,prompt="Add image name to file containing shifts"}
int 	accuracy{2,prompt="Number of decimal digits"}
int 	xmin	{1,prompt="Minimal absice of common area"}
int 	ymin	{1,prompt="Minimal ordinate of common area"}
int	xmax	{256,prompt="Maximal absice of common area"}
int 	ymax	{256,prompt="Maximal ordinate of common area"}
#bool	view	{prompt="View comun area of images"}

string *list1	{prompt="Ignore this parameter (list1)"}

begin
  string	ini,ino
  string	fname,camera
  file		tmpl,tf1 
  real		pixscl
  real		x,y,xr,yr,ref_ra,ref_dec,tel_ra,tel_dec
  real		xoff,yoff,xoff_ref,yoff_ref
  real		dra,ddec,accu,rdiv
  real		xs,ys,xd,yd
  int           nxaxis1,nxaxis2
  int		x1,x2,y1,y2
  int           icam = 0
  int		icam_first
  bool		first,addim1

  surfcom = yes  
  addim1 = addimnam
  
  # Control if we check the first image
  first = yes
  ini = input
  
  # Create output list file, delete if already exists
  tf1 = output
  delete(tf1,yes,verify=no, >>& "/dev/null")
  
  # expand input image names.
  tmpl = mktemp("_cshftwcstmpl")
  sections(ini,option="fullname",> tmpl)
  list1 = tmpl

  While ( fscan(list1,fname) != EOF )
    {
    ## determine offset. even if images are cubes only one shift value will be determined
    imgets(fname,"CAMERA")
    camera = imgets.value
    if (camera == "W") 
         icam = 1
    if (camera == "N") 
         icam = 2
      
    # find position telescope was pointing at
    #imgets (image=fname, param="RA") 
    ## use CRVAL1 instead of RA, Dec because are more accurate 
    imgets (image=fname, param="CRVAL1")
    tel_ra = real(imgets.value)
    #imgets (image=fname, param="DEC")
    imgets (image=fname, param="CRVAL2")
    tel_dec = real(imgets.value)
            
    # conversion factor degrees to radian: PI/180 = 0.017453293
    # conversion factor degrees to hours: 1/15
    ## tel_ra = 15.* tel_ra

    if ( first )
      {
      icam_first = icam
      # determine scale in degrees/pixel
      switch (icam) { 
         case 1: pixscl = 2.777e-4 
         case 2: pixscl = 1.111e-4 
         default: ierr = 1
      }

      xmin = 1
      imgets (image=fname, param="i_naxis1")
      nxaxis1 = int(imgets.value) 
      xmax =  nxaxis1 
      ymin = 1
      imgets (image=fname, param="i_naxis2")
      nxaxis2 = int(imgets.value)
      ymax = nxaxis2 
      
      
      # store position telescope was pointing at as reference
      ref_ra = tel_ra
      ref_dec = tel_dec
      
      if (verbose)
        print ("reference RA: ",ref_ra,"reference DEC: ",ref_dec)
      
      # set smart track error budget to zero
      xd = 0
      yd = 0
      if (addim1)
	   print(fname," 0. 0.", >> tf1)
      else
      	   print("0. 0.", >> tf1)
      first = no
      }
    else #if (!first)
      {
      if (verbose)
        {
           print ("Coordinates for frame ",fname)
           print ("RA: ",tel_ra,"DEC: ",tel_dec)
        }
	
      # check CAMERA is the same
      if (icam != icam_first) 
	  ierr = 1
      
      # Determine shift
      dra  = (tel_ra - ref_ra)*cos(ref_dec*3.1415/180)
      ddec = (tel_dec - ref_dec)

      # This position correspond for u=-y and v=-x)
      x =  dra/pixscl 
      y = - ddec/pixscl 
	
      # check limits
      if ( x >= 0 && x > xmin ) xmin = x
      if ( x < 0  && nxaxis1+x < xmax ) xmax = nxaxis1+x
      if ( y >= 0 && y > ymin ) ymin = y
      if ( y < 0  && nxaxis2+y < ymax ) ymax = nxaxis2+y
      #print ("After check x ",x,"; xmin ",xmin,"; xmax ",xmax)
	
      # test if the images have a common surface
      if ( xmin >= xmax || ymin >= ymax )
        {
        xmin = 0.
        ymin = 0.
        xmax = 0.
        ymax = 0.
        surfcom = no
	if (chkcom)
	   break
        }
      
      # round to three decimal places
      accu = accuracy
      rdiv = 10.**accu
      xs = real (nint (x * rdiv)) / rdiv
      ys = real (nint (y * rdiv)) / rdiv
 
      if (verbose)
        print("Auto       : x="//xs//" y="//ys)
      
      if (addim1)
	  print(fname," ",xs//" "//ys, >> tf1)
      else    
	  print(xs//" "//ys, >> tf1)
	
      } # end of else of if (first) 
    } # end while ( fscan(list1,fname) != EOF )
   
  
       
  delete(tmpl,yes,verify=no)
  
  list1 = ""
    
end
