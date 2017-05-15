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
static char html[1024];

int scan(const char *text, char c,int from){
	while (text[from] && text[from]!=c){
		from++;
	}
	return from;
}

int skip(const char *text, char c,int from){
	while (text[from] && text[from]==c){
		from++;
    }
	return from;
}

int word(char *text){
	int i,j;
	i=skip(text,' ',0);
	j=0;
	while (text[i] && text[i]!=' '){
		html[j++]=text[i++];
	}
	html[j]=0;
	return i;
}

void replaceAngleBrackets(char *text){
	int i=0,j=0;;
	while (text[i]){
		switch (text[i]){
			case '<':
			strcpy(&html[j],"&lt;");
			j+=4;
			break;
			case '>':
			strcpy(&html[j],"&gt;");
			j+=4;
			break;
			default:
			html[j++]=text[i];
			break;
		}//switch
		i++;
	}//while
	html[j]=0;
}

void formatNameLine(char *text,FILE *out){
	int i,j;
	char *start;
    
	i=scan(text,':',0);
	i++;
	i=skip(text,' ',i);
	start=&text[i];
	i=scan(text,' ',i+1);
	text[i]=0;
	replaceAngleBrackets(start);
	fprintf(out,"<p id=\"%s\">\n",html);
	fprintf(out,"<b>%s</b> ",html);
	i++;
	replaceAngleBrackets(&text[i]);
	fputs(html,out);
}

void outputArgLine(char *line,FILE *out){
	int i;
	
	line++;
	i=word(line);
	fprintf(out,"<div style=\"margin-left:5%%;\"><i>%s</i>&nbsp;&nbsp;",html);
	replaceAngleBrackets(&line[i]);
    fprintf(out,"%s</div>\n",html);
}

void addEntry(char* line, FILE *in, FILE *out){
	char *ref;
	int i;
	
	// nom:
	formatNameLine(line,out);
	// description
	while ((fgets(line,255,in))&&(*line==';')&&!strstr(line,"arguments:")){
		line++;
		replaceAngleBrackets(line);
		ref=strstr(line,"REF:");
		if (ref){
			ref+=4;
			fprintf(out,"<div style=\"margin-left:5%%;\">REF: <a href=\"%s\">%s</a></div>\n",ref,ref);
		}else{
			fprintf(out,"<div style=\"margin-left:5%%;\">%s</div>\n",html);
		}
	}
	fputs("</p>\n",out);
		if (strstr(line,"arguments:")){
		// arguments:
		line++;
		fprintf(out,"<div style=\"margin-left:5%%;\"><b>%s</b></div>\n",line);
		while ((fgets(line,255,in))&&(*line==';')&&!strstr(line,"retourne:")){
			outputArgLine(line,out);
		}
    }
	if (strstr(line,"retourne:")){ 
		//retourne:
		line++;
		fprintf(out,"<div style=\"margin-left:5%%;\"><b>%s</b></div>\n",line);
		while ((fgets(line,255,in))&&(*line==';')){
			outputArgLine(line,out);
		}
    }
	fputs("<hr>\n",out);
}

void generateDoc(FILE *in, FILE *out){
	char line[256];
	
	while (fgets(line,255,in)){
		if (strstr(line,"; nom:")){
			addEntry(line,in,out);
		}
	}
}//generateDoc()

FILE* createHeader(const char *name,FILE *out){
	static char* html=".html";
	char line[256];
	
	strcpy(line,name);
	strcat(line,html);
	out=fopen(line,"w");
	fputs("<DOCTYPE! html>\n",out);
	fputs("<html lang=\"fr-CA\">\n",out);
	fputs("<head>\n",out);
	fputs("</head>\n<body>\n",out);
	return out;
}

void closeHtml(FILE* out){
	fputs("\n</body>\n</html>\n",out);
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

