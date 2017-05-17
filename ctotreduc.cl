procedure ctotreduc (input,output,inpflatbg,inpflatdk,maskn,flatb,skyname)

string input     {prompt="Input images"}
string output    {prompt="Output coadded image"}

string inpflatbg {prompt="Input images of bright flats"}
string inpflatdk {prompt="Input image of dark flats"}
string maskn     {prompt="Input badpixel mask (default|file)"}
string flatb     {prompt="Output flat (Bright one will be used)"}
string skyn      {prompt="Output sky image"}


begin

string images

## Construye flat-field
 cmkflat(inputbg=inpflatbg,inputdk=inpflatdk,outputbg=flatb,outputdk="_flatdk",
  output="_flat")
  
## corrige de flat-field
 images=input
 cflatcub(images,"tmpf",flat=flatb,normal=yes)
 
## corrige de pixeles calientes
 cbadpix("tmpf*.fits","tmpb",immask=mask)
 
## sustrae el cielo, resultan imagenes con prefijo s
 subditsky("tmpb*.fits",prefix="tmps",combine="median",inidisc=0,scaleco="none", 
  nhigh=0.4,nlow=0.05,masktyp="none",maskval=0.,scalesu="offset",delsky=no,
  skyname=skyn,logfile="subditsky.log")
 
## combina imagenes 
 cicomb_cub("tmps*.fits",output,combine="average",outshif="_off",
  reject="none",ref_pla=1,roundc=no,verbose=no)
  
## Cleaning up temporary files
   imdel("sdcom*.fits")  
   imdel("tmp*.fits")  
   delete("_*",ver-,>>"dev$null")
   delete("ldedi*",ver-, >& "dev$null") 

end
