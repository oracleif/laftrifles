char *malloc();
char *strsort();

main(argc, argv)
int argc;
char **argv;
{
	char *buffer;
	buffer = malloc(strlen(argv[1]));
	buffer[0] = '\0';
	permute (buffer, strsort(argv[1]));
}

permute (prefix, remain)
char *prefix;
char *remain;
{
	char *holdrem;
	char permc;
	int i;
	int remlen;
	int pfx_end;

	remlen = strlen(remain);

	if (remlen == 1)
	{
		printf("%s%s\n", prefix, remain);
		return(0);
	}

	holdrem = malloc(remlen+1);

	pfx_end = strlen(prefix);

	permc=1;
	for (i = 0; i < remlen; i++)
	{
		prefix[pfx_end+1] = '\0';
		if (remain[i] != permc)
		{
			permc = remain[i];
			prefix[pfx_end] = permc;
			strcpy (holdrem, remain);
			strcpy (holdrem+i, remain+i+1);
			permute(prefix, holdrem);
		}
	}
	free(holdrem);
}

char *strsort(in_string)
char in_string[];
{
	int strsize;
	int scramble;
	int i;
	char holder;

	strsize = strlen(in_string);

	do
	{
		scramble = 0;
		for (i = 1; i < strsize; i++)
		{
			if (in_string[i] < in_string[i-1])
			{
				holder = in_string[i-1];
				in_string[i-1] = in_string[i];
				in_string[i] = holder;
				scramble=1;
			}
		}
	} while (scramble);

	return(in_string);
}
