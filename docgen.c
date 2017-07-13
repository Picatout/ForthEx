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

#define LINE_MAX 512

#define INDEX_SIZE 1024
static char *words[INDEX_SIZE];
int idx=0;

static char* path="ForthEx.X/";
static char* docPath="docs/html/";
static char* htmlExt=".html";

static char* ext=".s";
static char html[LINE_MAX];

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

char *asciiToUtf8(char *ascii,char *utf8){
	int i=0,j=0;
	unsigned char c;
	while (ascii[i]){
		c=ascii[i++];
		if ( c<128) {
			utf8[j++]=c;
		}else{
			utf8[j++]=0xC0|(c>>6);
			utf8[j++]=0x80|(c&0x3f);
		}
	}
	utf8[j]=0;
	return utf8;
}

char *readLine(char *utf8,int size,FILE *in){
	char line[LINE_MAX];
	if (fgets(line,LINE_MAX,in)){
		return asciiToUtf8(line,utf8);
	}else{
		return NULL;
	}
}

void replaceAngleBrackets(char *text){
	int i=0,j=0;
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
		}//switch
		i++;
	}//while
	html[j]=0;
}


void addHorzLine(FILE *fo,int tickness){
	fprintf(fo,"<hr style=\"border-width:%dpx;\">",tickness);
}

void addMasterRef(FILE* fo){
	fprintf(fo,"<div><a href=\"index.html#MasterIndex\">index principal</a></div>\n");	
}

void addIndexRef(FILE* fo){
	fprintf(fo,"<div><a href=\"#index\">index</a></div>\n");
}

void addTopRef(FILE* fo){
	fprintf(fo,"<div><a href=\"#top\">haut</a></div>\n");	
}

void formatNameLine(char *text,FILE *out){
	int i,j;
	char *start;
	char *toIndex;
    
	i=scan(text,':',0);
	i++;
	i=skip(text,' ',i);
	start=&text[i];
	i=scan(text,' ',i);
	text[i]=0;
	replaceAngleBrackets(start);
	if (idx<INDEX_SIZE){
		toIndex=malloc(strlen(html)+1);
		strcpy((char*)toIndex,html);
		words[idx++]=toIndex;
	}
	fprintf(out,"<p id=\"%s\">\n",html);
	fprintf(out,"<b>%s</b> ",html);
	i++;
	replaceAngleBrackets(&text[i]);
	fprintf(out,"%s<br>",html);
}

void outputArgLine(char *line,FILE *out){
	int i;
	
	line++;
	i=word(line);
	fprintf(out,"<div><i>%s</i>&nbsp;&nbsp;",html);
	replaceAngleBrackets(&line[i]);
    fprintf(out,"%s</div>\n",html);
}

// if line containt "REF:" output an hyperlink.
int refLine(char *line,FILE *out){
	char *ref;
	ref=strstr(line,"REF:");
	if (ref){
		ref+=4;
		fprintf(out,"<div>REF: <a href=\"%s\">%s</a></div>\n",ref,ref);
		return 1;
	}else{
		return 0;
	}
}

void addEmbeddedHtml(FILE *in, FILE *out){
	char line[LINE_MAX];
	fputs("<div>",out);
	while (readLine(line,LINE_MAX,in) && (*line==';') && !strstr(line,":HTML")){
		line[0]=' ';
        fprintf(out,"%s\n",line);
	}
	fputs("</div>",out);
}


void addEntry(char* line, FILE *in, FILE *out){
	char *ref;
	int i;
	
	// nom:
	formatNameLine(line,out);
	// description
	while ((readLine(line,LINE_MAX,in))&&(*line==';') && !strstr(line,"arguments:")){
		line++;
		if (strstr(line,"HTML:")) {
			addEmbeddedHtml(in,out);
		}else{
			replaceAngleBrackets(line);
			if (!refLine(html,out)){
				fprintf(out,"<div>%s</div>\n",html);
			}
		}
	}
	fputs("</p>\n",out);
		if (strstr(line,"arguments:")){
		// arguments:
		line++;
		fprintf(out,"<div><b>%s</b></div>\n",line);
		while ((readLine(line,255,in))&&(*line==';')&&!strstr(line,"retourne:")){
			outputArgLine(line,out);
		}
    }
	if (strstr(line,"retourne:")){ 
		//retourne:
		line++;
		fprintf(out,"<div><b>%s</b></div>\n",line);
		while ((readLine(line,255,in))&&(*line==';')){
			outputArgLine(line,out);
		}
    }
    addIndexRef(out);
    addTopRef(out);
    addMasterRef(out);
    addHorzLine(out,1);
}


void addDescription(char *line,FILE* in, FILE* out){
	char *colon;
	fputs("<h2 id=\"description\">Description</h2>",out);
	colon=strchr(line,':');
	colon++;
	replaceAngleBrackets(colon);
	if (strlen(html)){
	   fprintf(out,"<div>%s</div>\n",html);
    }
	while (readLine(line,LINE_MAX,in) && (*line==';')) {
		line++;
		if (strstr(line,"HTML:")){
			addEmbeddedHtml(in,out);
		}else{
			replaceAngleBrackets(line);
			if (!refLine(html,out)){
				fprintf(out,"<div>%s</div>\n",html);
			}
		}
	}
	addMasterRef(out);
	addHorzLine(out,4);
}

static int wc,fc;

void generateDoc(FILE *in, FILE *out){
	char line[LINE_MAX];
    
    fc++;	
	while (readLine(line,LINE_MAX,in)){
		if (strstr(line,"; DESCRIPTION:")){
			addDescription(line,in,out);
		}else
		if (strstr(line,"; nom:")){
			addEntry(line,in,out);
			wc++;
		}
	}
}//generateDoc()


FILE* createHeader(const char *name,FILE *out){
	char htmlName[LINE_MAX];

	out=fopen(name,"w");
	fputs("<DOCTYPE! html>\n",out);
	fputs("<html lang=\"fr-CA\">\n",out);
	fputs("<head>\n <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n",out);
	fputs(" <link rel=\"stylesheet\" type=\"text/css\" href=\"css/forthex.css\">",out);
	fputs("</head>\n<body id=\"#top\">\n",out);
	return out;
}

// combsort words[] array.
// REF: https://fr.wikipedia.org/wiki/Tri_%C3%A0_peigne 
void sortWords(){
	int skip=idx;
	int xchg;
	int i;
	char *temp;
	
	while ((skip>1) || xchg ){
		skip=skip/1.3;
		if (skip<1) skip=1;
		i=0;
		xchg=0;
		while (i<(idx-skip)){
			if (strcmp(words[i],words[i+skip])>0){
				temp=words[i];
				words[i]=words[i+skip];
				words[i+skip]=temp;
				xchg=-1;
			}
			i++;
		}//while
	}//while
}

void createIndex(FILE* out){
	int i;
	fputs("<h4 id=\"index\">Index</h4>\n<p>\n<ul>\n",out);
	sortWords();
	for (i=0;i<idx;i++){
		fprintf(out,"<li><a href=\"#%s\">%s</a></li>\n",words[i],words[i]);
		free(words[i]);
	}
	fputs("</ul>\n</p>\n",out);
	addHorzLine(out,1);
	addTopRef(out);
	addMasterRef(out);
	idx=0;
}

void closeHtml(FILE* out){
	createIndex(out);
	fputs("\n</body>\n</html>\n",out);
	fclose(out);
}
	
void parseFiles(){
  char fileName[256],*dot;
  char htmlName[256];
  
  FILE *fi,*fo;	
  DIR           *d;
  struct dirent *dir;
  d = opendir(path);
  if (d)
  {
	fc=0;
    while ((dir = readdir(d)) != NULL)
    {
	  if (strstr(dir->d_name,ext)){
		wc=0;
		strcpy(fileName,path);
		strcat(fileName,dir->d_name);
		printf("Analysing %s, ",fileName);
		fi=fopen(fileName,"r");
		strcpy(fileName,dir->d_name);
		dot=strstr(fileName,ext);
		*dot=0;
		strcpy(htmlName,docPath);
		strcat(htmlName,fileName);
		strcat(htmlName,htmlExt);
		fo=createHeader(htmlName,fo);
		fprintf(fo,"<h1>%s</h1>",fileName); 
		addIndexRef(fo);
		addMasterRef(fo);
        generateDoc(fi,fo);
        closeHtml(fo);
        fclose(fi);
        printf(" found %d definitions\n",wc);
        if (!wc) remove(htmlName);
      }//if...
    }//while...
    closedir(d);
    printf("%d files analysed\n",fc);
  }//if...		

}//parseFiles()

int main(int argc, char** argv){
	parseFiles();
	return 0;
}//main()

