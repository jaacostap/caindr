# IRAF script -- to subtract the sky, which is computed from 
#                a list of images especified in header keywords
# 		 observations are taken following a dittern pathern
# Jap, May 2001  - cambiar el n_axis3 a n_axis4
# JAP, May 2005  - modificar forma crear fichero de entrada a imcombine usando
#   		   imslice y argumentos
# JAP, Dic 2011  - se modifica para evitar reset del wcs

procedure csubditsky(frame_list)

string frame_list    {prompt="List of images, and offbeam exposures",mode="ql"}
string prefix	     {"s_",prompt="Prefix for sky subtracted images"}
string combine	     {"median",enum="average|median", \
			prompt="Type of combine operation when projecting"}
int    inidisc	     {0,   \
                        prompt="Number of first exposures discarded from a series"}		
string reject	     {"none",prompt="Type of rejection"}		
string scalecomb     {"none",enum="none|offset|scale", \
                             prompt="Equalization of sky images before combining"}
real   nhigh 	     {0.25,prompt="Fraction of images from maximum to reject"}
real   nlow 	     {0.05,prompt="Fraction of images from minimum to reject"}
#string masktype	     {"none",enum="none|badvalue|goodvalue",prompt="Mask type"}
#real   maskvalue     {0.,prompt="Mask value"}
bool   maskobj       {yes,prompt="Mask object for sky generation?"}
string maskpref	     {"m",prompt="Prefix for object mask frames"}
real   pclip	     {-0.5,prompt="Tolerance for sigma clipping scaling corrections"}
real   lsigma	     {3.,prompt="Lower sigma clipping factor"}
real   hsigma	     {3.,prompt="Upper sigma clipping factor"}
string scalesub	     {"none",enum="none|offset|scale", \
                             prompt="Modify sky image before subtraction"}
bool   delsky	     {yes,prompt="Delete resulting sky image"}
string skyname	     {"default",prompt="Name of sky frame"}			     			
string logfile	     {"csubditsky.log",prompt="Log file"}			

struct *imglist, *sublist, *outlist

begin

int 	nref   # number of reference images for each input one.
string  sref   # string containing the set of reference images.
string  combine1 # use average or median when combining the sky images
string  sscal  # scaling the sky images before combining

int     icount, jcount 

string  reflist, tmpref, reflist_tmp, ilist, olist, msklist
string  img, img1, dum, msk1
string  skytmp, skytmp_sca, objtmp, outtmp, outtmp1, comtmp1,msktmp
string 	log1, pre1
string	scalesub1,maskpref1
string	scale1, zero1, rej1


int     nh, nl
real	scale, lsig1, hsig1, pclp1, md, sig
int	firstfra, iaxis3, i, iaxis, nsc
bool	maskobj1 

# Get the query parameters
	       
	maskobj1 = maskobj
	maskpref1 = maskpref
	       
        icount=0
	scale = 1.
        #imglist = frame_list
	combine1 = combine
	log1 = logfile
	pre1 = prefix
	firstfra = inidisc+1
	scalesub1 = scalesub
	sscal = scalecomb
	rej1 = reject 
	lsig1 = lsigma
	hsig1 = hsigma
	pclp1 = pclip  

        #  get names for temporary files
		
	reflist = mktemp("_sbdrefl")
	ilist = mktemp("_sbdilt")
	olist = mktemp("_sbdolt")
	msklist = mktemp("_sbdmsklt")
	if (csubditsky.skyname == "default") 
	    skytmp = mktemp("_sbdskym") 
	else 
	    skytmp = csubditsky.skyname    
	outtmp1 = mktemp("_sbdout") 
	skytmp_sca = mktemp("_sbdskys") 
	
	files(frame_list,>reflist)
	imglist = reflist

        while (fscan (imglist,img) != EOF) 
	  {
              icount += 1
	      comtmp1 = mktemp("_sdcomb")
	      #print(img," is in processing")
	      # discard the first frames from a series
	      imgets(img, para="i_naxis")
	      iaxis = int(imgets.value)
	      if (iaxis == 4)  
                   imgets(img, para="i_naxis4")	
	      else 
	           imgets(img, para="i_naxis3")		         
              iaxis3=int(imgets.value)
	      
	      ## generating input list for sky 
	      imslice(img//"[*,*,"//firstfra//":"//iaxis3//"]",comtmp1,3,ver-,>& "dev$null")
	      sections(comtmp1//"*", >>ilist)
	      wcsreset("@"//ilist,"physical",verbose=no,>& "dev$null")
	      #wcsreset("@"//ilist,"world",verbose=no,>& "dev$null")
              hedit("@"//ilist,	"wcsdim",add-,del+,veri-,>& "dev$null")      
	      
	      # generating output and sky frame lists
	      cfilename(img)
	      outtmp = pre1//cfilename.root
	      msktmp = maskpref1//cfilename.root
	      imcopy(img//"[*,*,"//firstfra//":"//iaxis3//"]",outtmp,ver-,>& "dev$null")	      
	      if (maskobj1) 
	          imarith(img//"[*,*,"//firstfra//":"//iaxis3//"]","-",
	            img//"[*,*,"//firstfra//":"//iaxis3//"]",msktmp//".pl")	      
 	      for (i=firstfra; i <= iaxis3; i +=1)
	        {  
	          #sections(img//"[*,*,"//i//"]", >> ilist)
		  j = i - firstfra+1
		  sections(outtmp//"[*,*,"//j//"]", >> olist)
		  if (maskobj1)
		    sections(msktmp//"[*,*,"//j//"].pl", >> msklist)
		} 
	  	 
           }

        # generating sky frame

	 # determine the number of frames to discard to estimate sky
	 wc(ilist) | scan(jcount)

	 nl = int(nlow * jcount + 0.5)
	 nh = int(nhigh * jcount + 0.5) 

	 scale1 = "none"
	 zero1 = "none"
	 
	 # select scale or zero offset 
	 if (sscal == "scale") 
	      scale1 = "median"
	 if (sscal == "offset")
	      zero1 = "median"	   

         print("combinando las imagenes ")
	 print("reject ",lsig1,hsig1)
	 
	 imcombine("@"//ilist,skytmp,rejmask="",combine=combine1,
	  reject=rej1, project=no, outtype="real", offset="none", 
	  masktype="none", blank=0, scale=scale1, 
	  zero=zero1,weight="none", expname="", statsec="", nlow=nl, nhigh=nh,
	  nkeep=1,pclip=pclp1,lsigma=lsig1,hsigma=hsig1, logfile=log1)
            

        # subtract sky image to each frame
	imglist = ilist
	outlist = olist
        while (fscan (imglist,img) != EOF) 
	  {
	    if (fscan(outlist, outtmp) != EOF)
	      {
		print("Sky subtracted image ",outtmp)
		if (scalesub1 == "scale") 
		{
        	  # make scaled sky image, dividing the object frame by the sky
 		  imarith(img,"/",skytmp,skytmp_sca)
		  imstatistics(skytmp_sca, fields="midpt",format-) \ 
	    	              | scan(scale)
		  print("Sky scale ",scale,>>log1)	
		  imdel(skytmp_sca, ver-, >& "dev$null")		  
		  imarith(skytmp,"*",scale,skytmp_sca)
		  imarith(img,"-",skytmp_sca,skytmp_sca)
		} 
		else if (scalesub1 == "offset") 
		{
        	  # add offset to sky image
 		  imarith(img,"-",skytmp,skytmp_sca)
		  imstatistics(skytmp_sca, fields="midpt",format-) \ 
	    	              | scan(scale)
		  print("Sky offset ",scale,>>log1)
		  print(" outtmp=",outtmp)
		  imarith(skytmp_sca,"-",scale,skytmp_sca)
		} 
		else 
		{
		  imarith(img,"-",skytmp,skytmp_sca)
		} 

 		imcopy(skytmp_sca, outtmp, ver-, >& "dev$null")
 		imdel(skytmp_sca, ver-, >& "dev$null")

	      }  #close loop for sliced object images 
	    }

 	 # now create object mask from each sky subtracted frame
	if (maskobj1) 
	{ 
	  imglist = ilist
	  outlist = olist 
	  sublist = msklist
	  while (fscan(outlist,img) != EOF)
	   { 
	     dum = mktemp("_sbmsk")//".pl"
	     print("img ",img)
	     imstatistics(img,fields="midpt,stddev",format=no) | scan(md,sig)
	     objmasks(img,dum,omtyp="boolean",skys=md,
	       sigmas=sig,masks="",extname="",blkstep=1,blksize=4,hsigma=5,
	       lsigma=10,hdetect=yes,ldetect=no,neighbo=8,minpix=6,ngrow=1,
	       agrow=1)
	     nsc = fscan(sublist,msk1)
	     imcopy(dum,msk1,ver-,>& "dev$null") 
             imdel(dum,ver-,>& "dev$null") 
             nsc = fscan(imglist,img1)
	     hedit(img1,"BPM",msk1,add=yes,upd=yes,veri=no,>& "dev$null")

	   }
	   

	   # now combine the images to get the sky frame
	   imdel(skytmp,veri=no,>& "dev$null")
	   imcombine("@"//ilist,skytmp,rejmask="",combine=combine1, 
	    reject=rej1 ,project=no,outtype="real",offset="none", 
	    masktype="badvalue",maskvalue=1,blank=0,scale=scale1, 
	    zero=zero1,weight="none",expname="",statsec="",nlow=nl,nhigh=nh, 
	    nkeep=1,lthreshold=INDEF,hthreshold=INDEF,logfile=log1)

          # subtract sky image to each frame
	  imglist = ilist
	  outlist = olist
          while (fscan (imglist,img) != EOF) 
	    {
	      if (fscan(outlist, outtmp) != EOF)
		{
		  print("Sky subtracted image ",outtmp)
		  if (scalesub1 == "scale") 
		  {
        	    # make scaled sky image, dividing the object frame by the sky
 		    imarith(img,"/",skytmp,skytmp_sca)
		    imstatistics(skytmp_sca, fields="midpt",format-) \ 
	    	        	| scan(scale)
		    print("Sky scale ",scale,>>log1)	
		    imdel(skytmp_sca, ver-, >& "dev$null")		  
		    imarith(skytmp,"+",scale,skytmp_sca)
		  } 
		  else if (scalesub1 == "offset") 
		  {
        	    # add offset to sky image
 		    imarith(img,"-",skytmp,skytmp_sca)
		    imstatistics(skytmp_sca, fields="midpt",format-) \ 
	    	        	| scan(scale)
		    print("Sky offset ",scale,>>log1)	
		    imdel(skytmp_sca, ver-, >& "dev$null")		  
		    imarith(skytmp,"+",scale,skytmp_sca)
		  } 
		  else 
		  {
		    imcopy(skytmp,skytmp_sca,ver-)
		  } 

		  imarith(img,"-",skytmp_sca,outtmp1)
		  imcopy(outtmp1,outtmp,ver-)
 		  imdel(skytmp_sca, ver-, >& "dev$null")
		  imdel(outtmp1, ver-, >& "dev$null")

		}  #close loop for sliced object images 
	      }
	      
	}
 
          # Cleaning up

	  ## delete temporary images
	  imdel("@"//ilist, ver-, >& "dev$null")

          delete(ilist, ver-, >& "dev$null")
          delete(olist, ver-, >& "dev$null")
	  delete(reflist, ver-, >& "dev$null")
	  delete(msklist, ver-, >& "dev$null")
	  	  	  
	  if (delsky && csubditsky.skyname == "default") 
	      imdel(skytmp, ver-, >& "dev$null")  
		  
          print("   <<----- csubditsky DONE----->>")   
          beep;beep

end

