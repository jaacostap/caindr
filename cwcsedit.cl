# cwcsedit - add keywords to header 
# 
procedure cwcsedit (input)

string  input    {"",prompt="List of images to be corrected"}
string	racent	 {"",prompt="RA of the field center (hh:mm:ss)"}
string	deccent	 {"",prompt="Dec of the field center (dd:mm:ss)"}
real    cd11     {2.8236e-4,prompt="CD1_1"}
real  cd22       {-2.8069e-4,prompt="CD2_2"}
real   cd12      {5.5483e-6,prompt="CD1_2"}
real  cd21       {5.5167e-6,prompt="CD2_1"}
bool  correct    {yes,prompt="Perform the correction?"}

string *list1 	{prompt="Ignore this parameter"}

begin

real 	pixscl,wxoff1,wyoff1,crval1,crval2,crval1_all,crval2_all,cd11_0,cd12_0,cd21_0,cd22_0 
int     racent_hh,racent_mm,deccent_dd,deccent_mm
int     racent_ss,deccent_ss
string 	ini,ilist,camera,deccent_sg
int	icam=0
int     ierr=0


## check pixel scale 
#if (instr == "liris") {
#  pixscl = 0.25
#}

wxoff1 = 0
wyoff1 = 0

cd11_0 = cd11
cd12_0 = cd12
cd21_0 = cd21
cd22_0 = cd22


ilist = mktemp("_cwcsdtlst")
sections(input,option="fullname",> ilist)

if (racent != "")
 {
    print (racent) | scanf("%d:%d:%d",racent_hh,racent_mm,racent_ss)
    print ("ra_cent_hh=",racent_hh," ra_cent_mm=",racent_mm," ra_cent_ss=",racent_ss)
    crval1_all=(racent_hh+racent_mm/60.+racent_ss/3600.)*15.
 }
if (deccent != "") 
 {
    print (deccent) | scanf("%d:%d:%d",deccent_dd,deccent_mm,deccent_ss)
    print ("dec_cent_hh=",deccent_dd," dec_cent_mm=",deccent_mm," dec_cent_ss=",deccent_ss)
    crval2_all=(deccent_dd+deccent_mm/60.+deccent_ss/3600.)
 }

list1 = ilist

while (fscan(list1,ini) != EOF)
  {
   ## check if coordinates have been corrected 
   imgets(ini,"WCSCORR")
   ierr = int(imgets.value)
    print ("image - ierr=",ierr,ini)
        
        
    imgets(ini,"CAMERA")
    camera = imgets.value
    print ("imgets camera ",imgets.value)
    imgets(ini,"CRVAL1")
    print ("imgets crval1 ",imgets.value)
    if (imgets.value == "" || imgets.value == "0") 
      {
         print ("CRVAL1 undefined - Setting from RA")
         imgets(ini,"RA")
         if (imgets.value != "")
           {
             print (imgets.value) | scanf("%d:%d:%d",racent_hh,racent_mm,racent_ss)
             print ("ra "" _hh=",racent_hh," _mm=",racent_mm," _ss=",racent_ss)
             crval1=(racent_hh+racent_mm/60.+racent_ss/3600.)*15.
             if (correct) 
               { 
                 print ("setting crval1 in hdr ",crval1)
                 hedit (ini,"crval1",crval1,ver-,add+,upd+,>>& "dev$null")
               }
           }
      }
    imgets(ini,"CRVAL2") 
    #print ("imgets crval2 ",imgets.value)
    if (imgets.value == "" || imgets.value == "0") 
      {
         print ("CRVAL2 undefined - Setting from DEC")
         imgets(ini,"DEC")
         if (imgets.value != "")
           {
             print (imgets.value) | scanf("%1s%2d:%2d:%2d",deccent_sg,deccent_dd,deccent_mm,deccent_ss)
             print ("dec ","_sg=",deccent_sg," _hh=",deccent_dd," _mm=",deccent_mm) #," _ss=",deccent_ss)
             deccent_ss = 0
             crval2=(deccent_dd+deccent_mm/60.+deccent_ss/3600.)
             if (deccent_sg == "-")
               crval2=-1*crval2
             #print ("crval2 ",crval2) 
             if (correct) 
               { 
                 print ("setting crval2 in hdr ",crval2)
                 hedit (ini,"crval2",crval2,ver-,add+,upd+,>>& "dev$null")
               }
           }
      }
    
    if (camera == "W") 
       icam = 1
    if (camera == "N") 
       icam = 2
    switch (icam) { 
      case 1: pixscl = 2.777e-4 
      case 2: pixscl = 1.111e-4 
      default: ierr = 1
    }
    print ("ierr=",ierr)
    if (ierr == 0 && correct)
    {
      print ("correcting wcs")
      if (cd11_0 != 0) 
         hedit (ini,"cd1_1",cd11_0,ver-,add+,upd+,>>& "dev$null")
      if (cd12_0 != 0) 
         hedit (ini,"cd1_2",cd12_0,ver-,add+,upd+,>>& "dev$null")
      if (cd21_0 != 0) 
         hedit (ini,"cd2_1",cd21_0,ver-,add+,upd+,>>& "dev$null")
      if (cd22_0 != 0) 
         hedit (ini,"cd2_2",cd22_0,ver-,add+,upd+,>>& "dev$null")
      #hedit (ini,"crpix1",129,ver-,add+,upd+,>>& "dev$null")
      #hedit (ini,"crpix2",129,ver-,add+,upd+,>>& "dev$null")
      #hedit (ini,"RA",racent,ver-,add+,upd+,>>& "dev$null")
      #hedit (ini,"DEC",deccent,ver-,add+,upd+,>>& "dev$null")
      hedit (ini,"CTYPE1","RA---TAN",ver-,add+,upd+,>>& "dev$null")
      hedit (ini,"CTYPE2","DEC--TAN",ver-,add+,upd+,>>& "dev$null")
      #hedit (ini,"WCSDIM",2,ver-,add+,upd+,>>& "dev$null")
      ## changing epoch to 2000 to avoig GAIA bug 
      hedit (ini,"EPOCH",2000,ver-,add+,upd+,>>& "dev$null")
      hedit (ini,"WCSCORR",1,add+,upd+,ver-,>>& "dev$null")  
    }  
       

  }
  

delete(ilist,ver-,>>& "/dev/null") 

end 
