#include "KEY.H"

#include <stdint.h>
#include <stdio.h>

static int failures = 0;

template<class T> inline T enum_and(T t1, T t2)
{
	return((T)((int)t1 & (int)t2));
}

template<class T> inline T enum_not(T t1)
{
	return((T)(~(int)t1));
}

static void expect_int(char const *label, int actual, int expected)
{
	if (actual != expected) {
		printf("%s: got 0x%08x expected 0x%08x\n", label, actual, expected);
		failures++;
	}
}

int main()
{
	KeyNumType released_enter = (KeyNumType)(KN_RETURN | KN_RLSE_BIT);
	KeyNumType stripped = enum_and(released_enter, enum_not(KN_RLSE_BIT));

	expect_int("release bit mask", (int)stripped, KN_RETURN);
	return failures == 0 ? 0 : 1;
}
