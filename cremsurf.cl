procedure cremsurf (input, output)


### subtract large scale structure of image by fitting surface

string 	input     {"",prompt="Input images"}
string 	output    {"n",prompt="Prefix for corrected images (output)"}
string 	foutput    {"fn",prompt="Prefix for surface images (output)"}
int	xorder	  {1,prompt="Order of function in x"}
int     yorder    {1,prompt="Order of function in y"}
string  funcsurf  {"spline3",prompt="Function to be fit to surface"}
int     medfilt	  {9,prompt="Length of median box"}

struct *ilist
struct *flist

begin

 string in_im, comtmp1, im_list, iiname, iname, imsrmtmp
 string ofpref, opref, oimpatt, foimpatt
 int	iaxis3, islice
 

 #Expand the image template into a text file list
 in_im = mktemp("_iccncr")
 files(input,sort-,>in_im)

 ofpref = foutput
 opref = output

   ilist = in_im
   while (fscan(ilist, iname) != EOF) {
      print ("Surface fitting of ",iname)
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
      if (output != "") 
        oimpatt = opref//iname
      else
        oimpatt = mktemp("_oimncr")
      
      if (output != "") 
        foimpatt = ofpref//iname
      else
        foimpatt = mktemp("_oimncr")
      
      imarith(iname,"/",iname,oimpatt)

      ## now remove large scale patter by quadrant
      flist = im_list
      islice = 1
      while (fscan(flist,iiname) != EOF) {
	imcopy(iiname//"[1:128,1:128]",iiname//"_a",verb-,>& "dev$null")
	imcopy(iiname//"[1:128,129:256]",iiname//"_b",verb-,>& "dev$null") 
	imcopy(iiname//"[129:256,1:128]",iiname//"_c",verb-,>& "dev$null") 
	imcopy(iiname//"[129:256,129:256]",iiname//"_d",verb-,>& "dev$null")
	## fit a surface and extract the residuals (this step should
	##  remove illumination variations)
	imsrmtmp = mktemp("_imsrmtmp")
	imsurfit(iiname//"_a",imsrmtmp//"_a",xorder=xorder,yorder=yorder,
	  type_output="residual",xmedian=medfilt,ymedian=medfilt,
	  lower=2,upper=2,niter=2,regions="all",function=funcsurf)
	imsurfit(iiname//"_b",imsrmtmp//"_b",xorder=xorder,yorder=yorder,
	  type_output="residual",xmedian=medfilt,ymedian=medfilt,
	  lower=2,upper=2,niter=2,regions="all",function=funcsurf) 
	imsurfit(iiname//"_c",imsrmtmp//"_c",xorder=xorder,yorder=yorder,
	  type_output="residual",xmedian=medfilt,ymedian=medfilt,
	  lower=2,upper=2,niter=2,regions="all",function=funcsurf) 
	imsurfit(iiname//"_d",imsrmtmp//"_d",xorder=xorder,yorder=yorder,
	  type_output="residual",xmedian=medfilt,ymedian=medfilt,
	  lower=2,upper=2,niter=2,regions="all",function=funcsurf)
      
	if (iaxis == 3) { 	 
	  imcopy(imsrmtmp//"_a",oimpatt//"[1:128,1:128,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_b",oimpatt//"[1:128,129:256,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_c",oimpatt//"[129:256,1:128,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_d",oimpatt//"[129:256,129:256,"//islice//"]",verb-)
	} else if (iaxis ==4){  
	  imcopy(imsrmtmp//"_a",oimpatt//"[1:128,1:128,1,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_b",oimpatt//"[1:128,129:256,1,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_c",oimpatt//"[129:256,1:128,1,"//islice//"]",verb-)
	  imcopy(imsrmtmp//"_d",oimpatt//"[129:256,129:256,1,"//islice//"]",verb-)
	}  
        
	islice += 1
      }
      
     imarith (iname,"-",oimpatt,foimpatt)
  
   } 	  


end
