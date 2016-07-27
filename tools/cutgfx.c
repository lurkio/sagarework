#include <stdio.h>
#include <stdlib.h>

int main(argc, argv)
int argc;
char **argv;
{
   char filein[256],fileout[256];
   int start;
   int numrooms;
   int gfxoffset[99];
   int gfxlen[99];
   unsigned char gfxdata[99][1024];
   int current;
   int ptr;
   unsigned char byte;
   FILE *infile,*outfile;
   int i,j,k;
   
   for (i=0;i<numrooms;i++)
      gfxoffset[i]=0;
   if (argc!=5)
   {
      printf("Not enough parameters: convertgfx infile outfile start rooms\n");
      exit(1);
   }
   
   strcpy(filein,argv[1]);
   strcpy(fileout,argv[2]);
   
   start=strtol(argv[3],NULL,0);
   numrooms=atoi(argv[4]);
   
   // Find start of data
   infile=fopen(filein,"rb");
   fseek(infile,start,SEEK_SET);
   current=0;
   do
   {
      ptr=0;
      gfxlen[current]=1; // To include the 0xff
      byte=fgetc(infile);
      gfxdata[current][ptr++]=byte;
      do
      {
         byte=fgetc(infile);
         if (byte!=0xff)
         {
            gfxdata[current][ptr++]=byte;
            gfxlen[current]++;
         }
      } while (byte!= 0xff);
      fseek(infile,-1,SEEK_CUR);
      printf("Graphic %d, length %x %x\n", current, gfxlen[current],ftell(infile));
      current++;
   } while (current<numrooms);
   fclose(infile);
   // Now write it
   outfile=fopen(fileout,"wb");
   
   // Leave tables blank for moment
   for (current=0;current<numrooms;current++)
   {
      fputc('\0', outfile);
      fputc('\0', outfile);
      fputc('\0', outfile);
      fputc('\0', outfile);
   }

   // Remove duplicate images
   for (i=0; i<numrooms;i++)
   {
      for (j=i; j<numrooms;j++)
      {
         int match=0;
         if (j!=i)
         {
            if (gfxlen[j] == gfxlen[i] && gfxlen[j] != 0)
            {
               for (k=0; k<gfxlen[j]; k++)
               {
                  if (gfxdata[i][k] != gfxdata[j][k])
                     break;
               }
               if (k == gfxlen[j])
                  match=1;
            }
         }
         if (match)
         {
            printf("Removing duplicate image %d (of %d)\n",j,i);
            gfxoffset[j]=i;
            gfxlen[j]=0;
            break;
         }
      }
   }
   for (current=0;current<numrooms;current++)
   {
      if (gfxoffset[current] > 0)
      {
         i=gfxoffset[current];
         gfxoffset[current]=gfxoffset[i];
         gfxlen[current]=gfxlen[i];
      }
      else
      {      
         gfxoffset[current]=ftell(outfile);
         fwrite(gfxdata[current],gfxlen[current],1,outfile);
      }
   }
   fseek(outfile,0,SEEK_SET);
   for (current=0;current<numrooms;current++)
   {
      fputc(gfxoffset[current] % 256, outfile);
      fputc(gfxoffset[current] / 256, outfile);
      fputc(gfxlen[current] % 256, outfile);
      fputc(gfxlen[current] / 256, outfile);      
   }
   fclose(outfile);
   
   return 0;
}
