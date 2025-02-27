/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/***********************************************************************************************
 **             C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S                  **
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Data file creator.                                           *
 *                                                                                             *
 *                    File Name : MIXFILE.CPP                                                  *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : August 6, 1994                                               *
 *                                                                                             *
 *                  Last Update : 10/27/94 [JLB]                                               *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   Calc_CRC -- Calculate the CRC value of a block of data.                                   *
 *   compfunc -- Comparison function used by qsort().                                          *
 *   DataClass::DataClass -- Constructor for a data file object node.                          *
 *   DataClass::Process_Input -- Process the input file list and builds linked records.        *
 *   DataClass::Process_Output -- Creates the output data file from the component source files.*
 *   DataClass::~DataClass -- Destructor for the data file object.                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#pragma inline

#include	<stdlib.h>
#include	<stdio.h>
#include	<ctype.h>
#include	<dir.h>
#include	<string.h>

#define	FALSE	0
#define	TRUE	1

long Calc_CRC(void const *data, long size);


/********************************************************************
**	This is the data block controlling class.  It is used for every data
**	file as well as processing the entire data file list.
*/
class DataClass {
	public:
		long CRC;
		static short Count;
		static long TotalSize;
		static char *ExtFrom[10];
		static char *ExtTo[10];
		static int ExtCount;
		static char *AltPath[10];
		static int AltPathCount;

		DataClass(char const *filename);
		~DataClass(void);
		static void Process_Input(char const *infile, int quiet, int paths);
		static void Process_Output(char const *outfile);

		char const * Output_Filename(void);
		char const * Input_Filename(void);

	private:
		DataClass	*Next;		// Pointer to next file in chain.
		char			*Filename;	// Raw original filename.
		long			Size;			// Size of data element.
		long			Offset;		// Offset within mixfile for data start.
		int			Index;		// Write order number.

		static DataClass *First;
		static int Quiet;
		static int Paths;
};

char *DataClass::AltPath[10];
char *DataClass::ExtFrom[10];
char *DataClass::ExtTo[10];
int DataClass::ExtCount = 0;
int DataClass::AltPathCount = 0;
short DataClass::Count = 0;
DataClass * DataClass::First = 0;
int DataClass::Quiet = FALSE;
int DataClass::Paths = FALSE;
long DataClass::TotalSize = 0;

int main(int argc, char ** argv)
{
	class UsageError{};		// Parameter error or usage display desired.
	char *infile = 0;
	char *outfile = 0;
	int quiet = FALSE;
	int paths = FALSE;

	/*
	** Banner message.
	*/
	printf("MIXFILE V1.4 (c)\n");

	/*
	**	Process the parameter list and dispatch the packing function.
	*/
	try {

		/*
		**	If not enough parameters were specified, then immediately
		** display the usage instructions.
		*/
		if (argc < 2) throw UsageError();

		try {
			for (int index = 1; index < argc; index++) {
				char *arg = argv[index];

				switch (*arg) {

					/*
					**	Process any command line switches.
					*/
					case '/':
					case '-':
						switch (toupper(arg[1])) {
							case 'Q':
								quiet = TRUE;
								break;

							case 'S':
								paths = TRUE;
								break;

							case 'E':
								if (DataClass::ExtCount >= sizeof(DataClass::ExtFrom)/sizeof(DataClass::ExtFrom[0])) {
									throw "Too many extensions specified";
								} else {
									char * ptr = strupr(strtok(&arg[2], "="));
									if (*ptr == '.') ptr++;
									DataClass::ExtFrom[DataClass::ExtCount] = ptr;

									ptr = strupr(strtok(NULL, "=\r\n"));
									if (*ptr == '.') ptr++;
									DataClass::ExtTo[DataClass::ExtCount] = ptr;

									DataClass::ExtCount++;
								}
								break;

							case 'I':
								if (DataClass::AltPathCount >= sizeof(DataClass::AltPath)/sizeof(DataClass::AltPath[0])) {
									throw "Too many paths specified";
								} else {
									char dir[MAXDIR];

									strcpy(dir, &arg[2]);
									if (dir[strlen(dir)-1] != '\\') {
										strcat(dir, "\\");
									}
									DataClass::AltPath[DataClass::AltPathCount++] = strupr(strdup(dir));
								}
								break;

							default:
								throw "Unrecognized option flag";
						}
						break;

					/*
					**	Process command line filenames for either input or output.
					*/
					default:
						if (outfile) throw "Unrecognized parameter";
						if (!infile) {
							FILE *file = fopen(arg, "r");
							if (!file) throw "Unable to open input file";
							fclose(file);
							infile = arg;
							continue;
						}
						if (!outfile) {
							outfile = arg;
						}
						break;
				}
			}

			/*
			**	Perform a last minute check to make sure both an input and
			**	output filename was specified.  If not, then throw an
			**	error.
			*/
			if (!outfile) throw "No output file specified";
			if (!infile) throw "No input file specified";

			/*
			**	Process the data.
			*/
			try {
				DataClass::Process_Input(infile, quiet, paths);
				DataClass::Process_Output(outfile);
				printf("Created mix file '%s'\nEmbedded objects = %d\nTotal file size = %ld\n", outfile, DataClass::Count, DataClass::TotalSize);
			}
			catch (char *message) {
				printf("\nERROR: %s.\n", message);
				exit(EXIT_FAILURE);
			}
		}

		/*
		**	This exception is called for any of the various fatal errors that
		**	can occur while parsing the parameters.
		*/
		catch(char *message) {
			printf("\nERROR: %s.\n", message);
			throw UsageError();
		}
	}

	/*
	**	This exception is thrown when the utility can't proceed and the
	**	utility usage instructions are desired to be displayed.
	*/
	catch(UsageError) {
		printf("\nUSAGE:  DATFILE <controlfile> <datafile>\n"
		"\n"
		"  <controlfile>        : list of filenames to pack\n"
		"  <datafile>           : output data filename\n"
		"  Options\n"
		"    -q               : quiet operation\n"
		"    -i<path>         : alternate to find files\n"
		"    -e<ext1>=<ext2>  : changes file extensions from <ext1> to <ext2>\n"
		"    -s               : record paths in ID\n");
		exit(EXIT_FAILURE);
	}

	return EXIT_SUCCESS;
}


/***********************************************************************************************
 * DataClass::Process_Input -- Process the input file list and builds linked records.          *
 *                                                                                             *
 *    This routine will process the list of files in the input file.  It builds a linked       *
 *    list of DataClass objects.  This routine is the initial process of creating a packed     *
 *    data file.                                                                               *                                                                                             *
 *                                                                                             *
 * INPUT:   infile   -- Pointer to input filename.                                             *
 *                                                                                             *
 *          quiet    -- Process quietly?                                                       *
 *                                                                                             *
 *          paths    -- Should the path of the filename be considered as part of its signature?*
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void DataClass::Process_Input(char const *infile, int quiet, int paths)
{
	FILE	*file;		//	Input file.
	static char buffer[MAXFILE];

	Quiet = quiet;
	Paths = paths;

	if (!infile) throw "No input file specified";

	file = fopen(infile, "ra");
	if (!file) throw "Could not open input file";

	if (!Quiet) {
		printf("Processing '%s'.\n", infile);
	}

	/*
	**	Process the source file list.
	*/
	try {
		for (;;) {
			int result = fscanf(file, "%s", buffer);
			if (result == EOF) break;

			new DataClass(buffer);
		}
	}

	/*
	**	This error handler is used if there are any errors that occur while
	**	parsing and verifying the data block filenames.  Errors can include
	**	source filename errors as well as missing source files themselves.
	*/
	catch (char *message) {
		fclose(file);
		throw message;
	}

	fclose(file);
}


/***********************************************************************************************
 * DataClass::DataClass -- Constructor for a data file object node.                            *
 *                                                                                             *
 *    This constructs a data file object node and links it into the list of object nodes.      *
 *    It performs a preliminary check on the existance of the the source file.                 *
 *                                                                                             *
 * INPUT:   filename -- The filename of the object to add.                                     *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *   10/27/94   JLB : Handles multiple data paths.                                             * 
 *=============================================================================================*/
DataClass::DataClass(char const *filename)
{
	static char buffer[100];
	
	if (!filename) throw "NULL filename";

	Filename = strdup(filename);
	strupr(Filename);

	/*
	**	Try to find the data file.
	*/
	FILE *datafile = fopen(Filename, "rb");
	if (!datafile) {

		/*
		**	If the file couldn't be found in the current directory, check
		**	the alternate paths.  If the alternate path is successful, then
		**	alter the pathname to match and continue.
		*/
		for (int index = 0; index < AltPathCount; index++) {
			strcpy(buffer, AltPath[index]);
			strcat(buffer, Filename);
			datafile = fopen(buffer, "rb");
			if (datafile) {
				free(Filename);
				Filename = strdup(buffer);
				break;
			}
		}

		if (!datafile) {
			sprintf(buffer, "Could not find source file '%s'", Filename);
			throw buffer;
		}
	}

	/*
	**	Determine the CRC identifier for the filename,  This can be either
	**	the base filename or the complete path (as indicated by the command
	**	line parameter).
	*/
	char const * name = Output_Filename();
	CRC = Calc_CRC(name, strlen(name));

	/*
	**	Find out the size of the source data file.
	*/
	fseek(datafile, 0, SEEK_END);
	long size = ftell(datafile);
	fclose(datafile);

	if (size == -1) throw "Seek failure";
	Size = size;

	Index = Count;
	Count++;
	Next = First;
	First = this;
}


/***********************************************************************************************
 * DataClass::~DataClass -- Destructor for the data file object.                               *
 *                                                                                             *
 *    This is the destructor for the data file object.  It deallocates any memory allocated    *
 *    and de-links it from the list of file objects.                                           *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
DataClass::~DataClass(void)
{
	if (Filename) {
		free(Filename);
		Filename = 0;
	}

	Count--;
	DataClass *ptr = First;
	DataClass *prev = 0;
	while (ptr) {
		if (ptr == this) {
			if (prev) {
				prev->Next = Next;
			}
			return;
		}
		prev = ptr;
		ptr = ptr->Next;
	}
}


/***********************************************************************************************
 * compfunc -- Comparison function used by qsort().                                            *
 *                                                                                             *
 *    This is a support function that compares two file data objects against their CRC         *
 *    values.                                                                                  *
 *                                                                                             *
 * INPUT:   ptr1  -- Pointer to object number 1.                                               *
 *                                                                                             *
 *          ptr2  -- Pointer to object number 2.                                               *
 *                                                                                             *
 * OUTPUT:  Returns with a logical comparison of object 1 to object 2.                         *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
int compfunc(const void *ptr1, const void *ptr2)
{
	DataClass const *obj1 = *(DataClass const **)ptr1;
	DataClass const *obj2 = *(DataClass const **)ptr2;

	if (obj1->CRC < obj2->CRC) {
		return (-1);
	}
	if (obj1->CRC > obj2->CRC) {
		return (1);
	}
	return(0);
}


/***********************************************************************************************
 * DataClass::Process_Output -- Creates the output data file from the component source files.  *
 *                                                                                             *
 *    This is the final step in creation of the data output file.  It writes the header        *
 *    block and then appends the appropriate files to the output file.                         *
 *                                                                                             *
 * INPUT:   outname  -- Pointer to the filename to use for output.                             *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void DataClass::Process_Output(char const *outname)
{
	FILE *outfile;

	if (Count) {
		DataClass **array = new DataClass *[Count];

		/*
		**	Open the output file for creation.
		*/
		if (!outname) throw "Missing output filename";
		outfile = fopen(outname, "wb");
		if (!outfile) {
			throw "Unable to open output file";
		}

		/*
		**	Build a working array to the file objects.
		*/
		DataClass * ptr = First;
		for (int index = 0; index < Count; index++) {
			array[index] = ptr;
			ptr->Index = index;
			ptr = ptr->Next;
		}

		/*
		**	Precalculate the offset value for each data file will be.
		**	This value will be inserted into the header block. This is
		**	performed BEFORE the files are sorted because the data files
		**	are written to disk in the order that they were specified.
		*/
		TotalSize = 0;
		for (index = 0; index < Count; index++) {
			array[index]->Offset = TotalSize;
			TotalSize += array[index]->Size;
		}

		/*
		**	Next, sort the data objects so that a binary search on CRC values
		**	can be used for file retrieval.
		*/
		qsort(array, Count, sizeof(array[0]), compfunc);

		/*
		**	Output the header section of the data file.  This contains
		**	the count of objects contained, the CRC, and offset for each.
		*/
		fwrite(&Count, sizeof(Count), 1, outfile);
		fwrite(&TotalSize, sizeof(TotalSize), 1, outfile);
		for (index = 0; index < Count; index++) {
			fwrite(&array[index]->CRC, sizeof(array[index]->CRC), 1, outfile);
			fwrite(&array[index]->Offset, sizeof(array[index]->Offset), 1, outfile);
			fwrite(&array[index]->Size, sizeof(array[index]->Size), 1, outfile);
		}

		TotalSize += sizeof(Count) + sizeof(TotalSize) + (Count*12);

		if (!Quiet) {
			printf("size      CRC       Filename\n");
			printf("------    --------  -------------------------\n");
		}

		/*
		**	Now write the actual data -- one file at a time in the order that they were
		**	originally specified.
		*/
		for (int order = 0; order < Count; order++) {
			for (index = 0; index < Count; index++) {
				DataClass * entry = array[index];

				if (entry->Index == order) {
					FILE	*infile;
					long	size;
					static char buffer[1024*30];

					if (!Quiet) {
						printf("%-8ld [%08lX] %s\n", entry->Size, entry->CRC, entry->Output_Filename());
					}

					size = entry->Size;
					infile = fopen(entry->Input_Filename(), "rb");
					while (size > 0) {
						int count;

						count = (size < sizeof(buffer)) ? (int)size : sizeof(buffer);
						count = fread(buffer, sizeof(buffer[0]), count, infile);
						fwrite(buffer, sizeof(buffer[0]), count, outfile);
						size -= count;
						if (!count) break;		// Hmm..
					}
					fclose(infile);
					break;
				}
			}
		}

		fclose(outfile);
	}
}


/***********************************************************************************************
 * Calc_CRC -- Calculate the CRC value of a block of data.                                     *
 *                                                                                             *
 *    This routine is used to create a CRC value from a string of data bytes.                  *
 *                                                                                             *
 * INPUT:   data  -- Pointer to the data bytes to calculate the CRC value for.                 *
 *                                                                                             *
 *          size  -- The number of bytes in the data block.                                    *
 *                                                                                             *
 * OUTPUT:  Returns with the CRC value of the buffer specified.                                *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
long Calc_CRC(void const *data, long size)
{
	long	crc = 0;				// Accumulating CRC value.
	long	const *ptr = static_cast<long const *>(data);

	/*
	**	Process the bulk of the data (4 bytes at a time).
	*/
	for (; size > sizeof(long); size -= sizeof(long)) {
		long temp = *ptr++;
		asm {
			mov	eax,crc
			rol	eax,1
			add	eax,temp
			mov	crc,eax
		}
	}

	/*
	**	If there are any remainder bytes, then process them
	**	as a group of four, but the trailing left over bytes
	**	are forced to be NULL.
	*/
	if (size) {
		long temp = 0;

		memcpy(&temp, ptr, (size_t)size);
		asm {
			mov	eax,crc
			rol	eax,1
			add	eax,temp
			mov	crc,eax
		}
	}

	return (crc);
}


char const * DataClass::Output_Filename(void)
{
	char file[MAXFILE];
	char ext[MAXEXT];
	char path[MAXPATH];
	char drive[MAXDRIVE];
	static char filename[255];

	/*
	**	Break the original filename into its component parts.
	*/
	fnsplit(Filename, drive, path, file, ext);

	/*
	**	Substitute the extension if a substitution is called for.
	*/
	for (int index = 0; index < ExtCount; index++) {
		if (stricmp(ExtFrom[index], &ext[1]) == 0) {
			strcpy(&ext[1], ExtTo[index]);
			break;
		}
	}

	/*
	**	Strip the path from the filename if path stripping is enabled.
	*/
	if (!Paths) {
		fnmerge(filename, NULL, NULL, file, ext);
	} else {
		fnmerge(filename, drive, path, file, ext);
	}
	return(&filename[0]);
}	


char const * DataClass::Input_Filename(void)
{
	return(Filename);
}	
