#import <Monet/MOColor.h>

MOColor MOMakeColor(float aRed, float aGreen, float aBlue)
{
	MOColor color;

	color.red	= aRed;
	color.green	= aGreen;
	color.blue	= aBlue;

	return color;
}
