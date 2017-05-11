/*
 *  Vérifie tous les fichiers *.s du répertoire ForthEx.X pour s'assurer que les noms dans le dictionnaire
 *  ont la bonne valeur pour la longueur.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>

 
static char* path="ForthEx.X/";
static char* ext=".s";
static int count;

int checkNameLen(char* line){
	int state,len,n;
	char *name;
	name=strchr(line,'"');
	if (!name) return 0;
	name++;
	state=0;
	len=0;
	n=0;
	while (*name){
		switch (state){
		case 0:
			if (*name=='\\' )state++; else if (*name=='"') state=2;else len++;
			break;
		case 1:
			len++;
			state=0;
			break;
		case 2:
			if (*name==',') state++;
			break;	
		case 3:
		    if (!isdigit(*name)){ state++;	}
		    else {n = n*10+((*name)-'0');}
			break;
		default:;	
		}
		name++;
	}//while
	return n==len;
}

void checkDEF(char* line){
	
	;
	if (strstr(line,"DEFWORD")||
	    strstr(line,"DEFCODE")||
	    strstr(line,"DEFUSER")||
	    strstr(line,"DEFCONST")||
	    strstr(line,"DEFTABLE"))
	{
		//printf("%s\n",line);
		if (!checkNameLen(line)){
			printf("%s  >> bad length count\n",line);
		}	
		count++;
    };	
}

void parseFile(const char* fname){
	FILE* fh;
	char file_name[256];
	char line[256];
	char *str;
	int len;
	
	line[255]=0;
	strcpy(file_name,path);
	strcat(file_name,fname);
	fh=fopen(file_name,"r");
	while (fgets(line,255,fh)){
		checkDEF(line);
	}
	fclose(fh);
}

void countWords(){
  DIR           *d;
  struct dirent *dir;
  d = opendir(path);
  if (d)
  {
    while ((dir = readdir(d)) != NULL)
    {
	  if (strstr(dir->d_name,ext)){	
        printf("---------------\n-- %s\n---------------\n", dir->d_name);
        parseFile(dir->d_name);
      }
    }
    closedir(d);
  }		
}

int main(int argc, char** argv ){
	countWords();
    printf("count: %d\n",count);
	return 0;
}


