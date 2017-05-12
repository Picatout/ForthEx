/*
 *  Extraction des commentaires génération de fichiers documentant les mots du dictionnaire forth.
 *  les commentaire doivent avoir la forme suivante:
 *   ; nom:  MOT_FORTH   ( i*x -- j*x )
 *   ;    description du mot
 *   ; arguments:
 *   ;   description de chaque arguments
 *   ; retourne:
 *   ;   description de chaque valeur laissé sur la pile par l'exécution du mot.
 * 
 *   
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>

static char* path="ForthEx.X/";
static char* ext=".s";


void generateDoc(FILE *in, FILE *out){
}//generateDoc()

FILE* createHeader(const char *name,FILE *out){
	static char* html=".html";
	char line[256];
	
	strcpy(line,name);
	strcat(line,html);
	out=fopen(line,"w");
	fputs("<DOCTYPE! HTML>\n",out);
	fputs("<HEAD>\n",out);
	fprintf(out,"<META NAME=\"ForthExDoc\" VALUE=\"%s\">\n",name);
	fputs("</HEAD>\n<BODY>",out);
	return out;
}

void closeHtml(FILE* out){
	fputs("\n</BODY>\n</HTML>\n",out);
	fclose(out);
}
	
void parseFiles(){
  char fileName[256],*dot;	
  FILE *fi,*fo;	
  DIR           *d;
  struct dirent *dir;
  d = opendir(path);
  if (d)
  {
    while ((dir = readdir(d)) != NULL)
    {
	  if (strstr(dir->d_name,ext)){
		strcpy(fileName,path);
		strcat(fileName,dir->d_name);
		fi=fopen(fileName,"r");
		strcpy(fileName,dir->d_name);
		dot=strstr(fileName,ext);
		*dot=0;  
		fo=createHeader(fileName,fo);  	
        generateDoc(fi,fo);
        closeHtml(fo);
        fclose(fi);
      }//if...
    }//while...
    closedir(d);
  }//if...		

}//parseFiles()

int main(int argc, char** argv){
	parseFiles();
	return 0;
}//main()

