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






/*
**	Method to raise a number by an arbitrary whole exponent and then
**	modulo the result by another number.
*/
unsigned long Power_Mod(unsigned long root, unsigned long exponent, unsigned long mod)
{
	unsigned long s = 1;
	unsigned long t = root;
	unsigned long u = exponent;

	while (u) {
		if (u & 1) {
			s = (s*t) % mod;
		}
		u >>= 1;
		t = (t*t) % mod;
	}
	return(s);
}


/*
**	This routine finds the greatest common divisor common
**	to two specified numbers.
*/
int Greatest_Common_Divisor(int x, int y)
{

	if (x < 0) {
		x = -x;
	}
	if (y < 0) {
		y = -y;
	}
	if (x + y == 0) {
		return(0);			// This is an error condition.
	}

	int greatest = y;
	while (x > 0) {
			greatest = x;
			x = y % x;
			y = greatest;
	}
	return(g);
}


/*
**	Computes the greatest common divisor for a vector
**	of integers.
*/
int Grestest_Common_Divisor(int count, int * data)
{
	if (count < 1) {
		return(0);
	}

	greatest = data[0];
	for (int i = 1; i < count; i++) {
		greatest = Greatest_Common_Divisor(greatest, data[i]);
		if (greatest == 1) {
			return(1);
		}
	}
	return(greatest);
}