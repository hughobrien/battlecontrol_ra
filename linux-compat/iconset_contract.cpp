#include <cstdint>
#include <cstring>

typedef uint16_t WORD;

#define WIN32 1

#include "TILE.H"
#include "COMPAT.H"

int main()
{
	unsigned char storage[sizeof(IControl_Type) + 1] = {};
	IControl_Type header = {};
	header.MapWidth = 3;
	header.MapHeight = 2;
	header.ColorMap = 16;

	std::memcpy(storage + 1, &header, sizeof(header));
	void const * iconset = storage + 1;

	if (Get_IconSet_MapWidth(iconset) != 3) return 1;
	if (Get_IconSet_MapHeight(iconset) != 2) return 2;
	if (Get_IconSet_ControlMap(iconset) != storage + 17) return 3;

	return 0;
}
