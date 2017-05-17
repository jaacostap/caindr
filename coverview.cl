procedure coverview (input,output)

string input     {prompt="Input images"}
string output    {prompt="Output coadded image"}

begin

 subditsky(input,prefix="_tmp",combine="median",inidisc=0,scaleco="none", 
  nhigh=0.4,nlow=0.05,masktyp="none",maskval=0.,scalesu="offset",delsky=no,
  skyname="default",logfile="subditsky.log")
 
 cicomb_cub("_tmp*.fits",output,combine="average",outshif="_off",
  reject="none",ref_pla=1,roundc=no,verbose=no)
  
 # Cleaning up
   imdel("sdcom*.fits")  
   delete("_*",ver-,>>"dev$null")
   delete("ldedi*",ver-, >& "dev$null") 

end
