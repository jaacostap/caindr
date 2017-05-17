#!/usr/local/bin/python
# -*- coding: utf-8 -*-

'''
ds9.py
Created by Carlos J. Díaz on 2012-12.
Busco las estrellas; alineo las imágenes y las combino
'''
#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import sys, os, string

#Y las funciones del iraf
iraf.images()
iraf.imcoords() #starfind
iraf.immatch()
iraf.noao()
iraf.imred()
iraf.ccdred()
iraf.imutil()



def file_len(fname):
    with open(fname) as f:
        for i, l in enumerate(f, 1):
            pass
    return i


def plusoff(x):
	o=open(x,'r')
	f=open('p'+x,'a')
	w=0
	for linea in o:
		a=linea.split()
		if w>=16:
			f.write(('%6.5s %6.5s' % (float(a[0])+39,float(a[1])+39))+'\n')
		else:
			pass
		w=w+1

#os.system('rm csbf*')
#os.system('rm FINAL*.fits')
#os.system('rm *.obj.*')

#Para encontrar estrellas en las imágenes
o=open('lista_group','r')
q=open('Errorfind.log','w')
for grupo in o:
	grupo=string.strip(grupo)
	gruposq=string.strip(grupo)+'sq'
	shiftgrupo=grupo+'shiftsq'
	#print gruposq, shiftgrupo
	f=open(gruposq,'r')
	lista_grupo=[]
	for imagen in f:
		lista_grupo.append(imagen)
		imagen0=string.strip(lista_grupo[0])
	iraf.starfind(imagen0+'[40:210,40:210,1]',output='default',hwhmpsf='2',threshol='50',fradius='2.5',sepmin='5',npixmin='5',roundlo='0.05',roundhi='0.4',sharplo='0.5',sharphi='2')
	
#Creo un nuevo offset.obj movido para centrarlo
	plusoff(imagen0+'.obj.1')


#Movemos las imágenes y las alineamos
	if (file_len(imagen0+'.obj.1')) >= 17:
		try:
			iraf.imalign(input='@'+gruposq,referenc=imagen0,coords='p'+imagen0+'.obj.1',output='c//@'+gruposq,shifts=shiftgrupo,boxsize='25',bigbox='35',negativ='no',backgro='INDEF',lower='INDEF',upper='INDEF',niterat='100',toleran='1',maxshif= 'INDEF',shiftim='yes',interp_="linear",boundar='wrap',constan='0.',trimima='yes',verbose='no',mode='h')
		except:
			print 'Error iraf.imalign en grupo '+grupo
			q.write(grupo+'\n')
	else:
		q.write(grupo+'\n')

q.close()
os.system('diff lista_group Errorfind.log  | grep "<" > file1')
os.system("awk '{print $2, $3}' file1 > file2")

#Y por ultimo las combinamos
z=open('file2','r')
for lista in z:
	lista=string.strip(lista)
	lista1=lista+'sq'
	iraf.imcombine(input='c//@'+lista1,output='FINAL'+lista[1:],combine="average",masktype="none",outtype="real",scale="none",project="no",reject="none",weight="none")



