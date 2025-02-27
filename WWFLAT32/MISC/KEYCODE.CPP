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


#include	<stdio.h>
#include	<stdlib.h>
#include	<conio.h>
#include	<ctype.h>
#include	<string.h>

#define	true	1
#define	false	0
typedef int bool;

char KeyPhrase[128] = "";
char KeyCheck[128] = "";
long Code = 0x00000000L;


extern "C" {
long Calculate_CRC(void const * buffer, long length);
}
long Obfuscate(char const * string);


int main(int , char ** )
{
	char buffer[128];

	/*
	**	Fetch the key phrase from the console.
	*/
	for (;;) {

		/*
		**	Fetch the pass phrase.
		*/
		puts("\nEnter password phrase:");
		int key = 0;
		int index = 0;
		KeyPhrase[0] = '\0';
		bool process = true;
		while (process) {
			key = getche();

			switch (key) {
				case 0x08:
					if (index) {
						KeyPhrase[--index] = '\0';
					}
					break;

				case 0x0D:
				case 0x0A:
					process = false;
					break;

				default:
					if (isprint(key)) {
						KeyPhrase[index++] = key;
						KeyPhrase[index] = '\0';
					}
					break;
			}
		}
		puts("");

		/*
		**	Verify that it is long enough.
		*/
		if (strlen(KeyPhrase) == 0) break;

		/*
		**	Calculate the code for the key phrase.
		*/
		Code = Obfuscate(KeyPhrase);


		sprintf(buffer, "0x%08lX", Code);
		puts(buffer);
	}

	puts("Terminated");
	return(0);
}


/***********************************************************************************************
 * Obfuscate -- Sufficiently transform parameter to thwart casual hackers.                     *
 *                                                                                             *
 *    This routine borrows from CRC and PGP technology to sufficiently alter the parameter     *
 *    in order to make it difficult to reverse engineer the key phrase. This is designed to    *
 *    be used for hidden game options that will be released at a later time over Westwood's    *
 *    Web page or through magazine hint articles.                                              *
 *                                                                                             *
 *    Since this is a one way transformation, it becomes much more difficult to reverse        *
 *    engineer the pass phrase even if the resultant pass code is known. This has an added     *
 *    benefit of making this algorithm immune to traditional cyrptographic attacks.            *
 *                                                                                             *
 *    The largest strength of this transformation algorithm lies in the restriction on the     *
 *    source vector being legal ASCII uppercase characters. This restriction alone makes even  *
 *    a simple CRC transformation practically impossible to reverse engineer. This algorithm   *
 *    uses far more than a simple CRC transformation to achieve added strength from advanced   *
 *    attack methods.                                                                          *
 *                                                                                             *
 * INPUT:   string   -- Pointer to the key phrase that will be transformed into a code.        *
 *                                                                                             *
 * OUTPUT:  Returns with the code that the key phrase is translated into.                      *
 *                                                                                             *
 * WARNINGS:   A zero length pass phrase results in a 0x00000000 result code.                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/19/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
long Obfuscate(char const * string)
{
	char buffer[128];

	if (!string) return(0);
	memset(buffer, '\xA5', sizeof(buffer));

	/*
	**	Copy key phrase into a working buffer. This hides any transformation done
	**	to the string.
	*/
	strncpy(buffer, string, sizeof(buffer));
	buffer[sizeof(buffer)-1] = '\0';
	int length = strlen(buffer);

	/*
	**	Only upper case letters are significant.
	*/
	strupr(buffer);

	/*
	**	Ensure that only visible ASCII characters compose the key phrase. This
	**	discourages the direct forced illegal character input method of attack.
	*/
	for (int index = 0; index < length; index++) {
		if (!isgraph(buffer[index])) {
			buffer[index] = 'A' + (index%26);
		}
	}

	/*
	**	Increase the strength of even short pass phrases by extending the
	**	length to be at least a minimum number of characters. This helps prevent
	**	a weak pass phrase from compromising the obfuscation process. This
	**	process also forces the key phrase to be an even multiple of four.
	**	This is necessary to support the cypher process that occurs later.
	*/
	if (length < 16 || (length & 0x03)) {
		int maxlen = 16;
		if (((length+3) & 0x00FC) > maxlen) {
			maxlen = ((length+3) & 0x00FC);
		}
		for (index = length; index < maxlen; index++) {
			buffer[index] = 'A' + ((('?' ^ buffer[index-length]) + index) % 26);
		}
		length = index;
		buffer[length] = '\0';
	}

	/*
	**	Transform the buffer into a number. This transformation is character
	**	order dependant.
	*/
	long code = Calculate_CRC(buffer, length);

	/*
	**	Record a copy of this initial transformation to be used in a later
	**	self referential transformation.
	*/
	long copy = code;

	/*
	**	Reverse the character string and combine with the previous transformation.
	**	This doubles the workload of trying to reverse engineer the CRC calculation.
	*/
	strrev(buffer);
	code ^= Calculate_CRC(buffer, length);

	/*
	**	Perform a self referential transformation. This makes a reverse engineering
	**	by using a cause and effect attack more difficult.
	*/
	code = code ^ copy;

	/*
	**	Unroll and combine the code value into the pass phrase and then perform
	**	another self referential transformation. Although this is a trivial cypher
	**	process, it gives the sophisticated hacker false hope since the strong
	**	cypher process occurs later.
	*/
	strrev(buffer);		// Restore original string order.
	for (index = 0; index < length; index++) {
		code ^= (unsigned char)buffer[index];
		unsigned char temp = (unsigned char)code;
		buffer[index] ^= temp;
		code >>= 8;
		code |= (((long)temp)<<24);
	}

	/*
	**	Introduce loss into the vector. This strengthens the key against traditional
	**	cryptographic attack engines. Since this also weakens the key against
	**	unconventional attacks, the loss is limited to less than 10%.
	*/
	for (index = 0; index < length; index++) {
		static unsigned char _lossbits[] = {0x00,0x08,0x00,0x20,0x00,0x04,0x10,0x00};
		static unsigned char _addbits[] = {0x10,0x00,0x00,0x80,0x40,0x00,0x00,0x04};

		buffer[index] |= _addbits[index % (sizeof(_addbits)/sizeof(_addbits[0]))];
		buffer[index] &= ~_lossbits[index % (sizeof(_lossbits)/sizeof(_lossbits[0]))];
	}

	/*
	**	Perform a general cypher transformation on the vector
	**	and use the vector itself as the cypher key. This is a variation on the
	**	cypher process used in PGP. It is a very strong cypher process with no known
	**	weaknesses. However, in this case, the cypher key is the vector itself and this
	**	opens up a weakness against attacks that have access to this transformation
	**	algorithm. The sheer workload of reversing this transformation should be enough
	**	to discourage even the most determined hackers.
	*/
	for (index = 0; index < length; index += 4) {
		short key1 = buffer[index];
		short key2 = buffer[index+1];
		short key3 = buffer[index+2];
		short key4 = buffer[index+3];
		short val1 = key1;
		short val2 = key2;
		short val3 = key3;
		short val4 = key4;

		val1 *= key1;
		val2 += key2;
		val3 += key3;
		val4 *= key4;

		short s3 = val3;
		val3 ^= val1;
		val3 *= key1;
		short s2 = val2;
		val2 ^= val4;
		val2 += val3;
		val2 *= key3;
		val3 += val2;

		val1 ^= val2;
		val4 ^= val3;

		val2 ^= s3;
		val3 ^= s2;

		buffer[index] = val1;
		buffer[index+1] = val2;
		buffer[index+2] = val3;
		buffer[index+3] = val4;
	}

	/*
	**	Convert this final vector into a cypher key code to be
	**	returned by this routine.
	*/
	code = Calculate_CRC(buffer, length);

	/*
	**	Return the final code value.
	*/
	return(code);
}


