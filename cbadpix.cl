procedure cbadpix(input, output)

string input     {prompt="Input images"}
string output    {prompt="Prefix for corrected images"}
string immask    {prompt="Mask to be used (default or file)"}

struct *ilist

begin

 string iname, in_im, comtmp1, im_list, opref, maskn
 int iaxis3

 opref = output
 #Expand the image template into a text file list
 in_im = mktemp("_iralin")
 files(input,sort-,>in_im)

 # Now scanning through all images
 
   print("")
   print("Compiling list of images. Please wait!!!")
   ilist = in_im
   while (fscan(ilist, iname) != EOF) {
       if (nscan() == 1)
       {
         print("iname ",iname)
         imgets(iname, para="i_naxis")	      
         iaxis3=int(imgets.value)
	 ## generating input list for sky 
         comtmp1 = mktemp("_icccom")
	 IF (iaxis3 == 4)
	   imslice(iname//"[*,*,1,*]",comtmp1,3,ver-)
	 IF (iaxis3 == 3)  
	   imslice(iname,comtmp1,iaxis3,ver-)
	 im_list = mktemp("_cfllst")
	 sections(comtmp1//"*", >>im_list)
	 wcsreset("@"//im_list,"physical",verbose=no)
	 wcsreset("@"//im_list,"world",verbose=no)
	 if (cbadpix.immask == "default") 
	    maskn = "caindr$cmask.pl" 
	 else 
	    maskn = cbadpix.immask   
         fixpix("@"//im_list,mask=maskn,linterp=INDEF,cinterp=INDEF,
	    verbose=no)
	 imstack("@"//im_list,output//iname)

       }	 
   }    
   
 # Cleaning up
   #imdel("_*.fits")  
   delete("_*",ver-,>>"dev$null")

end
