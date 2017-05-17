#!/usr/bin/python
# -*- coding: utf-8 -*-

print '\n'
print '	+------------------------------------------------+'
print '	|          CAIN pipeline reduction               |'
print '	|                                                |'
print '	|  Developed by Carlos J.Díaz and C. Zurita-IAC  |'
print '	|      based on the IRAF routines CAINDR         |'
print '	|      by R. Barrena and J. Acosta - IAC         |'
print '	|  Please report any problems to czurita@iac.es  |'
print '	+------------------------------------------------+'
print '\n\n'

#Importo lo necesario para el desarrollo del programa
import sys, os, string

#Añadimos un argumento especificando el dia de las imagenes que vamos a reducir
argc = len(sys.argv)
if argc==3:
	dia=sys.argv[1]
	Mensaje=sys.argv[2]
	if Mensaje != 'y' and Mensaje != 'n':
		print '	Si el nombre de todas las imagenes lleva la signatura (Xa, Xb, ...)\n	 "y", sino es así "n".\n\n'
		exit()
	else:
		pass
else:
	print '	Falta especificar el día de la reducción y/o si el nombre\n	de todas las imagenes lleva la signatura (Xa, Xb, ...) con "y",\n	sino es así con "n".\n\n	Ejemplo: python cain.py 06nov12 y\n'
	exit()

#Creamos un directorio nuevo para reducir las imagenes.
#Trabajamos en la maquina cir.
#Las imagenes crudas estan en los directorios de cada noche dentro de /scratch/cir/
#Las reducidas van a estar en: /scratch/cir/reduccion/, dentro de un directorio para cada noche.
#Hay que copiar las imagenes de cir, para lo que hay que introcir el password de obstcs1

path0='/scratch/CAIN/'
path_raw=path0+'/raw_images/'+dia+'/'
path_red=path0+'/red_images/'+dia+'/'

os.chdir('/scratch/CAIN/')
if os.path.exists(path_red):
	os.system('rm -r ' +path_red)
os.system('mkdir '+path_red)

if os.path.exists(path_raw):
	os.system('rm -r ' +path_raw)
os.system('mkdir '+path_raw)

#Empezamos copiando las imagenes de 'cir' a 'cela'
print '-------------------------------------------'
print '     Please, write the obstcs2 password    '
print '-------------------------------------------'

os.system('scp obstcs2@cir:/scratch/cir/'+dia+'/*.fit '+path_raw)

#Y por seguridad copio tambien las imagenes al directorio de reduccion

os.system('cp '+path_raw+'*fit '+path_red)

#Creo una lista con todos las imágenes 
os.chdir(path_red)
if (os.path.exists("all.tex")):
    os.system("rm all.tex")
os.system('ls '+dia+'*fit > all.tex')

#Para guardar los Warning's y que no salgan por pantalla
#sys.stdout = open('log-stdout.txt', 'a')
sys.stderr = open('log-stderr.txt', 'a')

#Contiene el directorio de CAIN/CAIN.DAT!!!!
#Creacion de master-flats por filtros, division de objetos por filtros

import flat
flat

#Correccion de flat y pixeles malos a las imagenes
#--> Poner el directorio que lleva la mascara de los pixeles malos de cain
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

#Sustracción del cielo a cada grupo de imagenes
import cielo
cielo

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
print '	--> Limpiando y creando directorios...'

###############################################################

#Creo un nuevo directorio con las imagenes finales
os.system('mkdir Final_Images')
path_red_new=path_red+'Final_Images/'
os.system('cp FINAL*'+' ' +path_red_new)

#Creo un nuevo directorio con las imagenes corregidas de cielo
os.system('mkdir Clean_Images')
path_red_new=path_red+'Clean_Images/'
os.system('rm sbf*fit*fits')
os.system('cp sbf*.fits'+' '+path_red_new)
os.system('cp lis*'+' '+path_red_new)

#Creo un nuevo directorio con los Flats finales
os.system('mkdir Final_Flats')
path_red_new=path_red+'Final_Flats/'
os.system('cp Fla*'+' '+path_red_new)
os.system('rm Fla*')

###############################################
os.chdir(path_red)
os.system('rm sbf*fits')
os.system('rm FINAL*')
os.system('rm z*')
os.system('rm *obj.1')
os.system('rm *shifts*')
os.system('rm csbf*')
os.system('rm file*')
os.system('rm lis*')
#os.system('rm *obj*')
os.system('mv all.tex all.log')
os.system('rm '+'bf'+dia+'*.fit')
os.system('rm '+dia+'*.fit')
os.system('rm '+'f'+dia+'*.fit')
os.system('rm _*')
os.system('rm subditsky.log')
os.system('rm subsets')

print '\n'
print '	+-----------------------------------------------+'
print '	|             Reduccion finalizada              |'
print '	+-----------------------------------------------+'
print '\n'
print '	Se han creado las siguientes listas de errores:\n	-Para los flats saturados flaterror.log\n	-Para las imágenes de objetos erróneas Imgerror.log\n	-Para las imágenes de objetos sin estrellas Errorfind.log\n'
