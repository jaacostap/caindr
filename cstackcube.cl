# IRAF script -- to combine image cube into a single image, compute offsets automatically
#
# JAP, Oct 2009  - modificar forma crear fichero de entrada a imcombine usando
#   		   imslice y argumentos
procedure cstackcube(input,output)

string 	input		{prompt="List of input image cubes"}
string 	output		{prompt="List of output images"}
string	fstars		{prompt="Position file of stars considered"}
real	threshold	{10,prompt="Detection threshold (S/N ratio)"}
real	fwhmpsf		{2.,prompt="FWHM of the PSF in pixels"}
string 	outshift	{"",prompt="Shift file  result of images"}
string	combine		{"average",enum="average|median",prompt="Type of combine operation"}
string  scalecomb	{"offset",enum="none|offset",prompt="Offset median level of images?"}
string	reject		{"none",enum="none|sigclip|pclip|minmax",prompt="Type of rejection"}
int 	boxsize		{7,min=1,prompt="Size of the fine centering box"}
int	bigbox		{11,min=1,prompt="Size of the coarse centering box"}
bool	dispstars	{no,prompt="Display the reference image with stars used for alignment?"}
real	roundhi 	{0.3,prompt="Upper ellipticity level (starfind algorithm)"}
real	sharplo		{0.5,prompt="Lower sharpness limit"}
real	sharphi		{2,prompt="Upper sharpness limit"}
real	lower		{INDEF,prompt="Lower threshold for data"}
real	upper		{INDEF,prompt="Upper threshold for data"}
int	niterate	{3,prompt="Maximum number of iterations"}
bool	verbose		{no,prompt="Verbose?"}

struct *list1 		{prompt="Ignore this parameter"}
struct *list2	 	{prompt="Ignore this parameter"}
struct *list3	 	{prompt="Ignore this parameter"}
struct *list4	 	{prompt="Ignore this parameter"}
struct *list5           {prompt="Ignore this parameter"}


begin

string  imref, im1, out1, sltmp, slclst, censhift,ocrds, dumm, stpos, cenim, inim, cmblst,zer1
file	inlist,olist
string  immd, stpos_clean
int	ndim, xxsh_int, yysh_int, ifs, nimag,nsc,npos
real	xxsh, exxsh, yysh, eyysh, hwhmpsf, athreshold, fsigma, dmin, dmax, xpos, ypos
struct  dumm1
bool	verb1

## open loop upon image list

inlist = mktemp("_slcilst")
olist = mktemp("_slcolst")
files(input,>inlist)
files(output,>olist)

list1 = inlist
list2 = olist

verb1 = verbose

fsigma = threshold

while (fscan(list1,im1) != EOF) 
 {
    nsc = fscan(list2,out1)
    if (nsc == 0) 
      goto end_out
    
    imgets(im1,para="i_naxis")
    ndim = int(imgets.value)

    sltmp = mktemp("_slctmp")
    imslice(im1,sltmp,slice_dimens=ndim,verb-)

    slclst = mktemp("_slclst")
    files(sltmp//"*.fits",>slclst)

    if (outshift != "") 
      ocrds = ocoords
    else 
      ocrds = mktemp("_slcocrds")

    cmblst = mktemp("_slcmblst")

    list3 = slclst 
    nimag  = 1
    while (fscan(list3,inim) != EOF)
      {
	if (nimag > 1) {
	  ## determine centroid of stars and offset wrt imref
	   censhift = mktemp("_slccnshft") 
	   cenim = mktemp("_slccnm") 
	   print(inim,>cenim)
	   imcentroid("@"//cenim,imref,stpos,shift="",boxsize=boxsize,bigbox=bigbox,
	     negative=no,verb+,>censhift)
	   list4 = censhift 
	   while (fscan(list4,dumm) != EOF)
	     {
	       if (dumm == "#Shifts")
		 {
        	   ifs = fscanf(list4,"%s %f (%f) %f (%f)",dumm,xxsh,exxsh,yysh,eyysh)
		       nsc = nscan()
		       if (nsc > 0) {
			 xxsh_int = nint(xxsh) 
			 yysh_int = nint(yysh) 
			 print(xxsh_int," ",yysh_int,>>ocrds)
                	 print(inim,>>cmblst)
		       } else 
			 print("Warning: Shift cannot be determined for image slice ",nimag)
		 }
	     }
	   delete(censhift,ver-)
	   delete(cenim,ver-)	 
	 } else {
	  ## set reference image and initialize offset file
	   imref = inim
	   print("imref ",imref)   
	   stpos = mktemp("_slcstps")
           stpos_clean = mktemp("_slcstpscln")
	   hwhmpsf = fwhmpsf / 2.
           immd = mktemp("_cstkcbmd")
           median(imref,immd,xwin=3,ywin=3,boundary="reflect",constant=0.)
           cstatistic(imref,maxiter=2,addheader=no,lower=INDEF,upper=INDEF,oneparam="all",
               verbose=no,print=no)
           athreshold = fsigma * (cstatistic.quart3-cstatistic.quart1)/1.36 ## + cstatistic.median
           dmin = cstatistic.median - 10.*(cstatistic.quart3-cstatistic.quart1)/1.36
           print("athreshold ",athreshold)
	   starfind(immd,output=stpos,hwhmpsf=hwhmpsf,threshold=athreshold,verb-,
                     roundhi=roundhi,sharphi=sharphi,sharplo=sharplo,datamin=dmin,
                     datamax=15000)
           if (dispstars) 
              display(imref,1, >& "dev$null")
           #display(immd,2, >& "dev$null")
           list5 = stpos
           npos=0
           xpos=0.
           ypos=0.
           dumm1 = ""
           while (fscan(list5,dumm1) != EOF) 
            {
                    nsc = fscanf(dumm1,"%f %f",xpos,ypos)  
                    if (nsc > 0 )
                     { 
                      npos += 1
                      if (npos == 1)
                        {
                 	   print(0," ",0,>ocrds)
	                   print(inim,>cmblst)
                        }
                      if (verb1) 
                         print("xpos:",xpos," ypos:",ypos)
                     }
            }
           #tvmark(stpos,1,mark="plus")
           if (dispstars) 
             tvmark(1,stpos,mark="circle",color=215,radii=5)
           imdel(immd,ver-,>>"dev$null")
           if (npos == 0)
               {
                  beep ;beep ;beep 
                  print("ERROR: No stars suitable for alignment could be identified")
                  goto cleanup
               }
           else 
               {
                 if (verb1)
                   print("Found ",npos," stars at reference image") 
	       }		
	 }   
	 nimag += 1 
      }
    
    if (scalecomb == "offset") 
      zer1="median" 
    else 
      zer1="none"
    imcombine("@"//cmblst,out1,combine=combine,reject=reject,offsets=ocrds,zero=zer1)
    
    imdel ("_slctmp*",ver-)

    delete (slclst,ver-)
    if (outshift == "") 
	 delete (ocrds,ver-)

    delete (cmblst,ver-)  
    delete (stpos,ver-)
    
 }
 

## clean up
cleanup:
 delete(inlist,ver-)
 delete(olist,ver-)
 delete(stpos_clean,ver-)
 list1 = ""
 list2 = ""
 list3 = ""
 list4 = ""
 list5 = "" 

bye 

end_out : print("ERROR: Number of output images is smaller than input cubes")
          bye

no_files : print("ERROR: No valid images")
           bye 


end
