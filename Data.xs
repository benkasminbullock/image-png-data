#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "image-png-data-perl.c"

typedef image_png_data_t * Image__PNG__Data;

MODULE=Image::PNG::Data PACKAGE=Image::PNG::Data

PROTOTYPES: DISABLE

BOOT:
	/* Image__PNG__Data_error_handler = perl_error_handler; */

