procedure cicomb_slicecub (input, outima)

# align a set of frames forming part of the same cycle
# the final image can be the projection of all frames
# the difference with iralign is that the approximate shift is
# computed only on the first slice image

string input     {prompt="Input images, use only the rootname"}
string combine	 {"average",enum="average|median", \
			prompt="Type of combine operation when projecting"}
string inshift   {"",prompt="Input shift file "}
string outshift  {"",prompt="Output shift file "}
string outima    {prompt="Output image"}
string zero      {prompt="Image zero point offset"}
string reject    {"none",prompt="Type of rejection"}
string mask	 {"",prompt="Bad pixel mask"}
int    ref_plane {1,prompt="Reference plane "}
int    nslice    {1,prompt="Number of output slices (original cube is )"}
bool   roundc	 {yes,prompt="Round shift coordinates?"}
bool   verbose   {no,prompt="Verbose mode",mode="hl"}
	  
struct *ilist,*sublist

begin

 	file    imref 		     # reference image  			
        file    in_im                # equals input				
	string  outtmp		     # output image				
	string  exam_lst	     # output of imexam on all images		
	string	stars_lst	     # several stars in ref image		
	string	align_lst	     # output of imalign to produce final shifts
	string  out_shift,in_shift   # same for both passes	
	string  insh1 		     # input offset file		
	string  im_list              # temporary list of images 		
	string  im1_list             # temporary list of images 		
	string	temp2		     # temporary file
	string  zero1				
        string  combine1 # use average or median when combining the sky images
        real    x0, y0, xx, yy
	int     i, icount, iaxis3, iref, xini, yini 
	string  flist_tmp,iname, comtmp1, tfstar, tf2
        string  msktyp="none"
        int	mskval=0

 # Copiamos parametros
 
  im_list=mktemp("_iralst")
 im1_list=mktemp("_iralst1")   # first slice only
 flist_tmp = mktemp("_iralign")
 in_im = mktemp("_iralin")
 files(input,sort-,>in_im)
 
 zero1 = zero
 
 insh1 = inshift 
 iref = ref_plane
 
        
      tf2 = mktemp("ldedithertf2")
      if (outshift != "") 
        out_shift = outshift	
      else 
        out_shift = mktemp("ccmb_shft")
	
      in_shift = mktemp("ccmb_ishft")	

      tfstar = mktemp("ldedithertfst")
#      if (dispopt2.check) {contrdisp = xmin}
      
  

 # Now scanning through all images
 
   print("")
   print("Compiling list of images. Please wait!!!")
   sublist = in_im
   while (fscan(sublist, iname) != EOF) {
       if (nscan() == 1)
       {
         imgets(iname, para="i_naxis3")	      
         iaxis3=int(imgets.value)
	 ## generating input list for sky 
         comtmp1 = mktemp("_icccom")
	 imslice(iname//"[*,*,*]",comtmp1,3,ver-)
	 sections(comtmp1//"*", >>im_list)
	 wcsreset("@"//im_list,"physical",verbose=no)
	 print(iaxis3, >> flist_tmp)  
         sections(iname//"[*,*,"//iref//"]", >> im1_list)
       }	 
   }   
   
  # check if input offset are specified 
  if (access(insh1)) 
     {
       out_shift = insh1
       goto docomb
     }  

   cdispstars (input = "@"//im1_list,
            outstars = tfstar,
            outshift = tf2,
              shiftf = "",
        	xmin = INDEF,
        	ymin = INDEF,
        	xmax = INDEF,
        	ymax = INDEF,
              tmpdir = "./",
            checkbox = 20,
             verbose = yes)
	     
# now assing the same offset to images at the same dither point
   ilist = in_im 
   sublist = tf2	     
   while (fscan(ilist, iname) != EOF) {
     if (fscan(sublist, xini, yini) != EOF) 
      {
         imgets(iname, para="i_naxis3")	      
         iaxis3=int(imgets.value)
         for (i=1; i <= iaxis3; i+=1)
	   {
	     print(xini,yini, >> in_shift)
	   }
      }
   }
    
   
# now computing accurate shifts    
   print("Computing accurate shifts for all images. It may take some time!! ")
   ilist = ""

   #print("im_list ",im_list)
   #print("tfstar ",tfstar)
   #print("out_shift ",out_shift)
   #print("in_shift ",in_shift)
   #print("out_shift ",out_shift)
   cimcentroid(input="@"//im_list,fstars=tfstar,outshift=out_shift,
        inshift=in_shift,boxsize=15, bigbox=21, negative=no,
	background=INDEF, lower=INDEF, upper=INDEF, niterate=3,
	tolerance=0, verb=yes)
   

docomb: 
   outtmp = outima
 
   if (mask != "") {
      hedit("@"//im_list,"BPM",mask,add+,upd+,ver-,>& "dev$null")
      msktyp = "goodvalue"
      mskval = 0
   }

   hedit("@"//im_list,"WCSDIM",add-,del+,ver-,>& "dev$null")
  
   ## slice the cubes to produce different images 
   ilist = im_list
   sublist = out_shift
   nimages_slice = iaxis3/nslice
   islice0 = 0 
   for (islc=1; islc <= nslice; islc +=1)
     {
       islice0 += 1
       fscan(ilist,)  
     } 
   imcombine("@"//im_list,outtmp,combine=combine,offsets=out_shift,
    masktype=msktyp,maskvalue=mskval,project=no,outtype="real", zero=zero1, scale="none",
    reject=reject,weight="none",)

   
   # Cleaning up
   imdel("@"//im_list,ver-, >& "dev$null")  
   delete(tfstar, ver-, >& "dev$null")
   delete(in_shift, ver-, >& "dev$null")
   delete(im_list, ver-, >& "dev$null")
   delete(im1_list, ver-, >& "dev$null")
   delete(flist_tmp,ver-, >& "dev$null") 
   delete("_ira*",ver-, >& "dev$null") 
   delete("ldedi*",ver-, >& "dev$null") 

   print("")
   print("  <<------ cicomb_cub DONE ----->>")
         	 
     
end 

