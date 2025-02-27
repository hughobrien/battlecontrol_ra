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
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : AUDIOMAK.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : August 8, 1994                                               *
 *                                                                                             *
 *                  Last Update : August 8, 1994   [JLB]                                       *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	<stdio.h>
#include	<stdlib.h>
#include	<dir.h>
#include	<dos.h>
#include	<string.h>
#include	<ctype.h>
#include	<conio.h>

#define	FALSE	0
#define	TRUE	1

#define	MIN(a,b)		(((a)<(b)) ? (a) : (b))
#define	MAX(a,b)		(((a)>(b)) ? (a) : (b))

char * SourceFile = 0;
int SourceWild = FALSE;
char * DestFile = 0;
int DestDir = FALSE;
int DoSpecial = TRUE;				// Compression starts "on".
long MagicNumber = 0xDEAF;
int DoVerbose = FALSE;				// Verbose report starts "off".

char Path[MAXPATH];
char Drive[MAXDRIVE];
char Dir[MAXDIR];
char File[MAXFILE];
char Ext[MAXEXT];

// The size of these buffers must be evenly divisble by 2048.
char far StageBuffer[1024*16];
char far padding[1024];
char far AltBuffer[1024*16];
char far padding2[1024];

// General header to the RIFF file itself.
typedef struct {
	char szRIFF[4];				// "RIFF"
	long dwFormatLength;
	char szWAVE[4];				// "WAVE"
} RIFFHeaderType;

// Header to each sub-block of a RIFF file.
typedef struct {
	char szDATA[4];				// ASCII identifier for block.
	long dwDataLength;			// Size of block (not counting this header).
} RIFFBlockType;

// First part of the "fmt" data block.
typedef struct {
	short wFormatTag;				// 1=raw, 33=sonarc
	short wChannels;				// 1=mono, 2=stereo
	long dwSamplesPerSec;		// Playback "rate".
	long dwAvgBytesPerSec;		// =(samples/sec)*(bytes/sample)*wChannels
	short wBlockAlign;
	short wBitsPerSample;			// 8 or 16

	// Even more bytes can go here... examine dwDataLength to verify.
	// Optional for Sonarc
//		LONG cbSize;					// Size of the extra portion of fmt (always 2)
//		WORD wCompType;				// Compression algorithm index
} RIFFfmtType;

typedef struct {
	char	Description[0x14];
	short	Offset;
	short	Version;
	short	IDCode;
} VocHeaderType;

// Compression types.
typedef enum {
	SCOMP_NONE=0,			// No compression -- raw data.
	SCOMP_WESTWOOD,		// Special sliding window delta compression.
	SCOMP_SONARC=33		// Sonarc frame compression.
} SCompressType;

// Header to output file.
typedef struct {
	unsigned short	Rate;				// Playback rate (hertz).
	long				Size;				// Size of data (bytes).
	unsigned			Stereo:1;		// Is the sample stereo?
	unsigned			Bits:1;			// Is the sample 16 bits?
	unsigned			pad:6;			// Padding bits.
	unsigned char	Compression;	// What kind of compression for this sample?
} RawHeaderType;

typedef struct {
	short	frameSize;				// Size of the frame in bytes (including header).
	short	nSamples;					// # of samples in the frame.
	short	chkSum;					// A checksum -- Words XORed with 0xACED.
	char	tableIndex;				// Bit 7 set if frame was RLE'd
	char	order;						// The order of the predictor.
} SonarcFrameType;


int main(int argc, char **argv);
void Process(char const *src, char const *name, char const *dest);
void Convert(char const *src, char const *dst);
int Is_WAV(FILE *src);
void Convert_WAV(FILE * src, FILE * dst);
int Is_VOC(FILE *src);
void Convert_VOC(FILE *src, FILE *dst);
long Compress_Frame(void * source, void * dest, long size);

extern "C" {
short Decompress_Frame(void * source, void * dest, short size);
}


int main(int argc, char **argv)
{

	/*
	**	Process the command line parameters.
	*/
	try {
		if (argc < 2) throw 1;

		for (int index = 1; index < argc; index++) {
			char *string = argv[index];

			switch (string[0]) {
				case '-':
				case '/':
					switch (toupper(string[1])) {
						case 'X':
							if (string[2] == '-') {
								DoSpecial = FALSE;
							}
							break;

						case 'V':
							DoVerbose = TRUE;
							break;

						default:
							printf("\nERROR: Invalid command line argument.\n");
							return (EXIT_FAILURE);
					}
					break;

				default:
					if (!SourceFile) {
						SourceFile = string;
					} else {
						if (!DestFile) {
							DestFile = string;
						} else {
							printf("\nERROR: Invalid command line argument.\n");
							return (EXIT_FAILURE);
						}
					}
			}
		}

		/*
		**	Verify that the source filespec can locate at least one file.
		*/
		{
			struct ffblk block;

			int result = fnsplit(SourceFile, Drive, Dir, File, Ext);
			if (result & WILDCARDS) SourceWild = TRUE;
			result = findfirst(SourceFile, &block, FA_ARCH|FA_RDONLY);
			if (result) {
				printf("\nERROR: Cannot find source file '%s'.\n", SourceFile);
				exit(EXIT_FAILURE);
			}
		}

		/*
		**	No output file is necessary if only a single file is specified for
		**	the source.  In such a case, use the source file as the output file
		**	name but change the extension to .AUD.
		*/
		if (!DestFile) {
			if (!SourceWild) {
				fnsplit(SourceFile, Drive, Dir, File, Ext);
				fnmerge(Path, Drive, Dir, File, ".AUD");
				DestFile = strdup(Path);
			} else {
				DestFile = strdup(".");
				//printf("\nERROR: No destination directory specified.\n");
				//exit(EXIT_FAILURE);
			}
		}

		/*
		**	The source and destination files cannot be the same.
		*/
		if (stricmp(SourceFile, DestFile) == 0) {
			printf("\nERROR: Source and destination files must not be the same.\n");
			exit(EXIT_FAILURE);
		}

		/*
		**	Make sure that the destination filespec does not contain any 
		**	wildcard specifications.
		*/
		if (fnsplit(DestFile, Drive, Dir, File, Ext) & WILDCARDS) {
			printf("\nERROR: Wildcard characters not allowed in destination file '%s'.\n", DestFile);
			exit(EXIT_FAILURE);
		}

		/*
		**	Determine if the destination is a directory or not.  If it is
		**	a directory, then it must be mutated into proper directory format.
		*/
		{
			struct ffblk block;

			strcpy(Path, DestFile);
			if (Path[strlen(Path)-1] == '\\') {
				Path[strlen(Path)-1] = '\0';
			}

			int result = findfirst(Path, &block, FA_DIREC);
			if (!result && (block.ff_attrib & FA_DIREC)) {
				DestDir = TRUE;
				/*
				**	Make sure that the output directory ends with a backslash or a colon.
				*/
				strcpy(Path, DestFile);
				switch (Path[strlen(Path)-1]) {
					default:
						strcat(Path, "\\");
						DestFile = strdup(Path);
						break;

					case '\\':
					case ':':
						break;
				}
			}
		}

		/*
		**	Verify that the destination is a directory if wildcards were specified
		**	in the source filespec.
		*/
		if (SourceWild && !DestDir) {
			printf("\nERROR: Destination '%s' was not a directory.\n", DestFile);
			exit(EXIT_FAILURE);
		}

		/*
		**	Scan through all specified source files and process them into the 
		**	appropriate audio format.
		*/
		struct ffblk block;

		findfirst(SourceFile, &block, FA_ARCH|FA_RDONLY);
		do {
			Process(SourceFile, block.ff_name, DestFile);
		} while (!findnext(&block));

	}
	catch(int) {
		printf("\n"
				"AUDIOMAK V2.3 (c) 1994, by Westwood Studios\n"
				"USAGE:  AUDIOMAK [option] <sourcefile> <destfile>\n"
				"\n"
				"  Options:\n"
				"    -X-                : Turn compression off.\n"
				"    -V                 : Verbose compression report.\n"
				"\n"
				"  <sourcefile>         : File or filespec of VOC or WAV files to process\n"
				"                         Can be SONARC compressed.\n"
				"  <destfile>           : Destination file or destination directory.  If\n"
				"                         wildcards were used in the source file then this\n"
				"                         can only be a destination directory.\n"
				"\n");
		return(EXIT_FAILURE);
	}

	return(EXIT_SUCCESS);
}

long	rawframes;		// Number of non-compressed frames.
long	rate;				// Sample rate.
long	raw;				// Number of raw bytes output.
long	bit5;				// Number of 5bit codes output.
long	bit4;				// Number of 4bit codes output (@2 samples).
long	bit2;				// Number of 2bit codes output (@4 samples).
long	bit0;				// Number of 0 delta runs.
long	overhead;		// Overhead (wrapper) bytes.
long	original;		// Original data size.
long	compressed;		// Compressed data output.

inline void Log_RawFrame(long val) {rawframes += val;}
inline void Log_Raw(long val) {raw += val;}
inline void Log_5Bit(long val) {bit5 += val;}
inline void Log_4Bit(long val) {bit4 += val;}
inline void Log_2Bit(long val) {bit2 += val;}
inline void Log_0Bit(long val) {bit0 += val;}
inline void Log_Overhead(long val) {overhead += val;}
inline void Log_Compressed(long val) {compressed += val;}
inline void Log_Original(long val) {original += val;}
inline void Log_Rate(long val) {rate = val;}

void Stat_Reset(void)
{
	if (DoVerbose) {
		rawframes = 0;
		rate = 0;
		raw = 0;
		bit5 = 0;
		bit4 = 0;
		bit2 = 0;
		bit0 = 0;
		overhead = 0;
		original = 0;
		compressed = 0;
	}
}

void Stat_Dump(void)
{
	if (DoVerbose) {
		printf("Compression efficiency = %ld%% (%ld bytes)\n", ((original - compressed) * 100) / original, original - compressed);
		printf("  Sample Rate = %ld\n", rate);
		printf("  Uncompressed data..:%7ld %ld%%\n", raw, (raw * 100) / original);
		printf("  Uncompressed frames:%7ld\n", rawframes);
		printf("  5 bit codes........:%7ld %ld%%\n", bit5, (bit5 * 100) / original);
		printf("  4 bit codes........:%7ld %ld%%\n", bit4, (bit4 * 100) / original);
		printf("  2 bit codes........:%7ld %ld%%\n", bit2, (bit2 * 100) / original);
		printf("  0 bit codes........:%7ld %ld%%\n", bit0, (bit0 * 100) / original);
		printf("  overhead bytes.....:%7ld %ld%%\n", overhead, (overhead * 100) / original);
	} else {
		printf("%ld%%\n", ((original - compressed) * 100) / original);
	}
}


void Process(char const *src, char const *name, char const *dest)
{
	char sourcename[MAXPATH];

	/*
	** Open the input file.
	*/
	fnsplit(src, Drive, Dir, File, Ext);
	fnmerge(sourcename, Drive, Dir, NULL, NULL);
	strcat(sourcename, name);

	/*
	**	Open the output filename based on the source filename and the destination
	**	directory or filename.
	*/
	fnsplit(sourcename, NULL, NULL, File, Ext);
	if (DestDir) {
		fnsplit(dest, Drive, Dir, NULL, NULL);
		fnmerge(Path, Drive, Dir, File, ".AUD");
	} else {
		fnsplit(dest, Drive, Dir, NULL, Ext);
		fnmerge(Path, Drive, Dir, File, Ext);
	}

	strupr(sourcename);
	strupr(Path);
	printf("%s ", sourcename, Path);
	Convert(sourcename, Path);
}


void Convert(char const *src, char const *dst)
{
	FILE	*srcfile = 0;
	FILE	*dstfile = 0;

	srcfile = fopen(src, "rb");
	if (!srcfile) {
		perror(src);
		exit(EXIT_FAILURE);
	}

	if (Is_WAV(srcfile)) {
		dstfile = fopen(dst, "wb");
		if (!dstfile) {
			perror(dst);
			exit(EXIT_FAILURE);
		}
		Stat_Reset();
		Convert_WAV(srcfile, dstfile);
		Stat_Dump();
	} else {
		if (Is_VOC(srcfile)) {
			dstfile = fopen(dst, "wb");
			if (!dstfile) {
				perror(dst);
				exit(EXIT_FAILURE);
			}
			Stat_Reset();
			Convert_VOC(srcfile, dstfile);
			Stat_Dump();
		} else {
			printf("ERROR: Unrecognized source file format for '%s'.\n", src);
			exit(EXIT_FAILURE);
		}
	}
	if (dstfile) fclose(dstfile);
	fclose(srcfile);
}


int Is_WAV(FILE *src)
{
	long	size;
	RIFFHeaderType	header;

	fseek(src, 0, SEEK_SET);

	/*
	**	Determine if this is a WAV file.  Examining the file extension is
	**	not foolproof.  The actual data must be looked at.
	*/
	size = fread(&header, 1, sizeof(header), src);
	if (size == sizeof(header)) {
		if (memcmp(header.szRIFF, "RIFF", 4) == 0) {
			if (memcmp(header.szWAVE, "WAVE", 4) == 0) {
				return(TRUE);
			}
		}
	}
	return(FALSE);
}

void Convert_WAV(FILE * src, FILE * dst)
{
	RIFFBlockType block;
	RIFFfmtType fmt;
	RawHeaderType raw;
	int nodo = FALSE;
	long fcount = 0;

	raw.pad = 0;
	raw.Size = 0;
	fwrite(&raw, 1, sizeof(raw), dst);
	Log_Overhead(sizeof(raw));

	/*
	**	At this point, we already know that it is a RIFF (wav) file, so
	**	skip the identifier bytes at the beginning.
	*/
	fseek(src, sizeof(RIFFHeaderType), SEEK_SET);

	/*
	**	Process all the blocks in the RIFF file.
	*/
	for (;;) {
		long s;

		s = fread(&block, sizeof(block), 1, src);
		if (!s) break;

		/*
		**	If this is the format control block, the process it.
		*/
		if (memcmp(block.szDATA, "fmt ", sizeof("fmt ")-1) == 0) {
			s = fread(&fmt, 1, sizeof(fmt), src);
			if (s != sizeof(fmt)) break;

			raw.Rate = (short)fmt.dwSamplesPerSec;
			Log_Rate(raw.Rate);
			raw.Stereo = (fmt.wChannels == 2);
			raw.Bits = (fmt.wBitsPerSample == 16);
			switch (fmt.wFormatTag) {
				default:
				case 1:
					raw.Compression = SCOMP_NONE;
					if (DoSpecial) {
						raw.Compression = SCOMP_WESTWOOD;
					}
					break;

				case 33:
					raw.Compression = SCOMP_SONARC;
					if (DoSpecial) {
						printf("ERROR: Cannot compress an already compressed WAV file.\n");
						nodo = TRUE;
					}
					break;
			}

			/*
			**	Skip any extra format bytes.  For a Sonarc file, there are
			**	extra bytes to skip.
			*/
			fseek(src, block.dwDataLength - sizeof(fmt), SEEK_CUR);

		} else if (memcmp(block.szDATA, "data", sizeof("data")-1) == 0) {

			/*
			**	Add in the size of this data block to the running total of data
			**	count.  For SONARC compressed blocks, there is an extra four bytes
			**	at the start of the data that records the uncompressed size -- who
			**	cares, so skip it.
			*/
			if (raw.Compression == SCOMP_SONARC) {
				fseek(src, 4, SEEK_CUR);
				block.dwDataLength -= sizeof(raw.Size);
			}

			/*
			**	Copy the bulk of the data to the output file.
			*/
			while (block.dwDataLength) {
				long	desired;
				long	actual;

				desired = sizeof(StageBuffer);
				if (block.dwDataLength < desired) {
					desired = block.dwDataLength;
				}
				actual = fread(StageBuffer, 1, (unsigned)desired, src);
				Log_Original(actual);
				block.dwDataLength -= actual;

				/*
				**	Special process to convert audio data into deltas.
				*/
				if (DoSpecial && !nodo) {
					void *sptr = &StageBuffer[0];
					long	a = actual;

					/*
					**	When compressing the data, it must be processed in small
					**	chunks.  Loop through the source and process the chunks
					**	until there is no more source data.  Careful choice of the
					**	size of the buffers ensures that only full chunks are
					**	output.
					*/
					while (a) {
						long	tocomp;
						long	comped;

						tocomp = MIN(a, 2048);
						comped = Compress_Frame(sptr, AltBuffer, tocomp);
						a -= tocomp;
						Log_Compressed(comped);

						#if(FALSE)
						if (comped < tocomp) {
							Decompress_Frame(AltBuffer, sptr, (short)tocomp);
						}
						raw.Size += fwrite(sptr, 1, (size_t)tocomp, dst);
						(char*)sptr += (unsigned)tocomp;
						#else 

						(char*)sptr += (unsigned)tocomp;
						raw.Size += fwrite(&comped, 1, sizeof(short), dst);
						raw.Size += fwrite(&tocomp, 1, sizeof(short), dst);
						raw.Size += fwrite(&MagicNumber, 1, sizeof(MagicNumber), dst);
						raw.Size += fwrite(&AltBuffer[0], 1, (size_t)comped, dst);
						#endif
						fcount++;
					}

				} else {
					raw.Size += actual;
					fwrite(StageBuffer, 1, (unsigned)actual, dst);
					Log_Compressed(actual);
					fcount++;
				}
				if (!actual) break;
			}

		} else {

			/*
			**	Unrecognized blocks are skipped.
			*/
			fseek(src, block.dwDataLength, SEEK_CUR);
		}
	}

	/*
	**	Output the finalized raw header structure.
	*/
	fseek(dst, 0, SEEK_SET);
	fwrite(&raw, 1, sizeof(raw), dst);
}


int Is_VOC(FILE *src)
{
	long 				size;
	VocHeaderType	voc;

	fseek(src, 0, SEEK_SET);
	size = fread(&voc, 1, sizeof(voc), src);
	if (size != sizeof(voc)) {
		return(FALSE);
	}

	if (memicmp(voc.Description, "Creative Voice File", strlen("Creative Voice File")) != 0) {
		return(FALSE);
	}

	return (TRUE);
}


void Convert_VOC(FILE *src, FILE *dst)
{
//	long				size = 0;
	VocHeaderType	voc;
	RawHeaderType	raw;

	raw.pad = 0;
	raw.Size = 0;
	raw.Compression = SCOMP_NONE;
	if (DoSpecial) {
		raw.Compression = SCOMP_WESTWOOD;
	}

	fseek(src, 0, SEEK_SET);
	fread(&voc, 1, sizeof(voc), src);
	fseek(src, voc.Offset, SEEK_SET);

	/*
	**	Output a dummy raw header (will be updated later).
	*/
	raw.Size = 0;
	raw.Rate = 11025;
	raw.Stereo = FALSE;
	raw.Bits = FALSE;
	fwrite(&raw, sizeof(raw), 1, dst);

	/*
	**	Loop through all the VOC chunks in order to build the correct
	**	rawheader structure.
	*/
	char code = -1;
	while (code != 0) {
		char				c;
		long				blocksize=0;
		unsigned			rate=0;
		unsigned char	pack=0;
		ldiv_t	result;

		fread(&code, 1, sizeof(code), src);
		switch (code) {

			/*
			**	General data block.  Packed data is not supported.
			**	If an extended control block has been processed, then
			**	ignore the control bytes in this file.
			*/
			case 1:
				fread(&blocksize, 3, 1, src);

				/*
				**	Determine the sample rate from the special code provided
				**	for this block.  The formula is very inaccurate, so check
				**	for some special codes and fixe the playback rate accordingly.
				**	When dealing with odd sample rates, then just figure out
				**	the rate based on the formula.
				*/
				fread(&rate, 1, 1, src);
				switch (256-rate) {
					case 22:
					case 23:
						raw.Rate = 44100U;
						break;

					case 45:
						raw.Rate = 22050;
						break;

					case 90:
					case 91:
						raw.Rate = 11025;
						break;

					case 181:
						raw.Rate = 5512;
						break;

					default:
						result = ldiv(1000000L, (long)256-(long)rate);
						raw.Rate = (int)result.quot;
						break;
				}
				Log_Rate(raw.Rate);
				fread(&pack, 1, 1, src);

				/*
				**	Copy over the raw data.  If the data is packed, then
				**	it is skipped since packed data is not supported by this
				**	utility (yet).
				*/
				if (pack == 0) {
					long	desired;
					long	actual;

					blocksize -= 2;
					//raw.Size += blocksize;
					while (blocksize) {
						desired = MIN(blocksize, sizeof(StageBuffer));
						actual = fread(StageBuffer, 1, (unsigned)desired, src);
						Log_Original(actual);

						/*
						**	Special process to convert audio data into deltas.
						*/
						if (DoSpecial) {
							void *sptr = &StageBuffer[0];
							long	a = actual;

							/*
							**	When compressing the data, it must be processed in small
							**	chunks.  Loop through the source and process the chunks
							**	until there is no more source data.  Careful choice of the
							**	size of the buffers ensures that only full chunks are
							**	output.
							*/
							while (a) {
								short	tocomp;
								short	comped;

								tocomp = (short)MIN(a, 2048);
								comped = (short)Compress_Frame(sptr, AltBuffer, tocomp);
								a -= tocomp;
								Log_Compressed(comped);

								(char*)sptr += (unsigned)tocomp;
								raw.Size += fwrite(&comped, 1, sizeof(short), dst);
								raw.Size += fwrite(&tocomp, 1, sizeof(short), dst);
								raw.Size += fwrite(&MagicNumber, 1, sizeof(MagicNumber), dst);
								raw.Size += fwrite(&AltBuffer[0], 1, (size_t)comped, dst);
							}

						} else {

							raw.Size += actual;
							fwrite(StageBuffer, 1, (unsigned)actual, dst);
							Log_Compressed(actual);
						}

						//fwrite(StageBuffer, 1, (unsigned)actual, dst);
						blocksize -= actual;
						if (actual != desired) break;
					}
				} else {
					fseek(src, blocksize-2, SEEK_CUR);
				}
				break;

			/*
			**	Continuation block.  Sample rate and pack type is
			** inherited from the previous data block.
			*/
			case 2:
				fread(&blocksize, 1, 3, src);
				if (pack == 0) {
					long	desired;
					long	actual;

					blocksize -= 2;
					raw.Size += blocksize;
					while (blocksize) {
						desired = MIN(blocksize, sizeof(StageBuffer));
						actual = fread(StageBuffer, 1, (unsigned)desired, src);
						fwrite(StageBuffer, 1, (unsigned)actual, dst);
						Log_Original(actual);
						Log_Compressed(actual);
						blocksize -= actual;
						if (actual != desired) break;
					}
				} else {
					fseek(src, blocksize-2, SEEK_CUR);
				}
				break;

			/*
			**	Extended block is used for highspeed or 
			** stereo samples.
			*/
			case 8:
				fseek(src, 3, SEEK_CUR);
				fread(&rate, 2, 1, src);
				fread(&pack, 1, 1, src);
				fread(&c, 1, 1, src);
				raw.Stereo = (c == 1);

				if (raw.Stereo) {
					result = ldiv(128000000L, 65536L-rate);
				} else {
					result = ldiv(256000000L, 65532L-rate);
				}
				raw.Rate = (int)result.quot;
				Log_Rate(raw.Rate);
				break;

			/*
			**	Unprocessed blocks are skipped.
			*/
			case 3:		// Silence block.
			case 4:		// Marker block.
			case 5:		// Embedded string.
			case 6:		// Loop start block.
			case 7:		// End of loop block.
				fread(&blocksize, 1, 3, src);
				fseek(src, blocksize, SEEK_CUR);
				break;

			case 0:		// End of file block.
				break;

			default:
				code = 0;
				break;
		}
	}

	fseek(dst, 0, SEEK_SET);
	fwrite(&raw, sizeof(raw), 1, dst);
}



typedef enum {
	CODE_2BIT,				// Bit packed 2 bit delta.
	CODE_4BIT,				// Nibble packed 4 bit delta.
	CODE_RAW,				// Raw sample.
	CODE_SILENCE			// Run of silence.
} SCodeType;


signed char _2bitencode[5] = {0, 1, 2, 3};
//signed char _2bitencode[5] = {0, 1, (2), 2, 3};
signed int _2bitdecode[4] = {-2, -1, 0, 1};
//signed int _2bitdecode[4] = {-2, -1, 1, 2};

#if(TRUE)
signed char _4bitencode[19] = {
	0, 1, 2, 2, 3, 4, 5, 6, 7, (8), 8, 9, 10, 11, 12, 13, 13, 14, 15
};
signed int _4bitdecode[16] = {-9, -8, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 8};
#else
signed char _4bitencode[33] = {
	0,	0, 0, 1, 1, 1, 2, 2, 
	3, 3, 4, 4, 5, 5, 6, 7, 
	8, (8), 9, 10, 11, 12, 12, 13, 
	13, 13, 14, 14, 14, 15, 15, 15, 
	15
};
signed int _4bitdecode[16] = {-16, -13, -10, -8, -6, -4, -2, -1, 1, 2, 4, 6, 8, 10, 13, 16};
#endif

long Compress_Frame(void * source, void * dest, long size)
{
	unsigned char	*s = (unsigned char *)source;
	unsigned char	*d = (unsigned char *)dest;
	int				delta;
	unsigned int	previous = 0x80;
	long				outcount = 0;
	unsigned char	*s4;				// Scratch pointer into source data.
	unsigned int	p4;				// Scratch "previous" sample value.
	long				max4;
	unsigned char	*lastraw = 0;	// Pointer to last raw sequence code.
	long				osize = size;	// Copy of original compression data length.

	/*
	**	Reduce very small amplitudes to silence.  Usually a rather large
	**	portion of a sample is hovering around the silence value.  This is
	**	due, in part, to the artifacting of the sample process.  These low
	**	amplitudes are not audible.
	*/
	max4 = size;
#if(FALSE)
	while (max4) {
		int delta = (int)s[1] - (int)s[0];

		/*
		**	For steep sample transitions that just border on the range of 4 bit
		**	deltas, adjust them to fit.  This results in small savings but at
		**	no loss to audio quality.
		*/
		if (delta == -18)  s[1] += 2;
		if (delta == -17)  s[1]++;
		if (delta == 18)  s[1] -= 2;
		if (delta == 17)  s[1]--;

		if ((*s > 0x7F && *s < 0x81) && s[1] > 0x7F && s[1] < 0x81) *s = 0x80; 
		s++;
		max4--;
	}
#endif
	s = (unsigned char *)source;

	while (size > 0 && outcount < osize) {

		/*
		**	First check for runs of zero deltas.  If a run of at least
		**	any can be found, then output it.
		*/
		s4 = s;
		max4 = MIN(63+1, size);
		for (int i = 0; i < max4; i++) {
			if (previous != *s4++) break;
		}
		if (i > 2) {
			/*
			**	When there is a code transition, terminate any run of raw
			**	samples.
			*/
			lastraw = 0;

			*d++ = (i-1) | (CODE_SILENCE<<6);
			outcount++;
			s += i;
			size -= i;
			Log_0Bit(i);
			Log_Overhead(1);
			continue;
		}

		/*
		**	If there are fewer than 4 samples remaining, then using delta
		**	compression is inefficient.  Just drop into the raw routine
		*/
		if (size > 4) {

			s4 = s;
			p4 = previous;

			/*
			**	Find out the number of lossless 2 bit deltas available.  These
			**	deltas are always present in quads.  The compressed code is
			**	the delta quad count followed by the deltas in bit packed
			**	bytes.
			*/
			max4 = MIN(64L*4L + 4L + 4L, size);
			for (unsigned i = 0; i < max4; i++) {
				delta = ((int)*s4++) - p4;
				if (delta < -2 || delta > 1 /*|| !delta*/) break;
				//if (delta < -2 || delta > 2 || !delta) break;
				p4 += _2bitdecode[_2bitencode[delta+2]];

				if (((signed)p4) < 0) p4 = 0;
				if (((signed)p4) > 255) p4 = 255;
			}
			i >>= 2;					// Delta 2 always occur in quads -- force this.

			/*
			**	If there is the minimum benificial number of delta 2s available,
			**	then compress them.
			*/
			if (i) {
				Log_2Bit(i*4);
				Log_Overhead(1);

				/*
				**	When there is a code transition, terminate any run of raw
				**	samples.
				*/
				lastraw = 0;

				/*
				**	Output the delta 4 pair count.  This is the number of pairs
				**	minus the 'free' two pairs already assumed to be there.
				*/
				i = MIN(i, 63+1);
				*d++ = (i-1) | (CODE_2BIT<<6);
				outcount++;

				for (int dd = 0; dd < i; dd++) {
					int delta1, delta2, delta3, delta4;

					delta1 = _2bitencode[(((int)*s++) - previous)+2];
					previous += _2bitdecode[delta1];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					size--;

					delta2 = _2bitencode[(((int)*s++) - previous)+2];
					previous += _2bitdecode[delta2];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					size--;

					delta3 = _2bitencode[(((int)*s++) - previous)+2];
					previous += _2bitdecode[delta3];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					size--;

					delta4 = _2bitencode[(((int)*s++) - previous)+2];
					previous += _2bitdecode[delta4];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					size--;

					*d++ = (delta4<<6) | (delta3<<4) | (delta2<<2) | delta1;
					outcount++;
				}
				continue;

			} else {

				s4 = s;
				p4 = previous;

				/*
				**	Find out the number of lossless 4 bit deltas follow.  These
				**	deltas are always present in pairs.  The compressed code is
				**	the delta pair count followed by the deltas in nibble packed
				**	bytes.
				*/
				max4 = MIN(64L*2L+4L+4L, size);
				for (unsigned i = 0; i < max4; i++) {
					delta = ((int)*s4++) - p4;
					if (delta < -9 || delta >= 9 /*|| !delta*/) break;
					//if (delta < -16 || delta > 16 || !delta) break;
					p4 += _4bitdecode[_4bitencode[delta+9]];
					//p4 += _4bitdecode[_4bitencode[delta+16]];
					if (((signed)p4) < 0) p4 = 0;
					if (((signed)p4) > 255) p4 = 255;
				}
				i >>= 1;					// Delta 4 always occur in pairs -- force this.

				/*
				**	If there is the minimum benificial number of delta 4s available,
				**	then compress them.
				*/
				if (i) {
					Log_4Bit(2*i);
					Log_Overhead(1);

					/*
					**	When there is a code transition, terminate any run of raw
					**	samples.
					*/
					lastraw = 0;

					/*
					**	Output the delta 4 pair count.  This is the number of pairs
					**	minus the 'free' two pairs already assumed to be there.
					*/
					i = MIN(i, 63+1);
					*d++ = (i-1) | (CODE_4BIT<<6);
					outcount++;

					for (int dd = 0; dd < i; dd++) {
						int delta1, delta2;

						delta1 = _4bitencode[(((int)*s++) - previous) + 9];
						//delta1 = _4bitencode[(((int)*s++) - previous) + 16];
						previous += _4bitdecode[delta1];
						if (((signed)previous) < 0) previous = 0;
						if (((signed)previous) > 255) previous = 255;
						size--;

						delta2 = _4bitencode[(((int)*s++) - previous) + 9];
						//delta2 = _4bitencode[(((int)*s++) - previous) + 16];
						previous += _4bitdecode[delta2];
						if (((signed)previous) < 0) previous = 0;
						if (((signed)previous) > 255) previous = 255;
						size--;

						*d++ = (delta2 << 4) | (delta1 & 0x0F);
						outcount++;
					}
					continue;
				}
			}
		}

		/*
		**	Raw output since deltas were unsuccessful.  If this is a run
		**	of raw output, then merely tack it onto the run rather than
		**	create a new code sequence.
		*/
		if (lastraw) {
			*lastraw = (*lastraw)+1;

			/*
			**	There is only so much a run code can accomodate.  If the limit
			**	has been reached, then terminate this code.  A new one will be
			**	created if necessary.
			*/
			if ((*lastraw & 0x1F) == 0x1F) {
				lastraw = 0;
			}
		} else {
			
			/*
			**	If there is no current raw dump of samples, then check to see if
			**	this sample can fit into a 5 bit delta.  If it can, then store
			**	it as such as a parasite to the "raw" code.  This will save a byte
			** for any stray 5 bit deltas that happen along.  It is expected that
			**	this is more frequent than 6 or more bit deltas that would necessitate
			**	the use of the RAW code.
			*/
			delta = ((int)*s) - previous;
			if (delta >= -16 && delta <= 15) {
				lastraw = 0;
				*d++ = (CODE_RAW<<6) | 0x20 | (delta & 0x1F);
				outcount++;
				previous = *s++;
				size--;
				Log_5Bit(1);
				continue;
			} else {
				lastraw = d;
				*d++ = (CODE_RAW<<6);
				Log_Overhead(1);
				outcount++;
			}
		}
		Log_Raw(1);
		*d++ = previous = *s++;
		size--;
		outcount++;
	}

	/*
	**	Check to see if the compression process actually resulted in smaller
	**	data size.  In some cases, the 'compressed' data is actually larger.  In
	**	this case, just output the raw frame.  If the compressed and actual frame
	**	size match, then it is presumed that no compression occurs.
	*/
	if (outcount >= osize) {
		memcpy(dest, source, (size_t)osize);
		outcount = osize;
		Log_RawFrame(1);
	}

	return(outcount);
}

#if(FALSE)
long Decompress_Frame(void * source, void * dest, long size)
{
	unsigned int	previous = 0x0080;
	signed char		*s = (signed char *)source;
	unsigned char	*d = (unsigned char *)dest;
	long incount = 0;

	/*
	**	Uncompress the source data until the buffer is filled.
	*/
	while (size > 0) {
		signed char code;		// Compression code.
		int counter;

		code = *s++;
		counter = (code & 0x3F) + 1;
		incount++;

		switch ((code >> 6) & 0x03) {
			case CODE_RAW:

				/*
				**	The "raw" code could actually contain an embedded 5 bit delta.
				**	If this is the case then this is a self contained code.  Extract
				**	and process the delta.
				*/
				if ((counter-1) & 0x20) {
					counter = (counter-1) & 0x1F;
					if (counter & 0x10) counter |= 0xFFE0;
					previous = *d++ = previous + counter;
					size--;

				} else {

					/*
					**	Normal run of raw samples.
					*/
					memcpy(d, s, counter);
					incount += counter;
					size -= counter;
					d += counter-1;
					s += counter;
					previous = *d++;
				}
				break;

			case CODE_4BIT:
				while (counter) {
					int delta;

					delta = *s++;
					incount--;

					previous += (signed)_4bitdecode[delta & 0x0F];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					previous += (signed)_4bitdecode[(delta >> 4) & 0x0F];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					counter--;
				}
				break;

			case CODE_2BIT:
				while (counter) {
					int delta;

					delta = *s++;
					incount--;

					previous += (signed)_2bitdecode[delta & 0x03];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					previous += (signed)_2bitdecode[(delta >> 2) & 0x03];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					previous += (signed)_2bitdecode[(delta >> 4) & 0x03];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					previous += (signed)_2bitdecode[(delta >> 6) & 0x03];
					if (((signed)previous) < 0) previous = 0;
					if (((signed)previous) > 255) previous = 255;
					*d++ = previous;
					size--;

					counter--;
				}
				break;

			default:
			case CODE_SILENCE:
				memset(d, previous, counter);
				d += counter;
				size -= counter;
				break;
		}
	}
	return (incount);
}
#endif
