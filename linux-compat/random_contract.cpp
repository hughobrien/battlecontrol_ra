#include "RANDOM.H"

#include <stdint.h>
#include <stdio.h>

static int failures = 0;

static void expect_int(char const * label, int actual, int expected)
{
	if (actual != expected) {
		printf("%s: got %d expected %d\n", label, actual, expected);
		failures++;
	}
}

static void expect_u32(char const * label, uint32_t actual, uint32_t expected)
{
	if (actual != expected) {
		printf("%s: got 0x%08x expected 0x%08x\n", label, actual, expected);
		failures++;
	}
}

static void check_next_sequence()
{
	RandomClass random(0xffffffffU);
	expect_int("seed storage width", (int)sizeof(random.Seed), 4);

	int value = random();
	expect_int("next[0] value", value, 3704);
	expect_u32("next[0] seed", random.Seed, 0xbe39e1ccU);

	value = random();
	expect_int("next[1] value", value, 20063);
	expect_u32("next[1] seed", random.Seed, 0x11397c15U);

	value = random();
	expect_int("next[2] value", value, 8602);
	expect_u32("next[2] seed", random.Seed, 0x26866b2aU);
}

static void check_ranged_sequence()
{
	RandomClass random(0xffffffffU);
	expect_int("range normal", random(0, 100), 95);
	expect_u32("range normal seed", random.Seed, 0x11397c15U);

	random = RandomClass(0xffffffffU);
	expect_int("range swapped", random(100, 0), 95);
	expect_u32("range swapped seed", random.Seed, 0x11397c15U);

	random = RandomClass(0xffffffffU);
	expect_int("range equal", random(5, 5), 5);
	expect_u32("range equal seed", random.Seed, 0xffffffffU);

	random = RandomClass(0x80000000U);
	expect_int("range signed", random(-7, 7), 5);
	expect_u32("range signed seed", random.Seed, 0x80003039U);
}

int main()
{
	check_next_sequence();
	check_ranged_sequence();
	return failures == 0 ? 0 : 1;
}
