{
	UNIX-only variables

	Required for both verifier and compiler
}
filestack: array [1..filestackmax] of fileitem;	{ stack for include files }
filestackdepth: 0..filestackmax;		{ depth into above }
fileserial: integer;				{ serial number of files }
currentarg: integer;				{ next arg to read on call }
validkeyletters: set of char;			{ allowed option letters }
