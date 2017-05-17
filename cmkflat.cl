procedure cmkflat  (inputbg,inputdk,output)

string inputbg     {"",prompt="Input images of bright flats"}
string inputdk     {"",prompt="Input images of dark flats"}
string outputbg    {"",prompt="Output bright flat"}
string outputdk    {"",prompt="Output dark flat"}
string output      {"",prompt="Output flat (bright-dark)"}

struct *ilist 

begin
 
 string iname, in_im, comtmp1, im_list, outputbg1, outputdk1, output1
 int iaxis3
 real md

 #Expand the image template into a text file list
 in_im = mktemp("_iralin")
 files(inputbg,sort-,>in_im)
 
 output1 = mktemp("_cmkfltout")
 if (outputbg == "") 
    outputbg1 = mktemp("_cmkfltbg")
 else 
    outputbg1 =  outputbg
# Now scanning through bright flats
 
 in_im = mktemp("_iralin")
 files(inputbg,sort-,>in_im)
   print("")
   print("Compiling bright flats. Please wait!!!")
   ilist = in_im
   
   im_list = mktemp("_cfllst")
   while (fscan(ilist, iname) != EOF) {
       #if (nscan() == 1)
       #{
         imgets(iname, para="i_naxis")	      
         iaxis3=int(imgets.value)
	 ## generating input list for sky 
        print("iname ",iname," iaxis3=",iaxis3)
        comtmp1 = mktemp("_icccom")
	 IF (iaxis3 == 4)
	   imslice(iname//"[*,*,1,*]",comtmp1,3,ver-,>& "dev$null")
	 IF (iaxis3 == 3)  
	   imslice(iname,comtmp1,iaxis3,ver-,>& "dev$null")
	 sections(comtmp1//"*", >>im_list)
         print("comtmp1 ",comtmp1)

   }    
   wcsreset("@"//im_list,"physical",verbose=no,>& "dev$null")

   imcombine("@"//im_list,outputbg1,combine="median",offsets="",
     masktype="none",project=no,outtype="real",zero="none", scale="mode",
     reject="avsigclip",weight="none",lsigma=3,hsigma=3,sigscal=0.1)

   #imdel("@"//im_list,verify=no)
   print  ("im_list ",im_list)
   delete("@"//im_list,verify=no)
   
	 
# Now scanning through dark flats
 if (inputdk != "") 
 {
   in_im = mktemp("_iralin")
   files(inputdk,sort-,>in_im)
     print("")
     print("Compiling dark flats. Please wait!!!")
     ilist = in_im

     im_list = mktemp("_cfllst")
     while (fscan(ilist, iname) != EOF) {
           print("iname ",iname)
           imgets(iname, para="i_naxis")	      
           iaxis3=int(imgets.value)
	   ## generating input list for sky 
           comtmp1 = mktemp("_icccom")
	   IF (iaxis3 == 4)
	     imslice(iname//"[*,*,1,*]",comtmp1,3,ver-,>& "dev$null")
	   IF (iaxis3 == 3)  
	     imslice(iname,comtmp1,iaxis3,ver-,>& "dev$null")
	   sections(comtmp1//"*", >>im_list)
	   #wcsreset("@"//im_list,"world",verbose=no,>& "dev$null")

     }    

     wcsreset("@"//im_list,"physical",verbose=no,>& "dev$null")

     imcombine("@"//im_list,outputdk,combine="median",offsets="",
       masktype="none",project=no,outtype="real",zero="none", scale="mode",
       reject="avsigclip",weight="none",lsigma=3,hsigma=3,sigscal=0.1)

     print ("subtracting bright-dark: ",outputbg1,", ",outputdk,", ",output1)
     imarith(outputbg1,"-",outputdk,output1) 
     
     print ("deleting im_list dark ",im_list)
     delete("@"//im_list,verify=no)
     #imdel("@"//im_list,ver-)

    } else {

      imcopy(outputbg1,output1)
    }

    
    ## now normalize by median
   imstatistics(output1,fields="midpt",format=no) | scan(md)
   imarith(output1,"/",md,output)

   delete("_cfllst*")
   delete("_iralin*")
     
end
