# lstatist - return statistic values of input image 
# Author : Miguel Charcos (mcharcos@ll.iac.es)
# Version: 09. Feb. 2004
##############################################################################
procedure cstatistic(image)

string	image		{prompt="Input image(s)"}
real	nsigrej		{5.,min=0.,prompt="Number of sigmas for limits"}
int	maxiter		{10,min=1,prompt="Maximum number of iterations"}
bool	print		{yes,prompt="Print final results?"}
bool	verbose		{no,prompt="Show results of all iterations?"}
bool  	addheader	{yes,prompt="Put returned values into image header keywords?"}
real	xborder		{0.1,prompt="Avoid fraction of pixels close to the x-border"}
real	yborder		{0.1,prompt="Avoid fraction pixels close to the y-border"}
real	lower		{INDEF,prompt="Initial lower limit for data range"}
real	upper		{INDEF,prompt="Initial upper limit for data range"}
real	binwidth	{0.01,prompt="Bin width of histogram in sigma"}
real	mean		{prompt="Returned value of mean"}
real	sigma		{prompt="Returned value of sigma"}
real	variance 	{prompt="Returned value of variance (sigma**2)"}
real	median		{prompt="Returned value of median"}
real	quart1		{prompt="Returned value of first quartile"}
real	quart3		{prompt="Returned value of third quartile"}
real	signoise	{prompt="Returned value of noise sigma"}
real	valmode		{prompt="Returned value of mode"}
#Above must be "valmode" to avoid conflict w/ omnipresent task parameter "mode" 
string oneparam 	{"all",enum="all|mean|stddev|npix|midpt|mode|rms|median", prompt="Find iterative value of this one parameter only"}


struct	*inimglist	{prompt="Ignore this parameter(inimglist)"}

begin

	string	im		# equals image
	string	imglist		# equals image
	string	infile		# temporary list for files
	string  img		# image name from fscan
        string	img1		# image namoe include initial section
	string  imgroot		# image root name 
	string  check		# string for `@filename' checking
	string  blankstring	# long blank string 
	string  headstring	# strings for output formatting
	string  mnstring	# 
	string  sigstring	# 
	string  npxstring	# 
	string  medstring	# 
	string  modstring	# 
	string  one_param	#
	string  statsec		# 
	real	mn		# mean from imstat
	real	sig		# stddev from imstat
	real	med		# midpt from imstat
	real	mod		# mode from imstat
	real	ll		# lower limit for imstat
	real	ul		# upper limit for imstat
        real	binwd		# binwidth
	int	nx, npx		# number of pixels used
        int	szx,szy		# X,Y size of the images
        int	xbd,ybd
        int	x1,x2,y1,y2
	int	m		# dummy for countdown
	int 	i		# length of image string
	int 	j		# dummy integer
	int 	x		# dummy integer
	
	real	qrt1,qrt3,snoise
	string  qrt1string,qrt3string


  # Expand file lists into temporary files.
  imglist = image
  infile = imglist
  check = substr(imglist,1,1)
  if(check=="@") 
    {
    infile=substr(imglist,2,strlen(imglist))
    } 
  else 
    {
    infile = mktemp("tmp$lstatist")
    sections (imglist,option="fullname",>infile)
    }
  
  binwd = binwidth
  mn = 0.
  sig = 0.
  med = 0.
  mod = 0.
  qrt1 = 0.
  qrt3 = 0.
  snoise = 0.
  nx = 0
    
    
  inimglist = infile
  one_param = oneparam
  if (one_param=="rms") one_param="stddev"
  else if (one_param=="median") one_param="midpt"
  
  lower = -999999.
  upper =  999999.

  j=0; med=0.; mod=0.
  # Loop through images
  while (fscan(inimglist,img1) != EOF) 
    {
    img = mktemp("_lsttstimg")
    imcopy(img1,img,ver-)
    imgets(img,"i_naxis1")
    szx = int(imgets.value)
    imgets(img,"i_naxis2")
    szy = int(imgets.value)
    xbd = int(xborder*szx)
    ybd = int(yborder*szy)
    x1 = xbd 
    x2 = szx - xbd
    y1 = ybd 
    y2 = szy - ybd
    statsec = "["//x1//":"//x2//","//y1//":"//y2//"]"
    # save image root name for print actions
    #lfilename(img)
    #imgroot = lfilename.root
    
    # Calculate stats using initial lower & upper limits
    
    if (one_param == "all") 
      { 
      imstat(images = img//statsec,
             fields = "mean,stddev,npix,midpt,mode",
	      #lower = lower,
	      #upper = upper,
	     format = no) | scan(mn,sig,npx,med,mod) 
      }
    else if (one_param == "mean" || one_param == "stddev" || one_param == "npix") 
      {
      imstat(images = img//statsec,
             fields = "mean,stddev,npix",
	      lower = lower,
	      upper = upper,
	     format = no) | scan(mn,sig,npx)
      }
    else if (one_param=="midpt") 
      {
      imstat(images = img//statsec,
             fields = "mean,stddev,npix,midpt",
	      lower = lower,
	      upper = upper,
	     format = no) | scan(mn,sig,npx,med)
      }
    else if (one_param=="mode") 
      {
      imstat(images = img//statsec,
             fields = "mean,stddev,npix,mode",
	      lower = lower,
	      upper = upper,
	     format = no) | scan(mn,sig,npx,mod)
      }

    # If verbose+, print output header
    if(verbose)
      {
      blankstring="                                                      "
      i=strlen(str(img))
      if (i<=6) i=7
      headstring=substr(blankstring,1,i-6)
      i=strlen(str(mn))
      if (i<=4) i=5
      mnstring=substr(blankstring,1,i-4)
      i=strlen(str(sig))
      if (i<=3) i=4
      sigstring=substr(blankstring,1,i-3)
      i=strlen(str(npx))
      if (i<=4) i=5
      npxstring=substr(blankstring,1,i-4)
      i=strlen(str(med))
      if (i<=6) i=7
      medstring=substr(blankstring,1,i-6)
      
      print("#IMAGE"//headstring//" MEAN"//mnstring//" RMS"//sigstring//" NPIX"//npxstring//" MEDIAN"//medstring//" MODE")
      
      
      }

    m = 1
    while (m <= maxiter)  
      {
      if (verbose) print(img," ",mn,sig,npx,med,mod)
      
      # Calculate new lower & upper limits by tossing out values nsigrej from the mean
      ll = mn - (nsigrej*sig)
      ul = mn + (nsigrej*sig)
      if (lower != INDEF && ll < lower) ll = lower 
      if (upper != INDEF && ul > upper) ul = upper
      
#      if (one_param=="all") 
#        { 
        imstat(img//statsec,fields="mean,stddev,npix,midpt,mode",lower=ll,upper=ul,for-,binwidth=binwd) | scan(mn,sig,nx,med,mod) 
#        }
#      else if (one_param == "mean"|| one_param == "stddev" || one_param == "npix") 
#        {
#	imstat(img//statsec,fields="mean,stddev,npix",lower=ll,upper=ul,for-) | scan(mn,sig,nx)
#	}
#      else if (one_param == "midpt") 
#        {
#	imstat(img//statsec,fields="mean,stddev,npix,midpt",lower=ll,upper=ul,for-) | scan(mn,sig,nx,med)
#	}
#      else if (one_param == "mode") 
#        {
#	imstat(img//statsec,fields="mean,stddev,npix,mode",lower=ll,upper=ul,for-) | scan(mn,sig,nx,mod)
#	}

      # If mean is INDEF, set it to zero
      if(mn==INDEF) 
        {
	mn=0.
	print("#WARNING: mean of "//img//" is INDEF!  Setting mean equal to zero.")
	}

      # If stddev is INDEF, set it to 32767
      if(sig==INDEF) 
        {
	sig=32767.
        print("#WARNING: stddev of "//img//" is INDEF!  Setting stddev equal to 32767.")
	}

      # If midpt (median) is INDEF, set it to the mean 
      if(med==INDEF && (one_param == "all" || one_param == "midpt")) 
        {
	med=mn
        print("#WARNING: median of "//img//" is INDEF!  Setting median equal to mean.")
	}

      # If mode is INDEF, set it to the mean 
      if(mod == INDEF && (one_param == "all" || one_param == "mode")) 
        {
	mod=mn
        print("#WARNING: mode of "//img//" is INDEF!  Setting mode equal to mean.")
	}

      # If after this recalculation the same number of pixels are accepted, end loop
      if (nx == npx) break
	   	
      npx = nx
      m = m + 1
      } # End of while (m <= maxiter)

    # If median (midpt) or mode output was not requested, set to INDEF 
    if (med!=INDEF && (one_param!="all" && one_param!="midpt")) med=INDEF
    if (mod!=INDEF && (one_param!="all" && one_param!="mode")) mod=INDEF

    # Calculate first and third quartile and efficient noise
    if (med != INDEF) 
      {
      imstatistics(images = img//statsec,
                   fields = "midpt",
		    upper = med,   
	            lower = INDEF, 
		 binwidth = 0.001,
		   format = no) | scan(qrt1)
      imstatistics(images = img//statsec,
                   fields = "midpt",
		    upper = INDEF, 
                    lower = med, 
		 binwidth = 0.001,
		   format = no) | scan(qrt3)
       
      snois = (med - qrt1)*2./1.36
      }

    # If first image, print output header
    j+=1
    if(j==1 && !verbose)
      {
      blankstring="							 "
      i=strlen(str(img))
      if (i<=6) i=7
      headstring=substr(blankstring,1,i-6)
      i=strlen(str(mn))
      if (i<=4) i=5
      mnstring=substr(blankstring,1,i-4)
      i=strlen(str(sig))
      if (i<=3) i=4
      sigstring=substr(blankstring,1,i-3)
      i=strlen(str(npx))
      if (i<=4) i=5
      npxstring=substr(blankstring,1,i-4)
      i=strlen(str(med))
      if (i<=6) i=7
      medstring=substr(blankstring,1,i-6)
      i=strlen(str(mod))
      if (i<=4) i=5
      modstring=substr(blankstring,1,i-4)
      i=strlen(str(qrt1))
      if (i<=6) i=7
      qrt1string=substr(blankstring,1,i-6)
      i=strlen(str(qrt3))
      if (i<=6) i=7
      qrt3string=substr(blankstring,1,i-6)
      
      
      if (print)
        {
	print "" 
        print("#IMAGE"//headstring//" MEAN"//mnstring//" RMS"//sigstring// \
              " NPIX"//npxstring//" MEDIAN"//medstring//" MODE"//modstring// \
	      " QUART1"//qrt1string//" QUART3"//qrt3string//" RMS NOISE")
        }
      }

    # Print statistics
    if (print && !verbose) print(img," ",mn,sig,npx,med,mod,qrt1,qrt3,snois)
    mean = mn
    sigma = sig
    variance = sig**2.
    median = med
    valmode = mod
    quart1 = qrt1
    quart3 = qrt3
    signoise = snois
    
    if(addheader) 
      {
      hedit (img, "ITERMEAN", mean, add+, ver-, show-, update+)
      hedit (img, "ITERSIG", sigma, add+, ver-, show-, update+)
      hedit (img, "VARIANCE", variance, add+, ver-, show-, update+)
      hedit (img, "ITERMED", median, add+, ver-, show-, update+)
      hedit (img, "ITERMODE", valmode, add+, ver-, show-, update+)
      hedit (img, "QUART1", quart1, add+, ver-, show-, update+)
      hedit (img, "QUART3", quart3, add+, ver-, show-, update+)
      hedit (img, "SIGNOISE", signoise, add+, ver-, show-, update+)
      }

      imdel(img,ver-)
    } # End of while (fscan(inimglist=infile,img) != EOF)

  if(check!="@") delete (infile,ver-, >& "dev$null")

  inimglist = ""

  #!time

end

