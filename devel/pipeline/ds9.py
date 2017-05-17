#!/usr/local/bin/python
# -*- coding: utf-8 -*-

'''
ds9.py
Created by Carlos J. Diaz on 2013-12.
Busco las estrellas; alineo las imagenes y las combino
'''
#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import os, string, sys
from function2 import sex,sex2cat,sex2catb


#Y las funciones del iraf
iraf.images()
iraf.imcoords()
iraf.immatch()
iraf.noao()
iraf.imred()
iraf.ccdred()
iraf.imutil()

#####################		ALGUNAS FUNCIONES ... ###################

def file_len(fname):
	#return os.system('wc -l '+fname,stdout=a)
	import subprocess
	proc = subprocess.Popen(['wc -l '+fname], stdout=subprocess.PIPE, shell=True)
	(out, err) = proc.communicate()
	return int(out.split()[0])


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


####################		COMIENZO DE DS9.PY		############################


os.system('rm csbf*')
os.system('rm FINAL*.fits')
os.system('rm aFINAL*.fits')
os.system('rm *.obj.*')
os.system('rm *.cat*')
os.system('rm cFINAL*.fits')

#CON DIV.PY HEMOS DIVIDIDO LAS IMAGENES EN GRUPOS 
#O CICLOS DE POSICIONES. PARA CADA UNO DE ELLOS HACEMOS
#UNA COMBINACION.
o=open('lista_group','r')
qr=open('Errorfind.log','w')
for grupo in o:
	print grupo
	grupo=string.strip(grupo)
	gruposq=string.strip(grupo)+'sq'
	shiftgrupo=grupo+'shiftsq'
	f=open(gruposq,'r')
	lista_grupo=[];c=0;lis_total=[]
	for imagen in f:
		if c==0:
			c=1
			imagen0=imagen
			lista_grupo.append(string.strip(imagen))
		else:
				
			if imagen[:-9] == imagen0[:-9]:
				lista_grupo.append(string.strip(imagen))
			else:
				c=0
				lis_total.append(lista_grupo)

				lista_grupo=[]

				lista_grupo.append(string.strip(imagen))
	lis_total.append(lista_grupo)
	
	
	'''
	#########################################################################################
	##############				ALINEAMIENTO Y COMBINACION DENTRO DEL MISMO CUBO DE IMAGENES
	#########################################################################################
	'''
	#En la variable lis_total estan todas las imagenes divididas por cubos [[1ºcubo],[2ºcubo],...]
	for cubo in lis_total:
		lista_grupo=cubo
		lista1=', '.join(lista_grupo)
		lista2='c'+', c'.join(lista_grupo)
		imagen0=lista_grupo[0]
		imagen0=string.strip(imagen0)
		sex(imagen0)

		sex2catb(imagen0)	#Esta funcion limpia el catalogo de sextractor para que pueda ser leido por imalign
		
		###########################################################################################
		#Bajo el estudio del movimiento "no guiado" del telescopio, tambien denominado deriva, 
		#es posible extrapolar una primera aproximacion del movimiento de deriva
		#para utilizarlo como segunda contribucion al movimiento total y conseguir un mejor 
		#recentrado. Para ello hacemos un mini-alineado de las 3 primeras imagenes:

		#Con imcentroid buscamos las mismas estrellas en imagen 1,2,3....hasta la -3.
		lista_grupo0=lista_grupo[0:-2];
		lista_grupo0=', '.join(lista_grupo0)

		coo0x=[]
		coo0y=[]
		ppp=1
		print imagen0[:-5]+'.obj.1'
		
		#SI LA IMAGEN TIENE SÓLO UNA ESTRELLA NO SE PUEDE COMBINAR YA QUE LA BAJA RELACION
		#SEÑAL-RUIDO HARÁ QUE SEA IMPOSIBLE ENCONTRAR DICHA ESTRELLA EN EL RESTO DE IMÁGENES
		if file_len(imagen0[:-5]+'.obj.1') < 2:
			print '###################  Grupo '+grupo+' sin combinar'
			ppp=0
			break
			
			
		qq=open(imagen0[:-5]+'.obj.1','r')
		for cat in qq:
			cat=cat.split()
			coo0x.append(float(cat[0]))
			coo0y.append(float(cat[1]))

		#RECENTRO AHORA CADA UNA DE LAS ESTRELLAS CON IMCNTR
		coo2=iraf.imcntr(input=lista_grupo0,x_init=coo0x[0],y_init = coo0y[0],cboxsize = '15',Stdout=1)
		#coo2 es una lista

		restax=[]
		restay=[]
		for centro in coo2:
			x=float(centro.split(':')[1][:-1])
			y=float(centro.split(':')[2])
			restax.append(-x+coo0x[0])		#COMO ESTAMOS CALCULANDO DESPLAZAMIENTOS RELATIVOS Restamos estas posiciones a imagen1. 
			restay.append(-y+coo0y[0])

		restax[0]=0.
		restay[0]=0.
		r=range(len(restax))
			
		#Utilizamos la funcion polyfit de numpy. Usamos esta recta para extrapolar el desplazamiento teorico:
		from numpy import polyfit
		zx = polyfit(r, restax, 1)
		zy = polyfit(r, restay, 1)

		#Construimos los shifts Y LOS GUARDAMOS EN UN ARCHIVO.
		rr=open(imagen0[:-5]+'.shft','w')
		for i in range(len(lista_grupo)):
			rr.write(('%8.5s %8.5s' % (zx[0]*i+zx[1],zy[0]*i+zx[1]))+'\n')
			#print zx[0]*i+zx[1],zy[0]*i+zx[1]
		rr.close()
		#######################################################################################
		
		iraf.imalign(input=lista1,referenc=imagen0,coords=imagen0[:-5]+'.obj.1',output=lista2,shifts=imagen0[:-5]+'.shft',boxsize='13',bigbox='17',negativ='no',backgro='INDEF',lower='INDEF',upper='INDEF',niterat='12',toleran='1',maxshif= 'INDEF',shiftim='yes',interp_='linear',boundar='constant',constan='0.',trimima='yes',verbose='no',mode='h')
		iraf.imcombine(input=lista2,output='FINAL_'+imagen0[:-12]+'.fits',combine="median",masktype="none",outtype="real",scale="none",project="no",reject="none",weight="none",logfile = "")
		print 'Image combined'
	#break
	
	if ppp==0:
		print '##############################################################################'
		print '##############################################################################'
		qr.write(grupo+'\n')
		continue	#ESTO SIGNIFICA QUE SI LA IMAGEN TIENE UNA ESTRELLA SOLA QUE PASE AL SIGUIENTE GRUPO PORQUE 
					#VA A SER MUY DIFICIL DE COMBINAR
		
	#Ahora tenemos las imagenes de cada grupo bajo la signatura FINAL_nombre
	#Y ahora toca combinarlas entre sí. Para ello acudimos de nuevo a los offset calculados entre 
	#ellas a partir de las coordenadas.
	
	
		'''
	#########################################################################################
	##############				ALINEAMIENTO Y COMBINACION DE CADA CUBO DE IMAGENES
	#########################################################################################
	'''
	os.system('more '+grupo+'shifts')
	tt=open(grupo,'r')
	file0=tt.readlines()
	tt.close()
	image00='FINAL_sbf'+string.strip(file0[0])+'s'
	
	mk=open(grupo+'shifts','r')
	line_shift=mk.readlines()
	mk.close()
	
	
	sex(image00)
	sex2cat(image00)
	
	print image00[:-5]+'.obj.1'
	
	grupos=grupo+'s'
	
	lista10=[]
	for cada in file0:
		lista10.append(string.strip(cada))
		
	#IMAGENES DEL CUBO COMBINADAS:
	lista1='FINAL_sbf'+'s, FINAL_sbf'.join(lista10)+'s'
	#IMAGENES DEL CUBO COMBINADAS Y ALINEADAS
	lista2='cFINAL_sbf'+'s, cFINAL_sbf'.join(lista10)+'s'
	
	
	####	METODO PARA CALCULAR LOS OFFSET ENTRE LAS IMAGENES	#####
	
	print image00[:-5]+'.cat'
		
	
	#El catalogo de la primera imagen es:
	catalog=image00[:-5]+'.cat'
	
	#SI NO ENCONTRAMOS NINGUNA ESTRELLA EN LA IMAGEN PASAMOS AL 
	#SIGUIENTE GRUPO DE IMAGENES PARA COMBINAR
	if file_len(catalog) ==7:
		print 'IMAGEN SIN ESTRELLA'
		#LO GUARDAMOS EN ERRORFIND.LOG
		continue
	
	cc=open(catalog,'r')
	posx=[]
	posy=[]
	flux=[]
	for star in cc:
		if star[0] != '#':
			star=star.split()
			x=float(star[1])
			y=float(star[2])
			if x > 20. and x < 230. and y > 20. and y < 230.:
				posx.append(float(star[1]))
				posy.append(float(star[2]))
				flux.append(float(star[4]))
	cc.close()
	print flux
	if len(flux)==0:
		#NO HAY ESTRELLAS EN LAS INMEDIASIONES QUE BUSCAMOS
		continue
	#Ordenamos los arrays por orden DE FLUJO PARA ALINEAR CON LAS ESTRELLAS MAS BRILLANTES
	#DE LA IMAGEN
	band=int(0);
	while band==0:
		band=1
		for k in range(0,len(flux)-1):
			if flux[k]<flux[k+1]:
				aux=flux[k+1]
				flux[k+1]=flux[k]
				flux[k]=aux					
					
				aux2=posx[k+1]
				posx[k+1]=posx[k]
				posx[k]=aux2
				
				aux3=posy[k+1]
				posy[k+1]=posy[k]
				posy[k]=aux3
				
				band=0;
	
	lista_todas=lista1.split(',')
	 
	#Posiciones relativas
	from numpy import *
	flux=array(flux);posx=array(posx);posy=array(posy);
	
	flux0=flux
	posx0=posx
	posy0=posy
	
	
	flux=flux/flux[0]
	posx=posx-posx[0]
	posy=posy-posy[0]
	
	#FLUXO,...HACEN ALUSION A LAS ESTRELLAS DE LA PRIMERA IAMGEN
	#QUE ACONTINUACION SERAN COMPARADAS CON LAS RESTANTES
	os.system('rm *shifts2*')
	
	vv=open(grupo+'shifts2','a')
	xx=0.0
	yy=0.0
	vv.write(('%8.5s %8.5s' % (xx,yy))+'\n')
	vv.close()
					
	index=1						
	for ima in lista_todas[1:]:
		
		
		#print where(lista_todas == ima)
		ima=string.strip(ima)
		sex(ima)
		#El catalogo de la primera imagen es:
		catalog2=ima[:-5]+'.cat'
		
		if file_len(catalog2)==7:
			#SI NO ENCONTRAMOS NINGUNA ESTRELLA EN LA IMAGEN PASAMOS AL 
			#SIGUIENTE GRUPO DE IMAGENES PARA COMBINAR
			print grupo+' sin combinar'
			break #CON EL BREAK PARAMOS EL FOR Y COMO NO PODRA ALINEARLAS DARA ERROR Y 
			# APARECERA COMO GRUPO NO COMBINADO
			
		cc2=open(catalog2,'r')
		posx2=[];	posy2=[];	flux2=[];
		for star in cc2:
			if star[0] != '#':
				star=star.split()
				x=float(star[1])
				y=float(star[2])
				if x > 30. and x < 220. and y > 30. and y < 220.:
					posx2.append(float(star[1]))
					posy2.append(float(star[2]))
					flux2.append(float(star[4]))
		
		if len(flux2)==0:
			#NO HAY ESTRELLAS EN LAS INMEDIASIONES QUE BUSCAMOS
			continue
		 
		#DE NUEVO Ordenamos los arrays por orden DE FLUJO PARA BUSCAR LAS ESTRELLAS
		band=int(0);
		while band==0:
			band=1
			for k in range(0,len(flux2)-1):
				if flux2[k]<flux2[k+1]:
					aux=flux2[k+1]
					flux2[k+1]=flux2[k]
					flux2[k]=aux					
						
					aux2=posx2[k+1]
					posx2[k+1]=posx2[k]
					posx2[k]=aux2
					
					aux3=posy2[k+1]
					posy2[k+1]=posy2[k]
					posy2[k]=aux3
					
					band=0;
		#print flux2,posx2,posy2
		
		### ALGORITMO DE COMPARACION ###
		#
		#BUSCA LAS ESTRELLAS QUE TIENE LA MISMA SEPARACION RELATIVA Y CUYO COCIENTE DE 
		#FLUJO ES PARECEIDO
		
		flux2=array(flux2);posx2=array(posx2);posy2=array(posy2);
		
		aa=0; 
		contar=range(len(flux2))
		flux3=[]
		posx3=[]
		posy3=[]
		for i in contar[1:]:
			flux3=flux2/flux2[i]
			posx3=posx2-posx2[i]
			posy3=posy2-posy2[i]
			
			if aa==10:
				break
			for j in range(len(flux0)):
				flux=flux0/flux0[j]
				posx=posx0-posx0[j]
				posy=posy0-posy0[j]
					
				limpos=6.
				
				if len(posx)==1:
					## OFFSET PARA IMAGEN CON UNA ESTRELLA:
					coo2=iraf.imcntr(input=ima,x_init=posx0[0],y_init = posy0[0],cboxsize = '60',Stdout=1)
					x=float(centro.split(':')[1][:-1])
					y=float(centro.split(':')[2])
					vx=-x+posx0[0]
					vy=-y+posy0[0]

					vv=open(grupo+'shifts2','a')
					vv.write(('%8.5s %8.5s' % (vx,vy))+'\n')
					vv.close()
					aa=10
					break
					
					
				else:
					donde=where(( posx3<posx[1] + limpos) & ( posx3>posx[1] - limpos) & (posy3<posy[1] + limpos) & ( posy3>posy[1] - limpos))
					
					if len(donde[0])!=0:
						limflux=flux[1]/2.
						if abs(flux3[donde[0]][0]-flux[1])<limflux:
							if flux[1] != 1.:
								print posx0[1]-posx2[donde[0]],posy0[1]-posy2[donde[0]],ima,flux3[donde[0]],flux[1]
								x=(posx0[1]-posx2[donde[0]])[0]
								y=(posy0[1]-posy2[donde[0]])[0]
								vv=open(grupo+'shifts2','a')
								vv.write(('%8.5s %8.5s' % (x,y))+'\n')
								vv.close()
								aa=10
								break
		if aa==0:
			#ESTO SIGNIFICA QUE NO HA ENCONTRADO NINGUNA SIMILITUD EN ESTA IMAGEN
			#Y AÑADO LA QUE ESTABA SEGUN LAS COORDENADAS
			vv=open(grupo+'shifts2','a')
			vv.write(line_shift[index])
			vv.close()
		index=index+1
			

	
	os.system('more '+grupo+'shifts2')
			
	
	try:
		iraf.imalign(input=lista1,referenc=image00,coords=image00[:-5]+'.obj.1',output=lista2,shifts=grupo+'shifts2',boxsize='21',bigbox='23',negativ='no',backgro='INDEF',lower='INDEF',upper='INDEF',niterat='11',toleran='0',maxshif= 'INDEF',shiftim='yes',interp_='linear',boundar='constant',constan='0.',trimima='yes',verbose='yes',mode='h')
		iraf.imcombine(input=lista2,output='aFINAL_'+grupo+'.fits',combine="median",masktype="none",outtype="real",scale="none",project="no",reject="none",weight="none",logfile = "")
		print 'aFINAL_'+grupo+'.fits'
	except:
		print 'Grupo'+grupo+'sin combinar #~~~~~~~~~~~~~~~#'
		qr.write(grupo+'\n')
	#break
	
	print '##############################################################################'
print '...'
	
qr.close()	
	
	
	
	
	
	
	
	
	
	
	
	
		

