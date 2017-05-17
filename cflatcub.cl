procedure cflatcub (input, output, flat)

# Perform flat-field correction for a list of frames

string input     {prompt="Input images"}
string output    {prompt="Prefix for corrected images"}
string flat      {prompt="Name of flat-field correction"}
bool   normal	 {yes,prompt="Normalize the flat field?"}

struct *ilist

begin

 string opref, iname, in_im, comtmp1, im_list,nflat 
 int iaxis3
 real nfact   
   
 opref = output
 #Expand the image template into a text file list
 in_im = mktemp("_iralin")
 files(input,sort-,>in_im)

## Normalize the flat 
  if (normal) 
   {
      nflat = mktemp("_cflnflt")
      imstatist(flat,fields="midpt",format-) | scan(nfact)
      imarith(flat,"/",nfact,nflat)
   } 
  else
   nflat = flat
   
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
	   imslice(iname//"[*,*,*]",comtmp1,iaxis3,ver-)
	 im_list = mktemp("_cfllst")
	 sections(comtmp1//"*", >>im_list)
	 wcsreset("@"//im_list,"physical",verbose=no)
	 #wcsreset("@"//im_list,"world",verbose=no)
	 imarith("@"//im_list,"/",nflat,opref//"@"//im_list)
	 print("output ",opref//iname)
	 imstack(opref//"@"//im_list,opref//iname)
       }	 
   }    
  
   # Clean up
   
   delete("_icc*",ver-, >& "dev$null")
   delete(opref//"_icc*",ver-, >& "dev$null")
   delete("_cfllst*",ver-, >& "dev$null")
   delete("_iralin*",ver-, >& "dev$null")
   delete("_cflnflt*",ver-, >& "dev$null")
   
   print("")
   print("  <<------ cflatcub DONE ----->>")
         	 
     
end 
