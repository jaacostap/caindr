procedure ccnoicor (input, output)

# Subtract correlated noise to a list of frames

string 	input     {"",prompt="Input images"}
string 	output    {"n",prompt="Prefix for corrected images (output)"}
string  noipatt	  {"noi_",prompt="Noise pattern images"}
string  masks	  {"msk_",prompt="Mask objects images"}
string  badpix	  {"",prompt="Bad pixel mask"}
string  reject	  {"pclip",prompt="Type of rejection"}
real	pclip     {-0.5,prompt="pclip: Percentile clipping parameter"}
int	xorder	  {1,prompt="Order of function in x"}
int     yorder    {1,prompt="Order of function in y"}
real	sigma	  {1.,prompt="Sigma of image"}
real    lsigma    {3.,prompt="Lower sigma clipping factor"}
real    hsigma    {3.,prompt="Upper sigma clipping factor"}
bool	subfit	  {no,prompt="Subtract surface fit prior to combination?"}
string  funcsurf  {"spline3",prompt="Function to be fit to surface"}
int     medfilt	  {9,prompt="Length of median box"}

struct *ilist
struct *flist

begin

 string opref, in_im, comtmp1, im_list, in_qsrlst, rej1
 string oimnoicor, oimpatt, iname, iiname, noiqua, imsrnoi,bpm,imsrnoiobj, omask
 int iaxis3, islice
 real nfact, md,ssg, lsg1, hsg1, pclp1   
   
   
 ssg = sigma  
 opref = output
 lsg1 = lsigma
 hsg1 = hsigma
 pclp1 = pclip
 rej1 = reject
 ####bpm = mktemp("_ccbpm")
 ####imcopy(badpix,bpm)
 ## divide the bad pixel mask
 ####imcopy(bpm//"[1:128,1:128]",bpm//"_a.pl",verb-,>& "dev$null")  
 ####imcopy(bpm//"[1:128,129:256]",bpm//"_b.pl",verb-,>& "dev$null")  
 ####imcopy(bpm//"[129:256,1:128]",bpm//"_c.pl",verb-,>& "dev$null")  
 ####imcopy(bpm//"[129:256,129:256]",bpm//"_d.pl",verb-,>& "dev$null") 
 
 ## Reset coordinate systems to avoid conflicts with objmask task
 ####wcsreset(bpm//"_*","world")

 #Expand the image template into a text file list
 in_im = mktemp("_iccncr")
 files(input,sort-,>in_im)

   
 # Now scanning through all images
 
   print(" ")
   print("Compiling list of images. Please wait!!!")
   ilist = in_im
   while (fscan(ilist, iname) != EOF) {
      imgets(iname, para="i_naxis")	   
      iaxis3=int(imgets.value)

      ## generating input list
      imdel("_icccom*",ver-) 
      comtmp1 = mktemp("_icccom")
      imslice(iname,comtmp1,iaxis3,ver-,>& "dev$null")
      im_list = mktemp("_cfllst")
      sections(comtmp1//"*", >>im_list)
      wcsreset("@"//im_list,"world",verbose=no)

      ## generate output image with the noise pattern
      if (noipatt != "") 
        oimpatt = noipat//iname
      else
        oimpatt = mktemp("_oimncr")
      imarith(iname,"/",iname,oimpatt)
      oimnoicor = opref//iname	  

      ## generate output mask
      omask = masks//iname//".pl"
      
      imexpr("repl(0,256)",omask,dim="256,256,30")

      ## now determine noise pattern
      flist = im_list
      islice = 1
      while (fscan(flist,iiname) != EOF) {
	imcopy(iiname//"[1:128,1:128]",iiname//"_a",verb-,>& "dev$null")
	imcopy(iiname//"[1:128,129:256]",iiname//"_b",verb-,>& "dev$null") 
	imcopy(iiname//"[129:256,1:128]",iiname//"_c",verb-,>& "dev$null") 
	imcopy(iiname//"[129:256,129:256]",iiname//"_d",verb-,>& "dev$null")
	## fit a surface and extract the residuals (this step should
	##  remove illumination variations)
	if (subfit) {
	  imsrnoi = mktemp("_imsrnoi")
	  imsrnoiobj = mktemp("_imsrnoiobj")
	  imsurfit(iiname//"_a",imsrnoi//"_a",xorder=xorder,yorder=yorder,
	    type_output="residual",xmedian=medfilt,ymedian=medfilt,
	    lower=2,upper=2,niter=2,regions="all",function=funcsurf) 
	  imsurfit(iiname//"_b",imsrnoi//"_b",xorder=xorder,yorder=yorder,
	    type_output="residual",xmedian=medfilt,ymedian=medfilt,
	    lower=2,upper=2,niter=2,regions="all",function=funcsurf) 
	  imsurfit(iiname//"_c",imsrnoi//"_c",xorder=xorder,yorder=yorder,
	    type_output="residual",xmedian=medfilt,ymedian=medfilt,
	    lower=2,upper=2,niter=2,regions="all",function=funcsurf) 
	  imsurfit(iiname//"_d",imsrnoi//"_d",xorder=xorder,yorder=yorder,
	    type_output="residual",xmedian=medfilt,ymedian=medfilt,
	    lower=2,upper=2,niter=2,regions="all",function=funcsurf)
	} else {
	  imsrnoi = iiname//"_"
	} 
##	# Now take into account generic bad pixel mask  
##	hedit(imsrnoi//"_a","BPM",bpm//"_a",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_b","BPM",bpm//"_b",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_c","BPM",bpm//"_c",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_d","BPM",bpm//"_d",add+,upd+,ver-,show-)  

	in_qsrlst = mktemp("_qsrlst")  
	files(imsrnoi//"*",>in_qsrlst) 
	noiqua = mktemp("_imnoiqua")
	
##	imcopy(imsrnoiobj//"_a.pl",omask//"[1:128,1:128,"//islice//"]",verb-)
##	imcopy(imsrnoiobj//"_b.pl",omask//"[1:128,129:256,"//islice//"]",verb-)
##	imcopy(imsrnoiobj//"_c.pl",omask//"[129:256,1:128,"//islice//"]",verb-)
##	imcopy(imsrnoiobj//"_d.pl",omask//"[129:256,129:256,"//islice//"]",verb-)
	
##	## adding keywords to the header   
##	hedit(imsrnoi//"_a","BPM",imsrnoiobj//"_a",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_b","BPM",imsrnoiobj//"_b",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_c","BPM",imsrnoiobj//"_c",add+,upd+,ver-,show-)  
##	hedit(imsrnoi//"_d","BPM",imsrnoiobj//"_d",add+,upd+,ver-,show-)  	   
	imcombine("@"//in_qsrlst,noiqua,rejmasks="",expmasks="",
	   combine="median",reject=rej1,scale="none",zero="none",
	   nlow=0,nhigh=2,nkeep=1,pclip=pclp1,lsigma=lsg1,hsigma=hsg1,
	   logfile="STDOUT",masktype="none",maskvalue=0)
	if (iaxis == 3) { 	 
	  imcopy(noiqua,oimpatt//"[1:128,1:128,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[1:128,129:256,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[129:256,1:128,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[129:256,129:256,"//islice//"]",verb-)
	} else if (iaxis ==4){  
	  imcopy(noiqua,oimpatt//"[1:128,1:128,1,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[1:128,129:256,1,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[129:256,1:128,1,"//islice//"]",verb-)
	  imcopy(noiqua,oimpatt//"[129:256,129:256,1,"//islice//"]",verb-)
	}  
	
##	hedit(oimpatt,"BPM",del+,ver-,show-)
        islice += 1  
	delete(in_qsrlst,ver-) 
	imdel ("_imsrnoi*",ver-)
	imdel("_imnoiqua*",ver-)    
      }
      
      imarith(iname,"-",oimpatt,oimnoicor)
                    
      imdel("_icccom*",ver-)
    }	 
       
   delete("_cfllst*",ver-)
   delete("_iccncr*",ver-)
   imdel("_ccbpm*",ver-)
  
   print("")
   print("  <<------ ccnoircor DONE ----->>")
         	 
     
end 
