#!/usr/local/bin/python
# -*- coding: utf-8 -*-

"""
flat.py
Created by Carlos J. Díaz on 2012-11.
Creacion de master-flats por filtros, division de objetos por filtros
"""

#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import sys, os, string, numpy

#Y las funciones del iraf
iraf.imred()
iraf.ccdred()
iraf.caindr()


#DIRECTORIO DE CAIN/CAIN.DAT
#dircain='/home/carlos/caindr/'

#Ahora dividimos todas las imágenes en objetos y flats

iraf.setinstrument(instrume= "cain",site="cain",directo="/usr/pkg/iraf/iraf-2.16/IAClocal/iac_local/ccddb/",review="no")
iraf.ccdgroup("@all.tex",output="lis",group="ccdtype")

#Comprobamos que las listas no estan vacías
if (os.path.exists("lisflat") == False):
	print "---------------------------"
	print "-----<[ No hay flats ]>----"
	print "---------------------------"
if (os.path.exists("lisobject") == False):
	print "--------------------------------"
	print "------<[ No hay imágenes ]>-----"
	print "--------------------------------"

#Eliminamos los flats saturados o defectuosos

f=open("lisflat","r")
for flat in f:
	estadis=iraf.imstat(flat[:-1],format="no",\
	fields="mean,max",Stdout=1)
	med=float(estadis[0].split()[0])
	maxi=float(estadis[0].split()[1])
#Quito flats saturado o fuera de rango
	maxsat=21500
	medsat=6000
	xsat=20
#Prueba para detectar flats saturados: medida de la desviacion de dos columnas 
	estad_col1=iraf.imstat(flat[:-1]+"[158:159,10:246,1]",format="no",\
	fields="mean",Stdout=1)
	estad_col2=iraf.imstat(flat[:-1]+"[158:160,10:246,1]",format="no",\
	fields="mean",Stdout=1)
	mean_col1=float(estad_col1[0].split()[0])
	mean_col2=float(estad_col2[0].split()[0])
	x=(numpy.std([mean_col1,mean_col2])/1)
	if (maxi > maxsat) or (x > xsat):
		print "--------------------"
		print flat[:-1],"es un flat saturado, eliminado."
		print maxi
		e=open('flaterror.log','a') 
		e.write('%s' % (flat)) #Añadido a la lista flaterror.log
		e.close()
#Creo una lista de flats dark y bright
	elif (med > medsat):
		print "--------------------"
		print flat[:-1],"es un flat brillante."  
		b=open("lisflat_bright",'a') 
		b.write('%s' % (flat)) #Añadido a la lista bright
		b.close()
	elif (med < medsat):
		print "--------------------"
		print flat[:-1],"es un flat oscuro."  
		d=open("lisflat_dark",'a')		
		d.write('%s' % (flat)) #Añadido a la lista dark
		d.close()
		print "--------------------"
f.close()

#Comprobamos que las listas no estan vacías y
#Separamos los flats en filtros
if os.path.exists("lisflat_bright"):# == True:
	iraf.ccdgroup("@lisflat_bright",output="lisflat_bright",group="subset")
	os.system("rm lisflat_bright")
else:
	print "--------------------------------------"
	print "-----<[ No hay flats brillantes ]>----"
	print "--------------------------------------"

if os.path.exists("lisflat_dark"):# == True:
	iraf.ccdgroup("@lisflat_dark",output="lisflat_dark",group="subset")
	os.system("rm lisflat_dark")
else:
	print "-------------------------------------"
	print "------<[ No hay flats oscuros ]>-----"
	print "-------------------------------------"

#Ahora dividimos los objetos por filtros
os.system("mv lisobject listaob")
#os.system("rm lisobj*")
iraf.ccdgroup("@listaob",output="lisobj",group="subset")


#Reviso los filtros utilizados
os.system("ls lisflat_bright* > lista_tiposf")
t= open("lista_tiposf","r")
for cadalista in t:
	filtro=cadalista[14:(len(cadalista)-1)]
	print "---------------"
	print "Filtro=",filtro
	print "---------------"

#Combinamos los flats
	if os.path.exists('lisflat_dark'+filtro):    
		iraf.cmkflat(inputbg="@lisflat_bright"+filtro,inputdk="@lisflat_dark"+filtro,outputbg="Flat_bright"+filtro, outputdk="Flat_dark"+filtro,output="Flat"+filtro)
     
	else:
		iraf.cmkflat(inputbg="@lisflat_bright"+filtro,inputdk="",outputbg="Flat"+filtro,outputdk="",output="")

t.close()


#os.system("rm lisflat*")
os.system("rm lista_tiposf")


print '\n'
print ' <<------ Creacion de master-flats por filtros y division de objetos por filtros hecha ----->> '
print '\n'


