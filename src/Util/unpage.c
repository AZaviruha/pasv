/*
	unpage - converts DEC-10 files with line numbers and form feeds
		 between pages into separate UNIX files, one for each
		 page, without line numbers.

					J. Nagle   February, 1981
					Version 1.7 of 8/27/82

*/
#include <stdio.h>
int optiond = 0;                        /* if -d keyletter */
int optionv = 0;			/* if -v keyletter */
#define NL 	'\n'
#define FF 	'\f'
#define HT 	'\t'
#define CR 	'\r'
/*
	newfile - handle start of a new file
*/
FILE *newfile(namebase,num)
char namebase[];			/* base of name to construct */
int num;				/* number of subfile */
{
    char fname[120];			/* constructed name */
    FILE *fptr;				/* output file file pointer */
    int oid = 0;			/* new file open descriptor */
    sprintf(fname,"%s%d%d",namebase,num/10, num%10); /* construct name */
    if (optionv) printf("%s\n",fname);	/* print if verbose */
    oid = creat(fname,0640);	/* try to create the file */
    if (oid < 0)			/* if not creatable */
    {    fprintf(stderr,"Error: cannot create %s\n",fname);
    }
    else				/* if created */
    {    fptr = fopen(fname,"w");	/* open it */
         close(oid);			/* close duplicate open */
         if (fptr == NULL) 		/* if open failed */
         {  fprintf(stderr,"Error: cannot open %s\n",fname); }
    }					/* done with opening */
    return(fptr);			/* return file pointer or null */
}
/*
	getnonnull  --  get char, ignoring nulls
*/
char getnonnull(f)
FILE *f;				/* file to use */
{   register char ch;			/* working char */
    while ((ch = getc(f)) == '\0') {};	/* get until non-null */
    return(ch);				/* return non-null */
}
/*
	main program
*/
main(argc,argv)
int argc;
char *argv[];
{
FILE *ifile, *ofile;			/* file descriptors */
char ch, lastch;			/* for parsing */
int fnum = 0;				/* sequence number of page file */
int fargn = 0;                          /* number of file args */
char *fargs[2];                         /* address of file args */
int arg;                                /* current arg being processed */

char key;                               /* current keyletter */

    for (arg = 1; arg < argc; arg++)    /* scan arguments */
    {   if (argv[arg][0] == '-')        /* if keyletter */
	{   key = argv[arg][1];         /* get keyletter */
	    switch (key) {              /* fan out on keyletter */
	    case 'd': { optiond++; break;}/* debug */
	    case 'v': { optionv++; break;}/* print file names */
	    default:  {                 /* unknown keyletter */
		fprintf(stderr,"Bad option: -%c\n",key); /* diagnose */
		exit(-1);
		}
	    }                           /* end switch */
	}                               /* end keyletter processing */
	else				/* not keyletter, must be file */
	{
	    if (fargn > 1)                  /* if too many file args */
	    {   fprintf(stderr,"Too many file args\n"); /* so state */
		exit(-1);                   /* error exit */
	    }
	    fargs[fargn++] = argv[arg];     /* remember file arg */
	}				/* end file arg */
    }                                   /* end arg processing */
    if (fargn < 1)                      /* if no file args */
    {   fprintf(stderr,"Usage:  unpage  <file name> [<base for new file names>]\n");
	exit(-1);                       /* error */
    }
    if (fargn == 1)				/* if only one file arg */
    {   fargs[1] = fargs[0];			/* both are same */
    }
    ifile = fopen(fargs[0],"r");            /* open arg 1 for reading */
    if (ifile == NULL)                       /* if open failed */
    {   fprintf(stderr,"Cannot open %s.\n",fargs[0]); /* so state */
	exit(-1);                       /* fails */
    }
    /*
	Main processing loop - processing is char by char 
    */
    ch = NL;				/* set previous state */
    ofile = newfile(fargs[1],fnum);		/* create first file */
    if (ofile == NULL) exit(-1);		/* failure is fatal */
    while (1)					/* do until escaped */
    {   lastch = ch;				/* remember last char */
     	ch = getnonnull(ifile);			/* get next char */
	if (ch == EOF) break;			/* normal exit */
	if (ch == FF)				/* if beginning of new page */
	{   fnum++;				/* start new file */
	    fclose(ofile);			/* close previous file */
	    ofile = newfile(fargs[1],fnum);	/* create new file */  
	    if (ofile == NULL) exit(-1);	/* failure is fatal */
	    lastch = NL;			/* set to beginning of line state */
	    ch = NL;				/* by setting state vars */
	}					/* end new file case */
	else					/* if normal case */
	{   if (ch == CR) {ch = NL;}		/* convert CR to LF */
	    if (lastch == NL)			/* if last was a new line */
	    {   if (ch != NL)			/* if this is not a new line */
		{   while (1)			/* skip over digit string */
		    {   lastch = ch;		/* update last char */
			ch = getnonnull(ifile);	/* get next char */
			if (ch == HT) break;	/* normal exit */
			if (ch == CR) break;	/* less-normal exit */
			if (ch == NL) break;	/* occurs at end of page */
			if (ch != ' ' && (ch < '0' || ch > '9')) /* if not seq number */
			{   fprintf(stderr,"Illegal char %c in line number.\n",
				ch);
			    exit(-1);		/* fails */
			}			/* end bad char handling */
		    }				/* end of line number */
		}				/* end beginning of line */
	    }					/* if last not newline */
	    else { putc(ch,ofile); }		/* normal case */
	}
    }						/* end processing loop */
    close(ofile);				/* close last file */
    exit(0);					/* normal exit */
}
