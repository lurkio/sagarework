#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct
{
   int magic;
   int objects;
   int actions;
   int words;
   int rooms;
   int maxcarry;
   int start;
   int treasures;
   int wlen;
   int llen;
   int messages;
   int trroom;
   int nverbs;
   int nnouns;
} header_type;

typedef struct
{
   unsigned char condition;
   unsigned char arg;
} condition_type;

typedef struct
{
   unsigned char verb;
   unsigned char noun;
   condition_type conditions[5];
   unsigned char responses[4];
   unsigned char nconditions;
   unsigned char nresponses;
} action_type;

typedef struct
{
   int n;
   int s;
   int e;
   int w;
   int u;
   int d;
   char *description;
} room_type;

typedef struct
{
   char description[255];
   char synonym[10];
   int start;
} object_type;

typedef struct
{
   char word[255];
   int count;
} dictionary_type;

void readconditions(infile,actions,header)
FILE *infile;
action_type *actions[255];
header_type *header;
{
   int i, j, result, word;
   int condition, response, nconditions, nresponses;
   
   for (i=0; i <= header->actions; i++)
   {
      // Reserve memory
      actions[i]=(void *) calloc(1, sizeof(action_type));
      
      result=fscanf(infile,"%d",&word);
      if (result != 1)
      {
         printf("Couldn't read from file properly %d %d\n", result,i);
         exit(1);
      }      
      actions[i]->verb=word / 150;
      actions[i]->noun=word % 150;
      
      // Now conditions
      int lastcond=0;
      for (j=0; j < 5; j++)
      {
         int a;
         result=fscanf(infile,"%d",&condition);
         if (result != 1)
         {
            printf("Couldn't read from file properly %d %d\n", result,i);
            exit(1);
         }      
         actions[i]->conditions[j].condition=condition % 20;
         a=condition/20;
         if (a>255) a=255;
         actions[i]->conditions[j].arg=a;
         if (actions[i]->conditions[j].condition != 0 || actions[i]->conditions[j].arg != 0) lastcond=j+1;
      }      
      actions[i]->nconditions=lastcond;
      
      // Finally responses
      nresponses=0;
      for (j=0; j < 4; j+=2)
      {
         result=fscanf(infile,"%d",&response);
         if (result != 1)
         {
            printf("Couldn't read from file properly %d %d\n", result,i);
            exit(1);
         }      
         actions[i]->responses[j]=response / 150;
         actions[i]->responses[j+1]=response % 150;
         if (actions[i]->responses[j] != 0) nresponses++;
         if (actions[i]->responses[j+1] != 0) nresponses++;
      }
      actions[i]->nresponses=nresponses;
   }
}

// Stolen from ScottFree
char *ReadString(FILE *f)
{
	char tmp[1024];
	char *t;
	int c,nc;
	int ct=0;

   do
	{
		c=fgetc(f);
	}
	while(c!=EOF && isspace(c));
	if(c!='"')
	{
		printf("Initial quote expected");
      exit(1);
	}
	do
	{
		c=fgetc(f);
		if(c==EOF)
      {
			printf("EOF in string");
         exit(1);
      }
		if(c=='"')
		{
			nc=fgetc(f);
			if(nc!='"')
			{
				ungetc(nc,f);
				break;
			}
		}
		if(c==0x60) 
			c='"'; /* pdd */
      tmp[ct++]=c;
	}
	while(1);
	tmp[ct]=0;
	t=malloc(ct+1);
   memset(t,'0',ct+1);
	memcpy(t,tmp,ct+1);
	return(t);
}

int stringblank(word)
char *word;
{
   int i, blank;
   blank=1;
   for (i=0; i<strlen(word); i++)
   {
      if (word[i] != ' ')
      {
         blank=0;
         break;
      }
   }
   return blank;
}

void readwords(infile,verbs,nouns,header)
FILE *infile;
char *verbs[150],*nouns[150];
header_type *header;
{
   int nverbs=0, nnouns=0, i, blank;
   
   for (i=0; i<=header->words; i++)
   {
      verbs[i]=ReadString(infile);
      nouns[i]=ReadString(infile);
      nverbs++;
      nnouns++;
   }
   nverbs--;nnouns--;
 
   // Now we should try and prune excessive verbs and nouns
   i=nverbs;
   do
   {
      blank=stringblank(verbs[i]);
      if (blank)
      {
         nverbs--;
         i--;
      }
   } while (blank==1);

   i=nnouns;
   do
   {
      blank=stringblank(nouns[i]);
      if (blank)
      {
         nnouns--;
         i--;
      }
   } while (blank==1);
   
   // Save numbers in header for later
   header->nverbs=nverbs;
   header->nnouns=nnouns;
}
      
void readheader(infile,header)
FILE *infile;
header_type *header;
{
   int result;

   result=fscanf(infile, "%d %d %d %d %d %d %d %d %d %d %d %d",
                 &header->magic, &header->objects, &header->actions,
                 &header->words, &header->rooms, &header->maxcarry,
                 &header->start, &header->treasures, &header->wlen,
                 &header->llen, &header->messages, &header->trroom
                );
                 
   if (result != 12)
   {
      printf("Couldn't read the header properly\n");
      exit(1);
   }
}

void readrooms(infile,rooms,header)
FILE *infile;
room_type *rooms[128];
header_type *header;
{
   int i, result;
   
   for (i=0; i<=header->rooms; i++)
   {
      rooms[i]=calloc(1, sizeof(room_type));
      result=fscanf(infile, "%d %d %d %d %d %d",
                    &rooms[i]->n, &rooms[i]->s, &rooms[i]->e,
                    &rooms[i]->w, &rooms[i]->u, &rooms[i]->d
                   );
      rooms[i]->description=ReadString(infile);
   }
}

void readmessages(infile,messages,header)
FILE *infile;
char *messages[255];
header_type *header;
{
   int i;
   for (i=0; i<=header->messages;i++)
   {
      messages[i]=ReadString(infile);
   }
}

void readobjects(infile,objects,header)
FILE *infile;
object_type *objects[255];
header_type *header;
{
   int i,j;
   char *working, *pointer;
   
   for (i=0; i<=header->objects;i++)
   {
      objects[i]=calloc(1,sizeof(object_type));
      working=ReadString(infile);
      pointer=strchr(working,'/');
      if (pointer == NULL)
      {
         strcpy(objects[i]->description,working);
         strcpy(objects[i]->synonym,"");
      }
      else
      {
         strncpy(objects[i]->description,working,pointer-working);
         strncpy(objects[i]->synonym,pointer+1,header->wlen);
         for (j=0;j<strlen(objects[i]->synonym);j++)
         {
            if (objects[i]->synonym[j] == '/')
            {
               objects[i]->synonym[j] = '\0';
            }
         }
      }
      fscanf(infile,"%d",&objects[i]->start);
   }
}

char *tokenise(dictionary, dictsize, message)
dictionary_type *dictionary[];
int dictsize;
char *message;
{
   int i;
   char working[255],*response, *pointer;

   response=malloc(255);
   strcpy(response,message);

   for (i=0; i<dictsize; i++)
   {
      memset(working,'\0',255);
      pointer=strstr(response,dictionary[i]->word);
      if (pointer != NULL)
      {
         // left of token
         strncpy(working,response,pointer-response);
         working[pointer-response]=i+128;
         strcat(working,pointer+strlen(dictionary[i]->word));
         strcpy(response,working);
      }
   }
   
   return response;
}

int updatedictionary(dictionary, dictsize, word)
dictionary_type *dictionary[];
int dictsize;
char word[255];
{
   int i,found=0;
   // Add to dictionary
   for (i=0;i<dictsize;i++)
   {
      if (strcmp(dictionary[i]->word,word)==0)
      {
         found=1;
         dictionary[i]->count++;

         break;
      }
   }
   if (!found)
   {
      dictionary[dictsize]=calloc(1, sizeof(dictionary_type));
      strcpy(dictionary[dictsize]->word,word);
      dictionary[dictsize]->count=1;
      dictsize++;
   }
   return dictsize;
}

int splitsentence(dictionary, dictsize, sentence)
dictionary_type *dictionary[];
int dictsize;
char sentence[255];
{
   char working[255],substr[255],*pointer,*pointer2;
   int i,j;
   
   strcpy(working, sentence);
   j=0;
   for (i=0; i<strlen(working); i++)
   {
      if ((tolower(working[i]) > 96 &&
          tolower(working[i]) < 123) ||
          working[i]==' ' || working[i] == '\'')
      {
         working[j]=tolower(working[i]);
         j++;
      }
   }
   working[j]='\0';
   pointer=working;
   do
   {
      while (*pointer == ' ') pointer++;
      pointer2=strchr(pointer,' ');
      
      if (pointer2 != NULL || strlen(pointer)>0)
      {
         memset(substr,'\0',255);
         if (pointer2 == NULL)
         {
            strcpy(substr,pointer);
         }
         else
         {                 
            strncpy(substr,pointer,pointer2-pointer);
         }
         // We don't care if the word's only 1 letter
         if (strlen(substr)>1)
         {
            dictsize=updatedictionary(dictionary,dictsize,substr);
         }
         pointer=pointer2;
      }
   } while (pointer2 != NULL);
   
   return dictsize;
}

int splitletters(dictionary, dictsize, sentence)
dictionary_type *dictionary[];
int dictsize;
char sentence[255];
{
   char working[255],substr[255],*pointer;
   int i,j;

   strcpy(working, sentence);

   //j=0;
   //for (i=0; i<strlen(working); i++)
   //{
   //  if ((tolower(working[i]) > 96 &&
   //       tolower(working[i]) < 123) ||
   //       working[i]==' ' || working[i] == '\'')
   //   {
   //      working[j]=tolower(working[i]);
   //      j++;
   //   }
   //}
   //working[j]='\0';
   pointer=working;
   do
   {
      while (*pointer == ' ') pointer++;
      if (strlen(pointer)>1)
      {
         memset(substr,'\0',255);
         strncpy(substr,pointer,2);
         dictsize=updatedictionary(dictionary,dictsize,substr);
         pointer+=2;
      }
   } while (strlen(pointer)>1);
   
   return dictsize;
}

int cmpdictionary(const void *a, const void *b)
{
   dictionary_type *const *one=a;
   dictionary_type *const *two=b;
   return ((*two)->count - (*one)->count);
}

int makeworddictionary(dictionary, messages, objects, rooms, header)
dictionary_type *dictionary[];
char *messages[];
object_type *objects[];
room_type *rooms[];
header_type *header;
{
   // Go through each lump of text and make up the "words"
   int i,dictsize=0;

   for (i=0; i<=header->messages; i++)
   {
      dictsize=splitsentence(dictionary, dictsize, messages[i]);
   }
   for (i=0; i<=header->rooms; i++)
   {
      dictsize=splitsentence(dictionary, dictsize, rooms[i]->description);
   }  
   for (i=0; i<=header->objects; i++)
   {
      dictsize=splitsentence(dictionary, dictsize, objects[i]->description);
   } 
   
   // qsort to get the biggest
   qsort(dictionary, dictsize, sizeof(*dictionary), cmpdictionary);
   
   return dictsize;
}

int makeletterdictionary(dictionary, messages, objects, rooms, header, dictionary2, dictsize2)
dictionary_type *dictionary[], *dictionary2[];
char *messages[];
object_type *objects[];
room_type *rooms[];
header_type *header;
int dictsize2;
{
   // Go through each lump of text and make up the "words"
   int i,dictsize=0;

   for (i=0; i<=header->messages; i++)
   {
      dictsize=splitletters(dictionary, dictsize, tokenise(dictionary2, dictsize2, messages[i]));
   }
   for (i=0; i<=header->rooms; i++)
   {
      dictsize=splitletters(dictionary, dictsize, tokenise(dictionary2, dictsize2, rooms[i]->description));
   }  
   for (i=0; i<=header->objects; i++)
   {
      dictsize=splitletters(dictionary, dictsize, tokenise(dictionary2, dictsize2, objects[i]->description));
   } 
   
   // qsort to get the biggest
   qsort(dictionary, dictsize, sizeof(*dictionary), cmpdictionary);
   
   return dictsize;
}

int main(argc, argv)
int argc;
char **argv;
{
   FILE *infile, *outfile;
   int i, j, temp, bytes;
   header_type *header;
   action_type *actions[512];
   char *verbs[150];
   char *nouns[150];
   room_type *rooms[128];
   char *messages[255];
   object_type *objects[255];
   dictionary_type **dictionary1,**dictionary2,**finaldictionary;
   int dictsize1, dictsize2, finaldictsize=0;
   int pointers[10];
   
   header=calloc(1, sizeof(header_type));
   dictionary1=calloc(1024, sizeof(dictionary_type *));
   dictionary2=calloc(1024, sizeof(dictionary_type *));      
   finaldictionary=calloc(128, sizeof(dictionary_type *)); 
   
   if (argc != 3)
   {
      printf("No filename passed: in out\n");
      exit(1);
   }
   
   if ((infile=fopen(argv[1],"r"))==NULL || (outfile=fopen(argv[2],"wb"))==NULL)
   {
      printf("Couldn't open files %s %s\n",argv[1], argv[2]);
      exit(1);
   }
   
   // First read the header
   readheader(infile,header);
   // Actions
   readconditions(infile,actions,header);
   // Words
   readwords(infile,verbs,nouns,header);
   // Rooms
   readrooms(infile,rooms,header);
   // Messages
   readmessages(infile,messages,header);
   // Objects
   readobjects(infile,objects,header);
   // Make dictionary
   dictsize1=makeworddictionary(dictionary1, messages, objects, rooms, header);
   // Replace the top 64 words in the dictionary
   //for (i=0; i<63; i++)
   //{
   //   finaldictsize=updatedictionary(finaldictionary,finaldictsize,dictionary1[i]->word);
   //}
   dictsize2=makeletterdictionary(dictionary2, messages, objects, rooms, header, finaldictionary, finaldictsize);
   for (i=0; i<127; i++)
   {
      finaldictsize=updatedictionary(finaldictionary,finaldictsize,dictionary2[i]->word);
   }

   
   /*int before=0, after=0;
   for (i=0; i<header->messages;i++)
   {
      before+=strlen(messages[i]);
      after+=strlen(tokenise(finaldictionary,finaldictsize,messages[i]));
   }  
   printf("Messages: %d -> %d\n",before,after);
   
   before=0, after=0;
   for (i=0; i<header->rooms;i++)
   {
      before+=strlen(rooms[i]->description);
      after+=strlen(tokenise(finaldictionary,finaldictsize,rooms[i]->description));
   }  
   printf("Room Descs: %d -> %d\n",before,after);   
   for (i=0; i<header->objects;i++)
   {
      before+=strlen(objects[i]->description);
      after+=strlen(tokenise(finaldictionary,finaldictsize,objects[i]->description));
   }  
   printf("Object Descs: %d -> %d\n",before,after);  
   bytes=0;
   for (i=0; i<finaldictsize;i++)
   {
      bytes+=strlen(finaldictionary[i]->word);
   }
   printf("dictionary: %d\n",bytes);*/
   
   // Set up blank pointers
   for (i=0; i<7;i++)
   {
      fputc(0, outfile);
      fputc(0, outfile);
   }
   
   // Munge into outheader
   bytes=0;
   fputc(header->objects, outfile);
   fputc(header->actions & 0xff, outfile);
   fputc(header->nverbs, outfile);
   fputc(header->nnouns, outfile);
   fputc(header->rooms, outfile);
   fputc(header->maxcarry, outfile);
   fputc(header->start, outfile);
   fputc(header->wlen+((header->actions & 0xf00)>>4), outfile);
   fputc(header->llen, outfile);
   fputc(header->messages, outfile);
   fputc(header->trroom, outfile);
   
   printf("Header: %d -> %d\n", sizeof(header_type), 11);
   
   pointers[0]=ftell(outfile);
   // Write compressed actions
   bytes=0;
   for (i=0; i <= header->actions; i++)
   {
      fputc(actions[i]->verb,outfile);
      fputc(actions[i]->noun,outfile);
      bytes+=2;
      // Mangle number of conditions and responses into one byte
      int tempptr=ftell(outfile);
      temp=(actions[i]->nconditions<<4) + actions[i]->nresponses;
      fputc(temp,outfile);
      bytes++;
      int nbytes=0;
      for (j=0; j<actions[i]->nconditions; j++)
      {
         // Special action to save some memory - if condition == 0 && arg < 128
         // we set bit 8 and munge it with the arg
         if (actions[i]->conditions[j].condition==0 && actions[i]->conditions[j].arg < 128)
         {
            fputc(actions[i]->conditions[j].arg|0x80, outfile);
            bytes++;
            nbytes++;
         }
         else
         {
            fputc(actions[i]->conditions[j].condition, outfile);
            fputc(actions[i]->conditions[j].arg, outfile);
            bytes+=2;
            nbytes+=2;
         }
      }
      for (j=0; j<actions[i]->nresponses; j++)
      {
         fputc(actions[i]->responses[j], outfile);
         bytes++;
      }
      
      int endptr=ftell(outfile);
      fseek(outfile, tempptr, SEEK_SET);
      temp=(nbytes<<4) + actions[i]->nresponses;
      fputc(temp,outfile);
      fseek(outfile, endptr, SEEK_SET);
   }
   
   printf("Actions: %d -> %d\n", 16*header->actions, bytes);
   pointers[1]=ftell(outfile);   
   // Another saving - we can use bit 7 set to mark the end
   // Finally, SACA uses a * to mark a synonym, so we can abuse that
   // by setting bit 7 at the start
   
   bytes=0;
   // Write compressed words
   for (i=0; i<= header->nverbs; i++)
   {
      int synonym=0;
      int end=0;
      if(verbs[i][0] == '*') synonym=1;
      end=header->wlen+synonym;
      for (j=synonym; j<end; j++)
      {
         int out=verbs[i][j];
         if (out == 0) out=' ';
         if (synonym)
         {
            out |= 0x80;
            synonym=0;
         }
         fputc(out, outfile);
         bytes++;
      }
   }
   pointers[2]=ftell(outfile);   
   for (i=0; i<= header->nnouns; i++)
   {
      int synonym=0;
      int end=0;
      if(nouns[i][0] == '*') synonym=1;
      end=header->wlen+synonym;
      for (j=synonym; j<end; j++)
      {
         unsigned char out=nouns[i][j];
         if (out == 0) out=' ';
         if (synonym)
         {
            out |= 0x80;
            synonym=0;
         }
         fputc(out, outfile);
         bytes++;
      }
   }
   printf("Words: %d -> %d\n", (header->words*2)*(header->wlen+1), bytes);
   pointers[3]=ftell(outfile);   
   // Write exits - we're going to mangle exits into 3 bytes, 1 nibble each
   int obytes=0;
   bytes=0;
   for (i=0; i <= header->rooms; i++)
   {
      int nexits=0;
      fputc(strlen(tokenise(finaldictionary,finaldictsize,rooms[i]->description))+1,outfile);
      fputs(tokenise(finaldictionary,finaldictsize,rooms[i]->description),outfile);
      obytes+=strlen(rooms[i]->description);
      bytes+=strlen(tokenise(finaldictionary,finaldictsize,rooms[i]->description));
      bytes++; obytes++;
      nexits=((rooms[i]->n!=0)?1:0);
      nexits+=((rooms[i]->s!=0)?1:0)<<1;
      nexits+=((rooms[i]->e!=0)?1:0)<<2;
      nexits+=((rooms[i]->w!=0)?1:0)<<3;
      nexits+=((rooms[i]->u!=0)?1:0)<<4;
      nexits+=((rooms[i]->d!=0)?1:0)<<5;
      fputc(nexits,outfile);
      bytes++;
            
      if (rooms[i]->n>0) { fputc(rooms[i]->n,outfile); bytes++; }
      if (rooms[i]->s>0) { fputc(rooms[i]->s,outfile); bytes++; }
      if (rooms[i]->e>0) { fputc(rooms[i]->e,outfile); bytes++; }
      if (rooms[i]->w>0) { fputc(rooms[i]->w,outfile); bytes++; }
      if (rooms[i]->u>0) { fputc(rooms[i]->u,outfile); bytes++; }
      if (rooms[i]->d>0) { fputc(rooms[i]->d,outfile); bytes++; }
      obytes+=6;
   }
   printf("Rooms: %d -> %d\n", obytes, bytes);
   pointers[4]=ftell(outfile);   
   // Write messages
   obytes=0;
   bytes=0;
   for (i=0; i<= header->messages; i++)
   {
      fputc(strlen(tokenise(finaldictionary,finaldictsize,messages[i]))+1,outfile);
      fputs(tokenise(finaldictionary,finaldictsize,messages[i]),outfile);
      obytes+=strlen(messages[i]);
      bytes+=strlen(tokenise(finaldictionary,finaldictsize,messages[i]));
      bytes++; obytes++;
   }
   printf("Messages: %d -> %d\n", obytes, bytes); 
   pointers[5]=ftell(outfile);   
   // Write objects
   obytes=0;
   bytes=0;
   for (i=0; i<= header->objects; i++)
   {
      fputc(strlen(tokenise(finaldictionary,finaldictsize,objects[i]->description))+1,outfile);
      fputs(tokenise(finaldictionary,finaldictsize,objects[i]->description),outfile);
      obytes+=strlen(objects[i]->description);
      bytes+=strlen(tokenise(finaldictionary,finaldictsize,objects[i]->description));       

      // to save even more space, we're going to use the string term to store whether
      // the object is not in room 0 (bit 1) and whether the object has a synonym (bit 2)
      int temp=0;
      if (objects[i]->start > 0) temp|=1;
      int objsyn=0;
      if (objects[i]->synonym!=NULL)
      {
         for (j=0; j <= header->nnouns; j++)
         {
            if (strncmp(nouns[j],objects[i]->synonym,strlen(objects[i]->synonym))==0)
            {
               objsyn=j;
               break;
            }
         }
         if (j == header->nnouns)
         {
            printf("Couldn't find noun for synonym: %s\n",objects[i]->synonym);
         }       
      }
         fputc(objects[i]->start,outfile);
         bytes++;
      obytes++;

         fputc(objsyn,outfile);
         bytes++;
      obytes++;

   }
   printf("Objects: %d -> %d\n", obytes, bytes);
   pointers[6]=ftell(outfile);   
   // Finally the dictionary
   for (i=0; i<finaldictsize; i++)
   {
      fputs(finaldictionary[i]->word,outfile);
   }
   fclose(infile);
   
   // Finally write the pointers
   fseek(outfile,0,SEEK_SET);
   for (i=0; i<7; i++)
   {
      printf("%x\n",pointers[i]);
      fputc(pointers[i] & 0xff,outfile);
      fputc((pointers[i] & 0xff00) >> 8, outfile);
   }
   fclose(outfile);
   return 0;
}
