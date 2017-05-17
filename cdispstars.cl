# cdispstar - acquire star coordinates interactivly in 2D-images
# Author : Miguel Charcos (mcharcos@ll.iac.es)
# Version: 3. Oct. 2003
# Modified by J. Acosta Oct 2004 to avoid presenting all images
# in manual mode. Only one the first exposure after changing of dithern point
# will be marked.
##############################################################################
procedure cdispstars (input, outstars)

string 	input		{prompt="List of input images"}
string	outstars	{prompt="File of position stars in the reference image"}
string 	outshift	{"",prompt="Shift file  result of reference star"}
string	shiftf		{"",prompt="File containing image shifts"}
real	xmin		{INDEF,prompt="Xmin of the common area"}
real	ymin		{INDEF,prompt="Ymin of the common area"}
real	xmax		{INDEF,prompt="Xmax of the common area"}
real	ymax		{INDEF,prompt="Ymax of the common area"}
bool    zscale		{yes,prompt="display range of greylevels near median?"}
bool	zrange		{no,prompt="display full image intensity range?"}
real	z1		{prompt="minimum grey level to be displayed"}
real	z2              {prompt="maximum grey level to be displayed"}
string	tmpdir		{")_.tmpdir",prompt="Temporary directory"}
int 	checkbox	{0,prompt="Box where would be point in other images"}
bool   	verbose	     	{yes,prompt="Verbose output?"}
			

string *list1	{prompt="Ignore this parameter(list1)"}
string *list2	{prompt="Ignore this parameter(list2)"}
string *list3	{prompt="Ignore this parameter(list3)"}

begin
  
  string	ini,isi,shiftaux
  string	fname,dispimg
  string 	tfstar,tf2,tmpl
  string	key
  real		x,y,xr,yr,xs,ys,xslast,yslast,_z1,_z2
  real		xstar,ystar,xminbox,xmaxbox,yminbox,ymaxbox
  real		dimx,dimy		
  int		nst,nsc
  bool		searchshift,first,check,manual,delshiftaux,markstarhere
  bool		_zscale, _zrange
  # --------------------------------------------------------------------
  # Verifications
  # --------------------------------------------------------------------
  if (verbose)
    {
    print ""
    print "verification of variables"
    }
    
  _zscale = zscale
  _zrange = zrange
  _z1 = z1 
  _z2 = z2
    
  ini = input
    
  # expand input image names.
  tmpl = mktemp(tmpdir//"idsptmpl")
  files(ini,> tmpl)
  # make sure we have some input files ... bail out if we don't
  first=yes
  list1=tmpl
#  while (fscan(list1, fname) != EOF)
#    {
#    imgaccess(fname, verbose=no)
#    print("INFO: image to use in idispstars ",fname)
#    if ( imgaccess.exists ) 
#     {
#      if (first)
#        {
#	print("INFO: ",fname," is the reference image")
#        first = no
#	}	
#      break
#      }
#    }


#  if ( first )
#    {
#    beep
#    print("")
#    print("ERROR: no input files found.")
#    print("idispstars aborted")
#    print("")
#    beep
#    bye
#    }

  xs = 0 
  ys = 0 
  
  if ( !access(shiftf) ) 
    {
    delshiftaux = yes
    shiftaux = mktemp(tmpdir//"ldispstarsshiftaux")
    if (verbose) {print"INFO: no input shift file introduced"}
    list1 = tmpl
    while (fscan(list1, fname) != EOF)
      {print("0 0",>>shiftaux)}
    }
  else 
    {
    delshiftaux = no
    shiftaux=shiftf
    }

  list1 = tmpl
  nsc = fscan(list1, fname)
  if ( fscan(list1, fname) == EOF )
    {
    print("")
    print("WARNING: only one input files found.")
    print "only star position sky treatment"
    searchshift = no
    print("")
    }
  else {searchshift = yes}
  
    check = no 
    if (verbose) {print "INFO: No visualisation for the comon area"}
  
  if (outshift == "")
    {
    if (verbose) {print "INFO: No shift image calculated"}
    manual = no
    }
  else if (access(outshift))
    {
    beep
    print("")
    print("ERROR: operation would override output outshift file "//outshift)
    print("idispstar aborted")
    print("")
    beep
    bye
    }
  else
    {
    if (verbose) {print "INFO: Shift image calculation using reference star"}
    manual = yes
    tf2 = outshift
    }
  
  if (access(outstars))
    {
    beep
    print("")
    print("ERROR: operation would override output outstars file "//outstars)
    print("idispstar aborted")
    print("")
    beep
    bye
    }
  else {tfstar = outstars}
  
  if (verbose)
    {
    print ("variables verified")
    print ""
    }
  # --------------------------------------------------------------------
  # End of verifications
  # --------------------------------------------------------------------


  # --------------------------------------------------------------------
  #  Determination of reference stars. Interaction with user
  # --------------------------------------------------------------------
  
  # Work through list of substracted pre read images 
  first = yes
  list1 = tmpl
  list2 = shiftaux
  while (fscan(list1, fname) != EOF)
    { 
    #check if we should subtract a user defined sky image
    
    dispimg = fname
    
    imgets(image=fname,param="i_naxis1")
    dimx = int(imgets.value)
    imgets(image=fname,param="i_naxis2")
    dimy = int(imgets.value)
    
    
    # Number of reference stars
    nst = 0
    
    # check if we need to get the offset manually
    # if we do, we need to display the frame, read the image cursor,
    # centroid and remember the coordinates for input to imcombine
    if (manual)
      {
      # mark area for star to be picked
      
      
      if ( first )
        {
        # the image has to be displayed
        display(dispimg,1,zscale=_zscale,zrange=_zrange,z1=_z1,z2=_z2)
	if ( check )
          {
          nsc=fscan(list2)
          x = xmin + (xmax - xmin) / 2.
          y = ymin + (ymax - ymin) / 2.
          print(int(x)//" "//int(y)) | tvmark (frame=1,\
          	coords="STDIN",\
          	mark = "rectangle",\
          	lengths = int(xmax - xmin)//" "//(ymax-ymin)/(xmax-xmin),\
          	color = 205,\
          	interactive = no )
          }
	
	  
	# print usage information  
	print ""
        print " *** You are marking stars in the reference image"
        print " *** please mark a reference star present in all images. Use 'm'"
        print ""
	
        key = ""
        while ( key != "m" )
          {
          cmarkstar(input=dispimg, verbose=yes)
          key = cmarkstar.key
          if ( key == "m" )
            {           
            xr = cmarkstar.x
            yr = cmarkstar.y
	    xslast = 0.
	    yslast = 0.
	    print(xr," ",yr,>>tfstar)
	    print("0 0",>>tf2)
	    nst = 1
	    print(int(xr+0.5)//" "//int(yr+0.5)) | tvmark (frame=1,\
                coords="STDIN",\
                mark = "cross",\
                color = 205,\
                interactive = no )
	    }
	  }
        
	# print usage information  
	print ""
        print " *** Now you can select other reference stars"
        print " *** please mark star using 'm'" 
	print " *** when you will finished press 'q'"
	print ""
	
	key = ""
	while ( key != "q" )
          {
          cmarkstar(input=dispimg, verbose=yes)
          key = cmarkstar.key
          if ( key == "m" )
            {           
	    print("reference star number ",nst)
	    print((cmarkstar.x)," ",(cmarkstar.y), >>tfstar)
	    nst = nst + 1
	    print(int(cmarkstar.x+0.5)//" "//int(cmarkstar.y+0.5)) | tvmark (frame=1,\
                coords="STDIN",\
                mark = "cross",\
                color = 205,\
                interactive = no )
	    }
	  else if ( key == "q" )
	    {
	    print ("INFO: You have selected ",nst, "reference stars")
	    break
	    }
	  else
	    beep	    
	  }
	first = no
	} # end of if (first)
      
      # if (!first)
      else 
        { 
	markstarhere  = yes  	
	# check if the difference in pixels between the expected position
	# and the last position are within the boxsize
#	  nsc=fscan(list2,xs,ys)
#	  print ("nsc ",nsc)
#	  print ("xs =",xs,"  xslast=",xslast)
#	  print ("ys =",ys,"  yslast=",yslast)
#	if ((abs(xs - xslast) <= checkbox) && (abs(ys - yslast) <= checkbox) ) 
#	   { 
#	   # use the last x,y positions as initial shift
#	   markstarhere = no
#	   printf("%d  %d\n",(xslast+0.5),(yslast+0.5), >> tf2)	      
#	   }
	   ## print (markstarhere) 
	# mark area for star to be picked and initial star position picked
        if (markstarhere) 
	  { 
          # the image has to be displayed
          display(dispimg,1,zscale=_zscale,zrange=_zrange,z1=_z1,z2=_z2)
	  
	    x = xr 
	    y = yr 
	    print(int(x)//" "//int(y)) | tvmark (frame=1,\
                  coords="STDIN",\
                  mark = "rectangle",\
                  lengths = checkbox//" "//1,\
                  color = 205,\
                  interactive = no )
	    print(int(xr)//" "//int(yr)) | tvmark (frame=1,\
                  coords="STDIN",\
                  mark = "cross",\
                  color = 205,\
                  interactive = no )

	    list3 = tfstar
	    While (fscan(list3,xstar,ystar) != EOF)
	      {
	      x = xstar - xs
	      y = ystar - ys
	      print(int(x)//" "//int(y)) | tvmark (frame=1,\
                  coords="STDIN",\
                  mark = "circle",\
                  radii = checkbox/2,\
                  color = 205,\
                  interactive = no )
	      }

	  key = ""
	  print ""
	  print " *** please mark main reference star with 'm'"
	  print ""
	  while ( key != "m" )
            {
	    cmarkstar(input=dispimg, verbose=yes)
            key = cmarkstar.key
	    if ( key == "m")
	      {
              ## E:modificado jap
	      xslast = xr-cmarkstar.x
	      yslast = yr-cmarkstar.y
	      printf("%d  %d\n",(xr-cmarkstar.x+0.5),(yr-cmarkstar.y+0.5), >> tf2)
              ## F:modificado jap
              break
	      }
	    } # end of while key != "m"
          } # end of if markstarhere  
        }  # end of else -> not first
      }  # end of if (manual)
    # check if we only need to get the first offset manually
    # if we do, we need to display the frame, read the image cursor,
    # centroid and remember the coordinates for input to imcombine.
    # For all the other images we need to calculate the shift from the offset
    # and then centroid for better accuracy.
    else # if (!manual)  --> selected when pick1
      {
      if ( first )
        {
        nsc=fscan(list2)
        # display image
        display(dispimg,1,zscale=_zscale,zrange=_zrange,z1=_z1,z2=_z2)
        # mark area for star to be picked
        if ( check )
          {
          x = xmin + (xmax - xmin) / 2.
          y = ymin + (ymax - ymin) / 2.
          print(int(x)//" "//int(y)) | tvmark (frame=1,\
                coords="STDIN",\
                mark = "rectangle",\
                lengths = int(xmax - xmin)//" "//(ymax-ymin)/(xmax-xmin),\
                color = 205,\
                interactive = no )
          }
        
	# print usage information  
	print ""
        print " *** Select reference stars (at least one star)"
        print " *** please mark stars with 'm'" 
	print " *** when you will finished press 'q'"
	print ""
	
	key = ""
	while ( key != "q" )
          {
          cmarkstar(input=dispimg, verbose=yes)
          key = cmarkstar.key
          if ( key == "m" )
            {           
           xr = cmarkstar.x
           yr = cmarkstar.y
	   print(xr," ",yr, >>tfstar)
	   print("reference star number ",nst)
	   print(int(xr)//" "//int(yr)) | tvmark (frame=1,\
                coords="STDIN",\
                mark = "cross",\
                color = 205,\
                interactive = no )
	   nst = nst + 1
	    }
	  else if ( key == "q" )
	    {
	    if (nst == 0)
	      {
	      print ("WARNING: You must select at least one star")
	      key = ""
	      }
	    else
	      {
	      print ("INFO: You have selected ",nst, "reference stars")
	      break
	      }
	    }
	  else
	    beep	    
	  }
	first = no  
        }  # end of if (first)
	else
	  {
	  if (check && checkbox != 0)
	    {
	    print ""
	    print " *** when you will finished of examine image press 'q'"
	    print ""
	    # display image
            display(dispimg,1,zscale=_zscale,zrange=_zrange,z1=_z1,z2=_z2)
            
            nsc=fscan(list2,xs,ys)
	    xminbox = xmin - xs
	    xmaxbox = xmax - xs
	    yminbox = ymin - ys
	    ymaxbox = ymax - ys
	
	    if (xminbox <=0) {xminbox = 1}
	    if (yminbox <=0) {yminbox = 1}
	    if (xmaxbox >dimx) {xmaxbox = dimx}
	    if (ymaxbox >dimy) {ymaxbox = dimy}
	
            # Mark common area
	    x = xminbox + (xmaxbox - xminbox) / 2.
            y = yminbox + (ymaxbox - yminbox) / 2.
            print(int(x)//" "//int(y)) | tvmark (frame=1,\
            	  coords="STDIN",\
            	  mark = "rectangle",\
            	  lengths = int(xmaxbox - xminbox)//" "//(ymaxbox-yminbox)/(xmaxbox-xminbox),\
            	  color = 205,\
            	  interactive = no )
	    
	    # Mark estimated position of star
	    list3 = tfstar
	    While (fscan(list3,xstar,ystar) != EOF)
	      {
	      x = xstar - xs
	      y = ystar - ys
	      print(int(x)//" "//int(y)) | tvmark (frame=1,\
                  coords="STDIN",\
                  mark = "circle",\
                  radii = checkbox/2,\
                  color = 205,\
                  interactive = no )
	      }
            cmarkstar(input=dispimg, verbose=no)
	    }
	  else
	    {
	    break
	    }
	  }
      }   # end of else [!manual]
	
    }  # end of while (fscan(list1, fname) != EOF)

  # --------------------------------------------------------------------
  #  End of determination of reference stars. 
  # --------------------------------------------------------------------
   
  if (delshiftaux) delete (shiftaux,yes,ver-)
  delete (tmpl,yes,ver-, >>&"/dev/null")
  
  list1 = ""
  list2 = ""
  list3 = ""
  
end
