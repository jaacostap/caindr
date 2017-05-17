#!/usr/bin/python
# -*- coding: utf-8 -*-

# Console colors
W  = '\033[0m'  # white (normal)
R  = '\033[31m' # red
G  = '\033[32m' # green
O  = '\033[33m' # orange
B  = '\033[34m' # blue
P  = '\033[35m' # purple
C  = '\033[36m' # cyan
GR = '\033[37m' # gray

print C+'\n'
print '	+------------------------------------------------+'
print '	|          '+G+'CAIN pipeline reduction'+C+'               |'
print '	|                                                |'
print '	|  '+W+'Developed by Carlos J.Diaz and C. Zurita-IAC'+C+'  |'
print '	|      '+W+'based on the IRAF routines CAINDR'+C+'         |'
print '	|      '+W+'by R. Barrena and J. Acosta - IAC'+C+'         |'
print '	|  '+W+'Please report any problems to czurita@iac.es'+C+'  |'
print '	+------------------------------------------------+'+W
print '\n\n'

#Importo lo necesario para el desarrollo del programa
import sys, os
import subprocess

#sys.exit()

#We add an argument with the of of the observation. // Anadimos un argumento especificando el dia de las imagenes que vamos a reducir.
argc = len(sys.argv)
if argc==3:
	dia=sys.argv[1]
	Mensaje=sys.argv[2]
	if Mensaje != 'y' and Mensaje != 'n':
		print '	If the name of images ends as (Xa, Xb, ...) press "y", \n  if not "n".\n\n Example : python cain.py 06nov12 y \n '
		# '	Si el nombre de todas las imagenes lleva la signatura (Xa, Xb, ...)\n	 "y", sino es así "n".\n\n'
		exit()
	else:
		pass
		
	
#if argc==4:
#	dia=sys.argv[1]
#	Mensaje=sys.argv[2]
#	size=sys.argv[3]
		

else:
        print ' Missing reduction day or mode (If the name \n of images ends as (Xa, Xb, ...) press "y", \n if not press "n". \n\n Example : python cain.py 06nov12 y \n '
	#Falta especificar el día de la reducción y/o si el nombre\n	de todas las imagenes lleva la signatura (Xa, Xb, ...) con "y",\n	sino es así con "n".\n\n	Ejemplo: python cain.py 06nov12 y\n'
	exit()

#Creamos un directorio nuevo para reducir las imagenes.
#Trabajamos en la maquina cir.
#Las imagenes crudas estan en los directorios de cada noche dentro de /scratch/cir/
#Las reducidas van a estar en: /scratch/cir/reduccion/, dentro de un directorio para cada noche.
#Hay que copiar las imagenes de cir, para lo que hay que introducir el password de obstcs1

#path0='/scratch/CAIN'
#path_raw=path0+'/raw_images/'+dia+'/'
#path_red=path0+'/red_images/'+dia+'/'
path_root=dia
path_raw=dia+'/raw/'
path_red=dia+'/pipe/'


os.chdir(path_root)
if os.path.exists(path_red):
	os.system('rm -r ' +path_red)
os.system('mkdir '+path_red)

#if os.path.exists(path_raw):
#	os.system('rm -r ' +path_raw)
#os.system('mkdir '+path_raw)

#Empezamos copiando las imagenes de 'cir' a 'cela'
#print '-------------------------------------------'
#print '     You must be logged as obstcs2         '
#print '     Please, write the obstcs2 password    '
#print '-------------------------------------------'

#username = subprocess.check_output("whoami").strip()

#if (username != 'obstcs2'):    
#    print '--------------------------------------------'    
#    print 'You are '+username+'. Please, log as obstcs2'
#    print '--------------------------------------------'
#    sys.exit()
#else:
#    os.system('cp /net/cir/scratch/cir/'+dia+'/*.fit '+path_raw)

#os.system('scp obstcs2@cir:/scratch/cir/'+dia+'/*.fit '+path_raw)

#Y por seguridad copio tambien las imagenes al directorio de reduccion
os.system('cp '+path_raw+'*fit '+path_red)

#Creo una lista con todas las imagenes 
os.chdir(path_red)
##if (os.path.exists("all.tex")):
##    os.system("rm all.tex")
#os.system('ls '+dia+'*fit > all.tex')

os.system('ls *fit > all.tex')
#Para guardar los Warning's y que no salgan por pantalla
#sys.stdout = open('log-stdout.txt', 'a')
##sys.stderr = open('log-stderr.txt', 'a')

#Contiene el directorio de CAIN/CAIN.DAT!!!!
#Creacion de master-flats por filtros, division de objetos por filtros

import flat
flat

#Correccion de flat y pixeles malos a las imagenes
#--> Poner el directorio que lleva la mascara de los pixeles malos de cain!!
import correccion
correccion

##########################################################
if Mensaje=='n':
	#Separa las imagenes en base al tiempo
	import divt
	divt
else:
	#Separa las imagenes en base al nombre
	import div
	div

#Sustraccion del cielo a cada grupo de imagenes
import cielo
cielo
'''
if size=='p':
	#PARAAA!!
	sys.exit()
'''
#Cambia el final de los nombres X.fit a X.fits 
#y los lista como lis*s
import adds
adds


#Medicion del offset entre cada una de las imagenes.
import offset
offset


#Separa las imagenes de un cubo y les añade su offset correspondiente.
import slicef
slicef

#Busco las estrellas; alineo las imágenes y las combino
import ds9
ds9


print '\n'
print '	--> Cleaning and creating directories ...' #Limpiando y creando directorios...

###############################################################
os.system('rm file*')
#Creating a new dir with  Final-Images // Creo un nuevo directorio con las imagenes finales
os.system('mkdir Final_Images')
path_red_new=path_red+'Final_Images/'
os.system('cp aFINAL*'+' ' +path_red_new)

#Creating a new dir with sky-clean // Creo un nuevo directorio con las imagenes corregidas de cielo
os.system('mkdir Clean_Images')
path_red_new=path_red+'Clean_Images/'
os.system('rm sbf*fit*fits')
os.system('rm FINAL*fits')
os.system('cp sbf*.fits'+' '+path_red_new)
os.system('cp lis*'+' '+path_red_new)

#Creating a new dir with Final Flats // Creo un nuevo directorio con los Flats finales
os.system('mkdir Final_Flats')
path_red_new=path_red+'Final_Flats/'
os.system('cp Fla*'+' '+path_red_new)
os.system('rm Fla*')

###############################################
#CLEANING
os.system('rm sbf*fits')
os.system('rm aFINAL*')
os.system('rm z*')
os.system('rm csbf*')
os.system('rm *cat')
os.system('rm *shft')
os.system('rm file*')
os.system('rm lis*')
os.system('rm *obj*')
os.system('mv all.tex all.log')
os.system('rm '+'bf'+dia+'*.fit')
os.system('rm '+dia+'*.fit')
os.system('rm '+'f'+dia+'*.fit')
os.system('rm _*')
os.system('rm subditsky.log')
os.system('rm subsets')
os.system('rm cFINAL*')

print '\n'
print '	+-----------------------------------------------+'
print '	|                 Ready !!!!!!!!!!              |'
print '	+-----------------------------------------------+'
print '\n'
#print '	Se han creado las siguientes listas de errores:\n	-Para los flats saturados flaterror.log\n	-Para las imagenes de objetos erroneas Imgerror.log\n	-Para las imagenes de objetos sin estrellas Errorfind.log\n'

print '    The reduced images are in /scratch/CAIN/red_images/'+dia
print '    There you can find these directories:'
print '       - Clean_Images: Containing the reduced images (Flats+Bad pixles+Sky)'
print '       - Final_Flats: The flats'
print '       - Final_Images: The reduced and combined images'
print '    There is a copy of the raw data in /scratch/CAIN/raw_images/'+dia
print '    ------------------------------------------------------------------'
print '    Errors:'
print '        - flaterror.log: list containing saturated flats'
print '        - Imgerror.log: bad images'
print '        - Errorfind.log: images with no stars'
print '    -------------------------------------------------------------------'
