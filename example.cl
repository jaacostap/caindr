## lista con imagenes originales Ks.lst

## sustrae el cielo, resultan imagenes con prefijo s
subditsky n//@Ks.lst  prefix="s" combine="median" inidisc=0 \
  scalecomb="offset" nhigh=0.25 nlow=0.05 scalesub="offset"  


## corrige de flat-field
cflatcub "sn//@Ks.lst" "f" "flat_ks"


## combina imagenes 
cicomb_cub "sn//@Ks.lst" "UXOri_Ks_a" outshif="Ks.shft"
