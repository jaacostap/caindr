#!/usr/bin/python
#-*- coding: utf-8 -*-

'''
Created by Carlos José Díaz Baso
Cambia el final de los nombres X.fit a X.fits
'''

def adds(x):
	L=open(x,'r')
	s='s\n'
	S='s'
	f=open(x+S, 'w')
	for i in L:
  		f.write(i[:-1]+s)

	f.close()
	L.close()

#Importo lo necesario para el desarrollo del programa
import sys, os, string

o=open('lista_group',"r")

for cadagrupo in o:
	cadagrupo=string.strip(cadagrupo)
	adds(cadagrupo)
	#os.system('rm '+cadagrupo)
o.close()

print '\n'
print ' <<------ Adición de "s" final terminada ----->> '
print '\n'
