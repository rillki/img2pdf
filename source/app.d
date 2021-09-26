module app;

import std;
import pdfed;

void main(string[] args) {
	if(args.length < 2) {
		("\n=========================================================\n" ~
			"img2pdf  v1.5 -- Image to PDF converter.\n" ~
			"---------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [images] [file] {options}\n" ~
			"\nOPTIONS:\n" ~ 
			"\t[stretch]   stretch img to PDF page size\n" ~
			"\t\t    -strue, -sfalse\n" ~
			"\t[order]     sort files (ascending, descending)\n" ~
			"\t\t    -asc, -desc\n" ~
			"\t[orient]    orientation (portrait, landscape)\n" ~
			"\t\t    -portrait, -landscape\n" ~
			"\nDEFAULTS:" ~ 
			"\n\t[path]     cwd/ (\'/\' or \'\\\\\' path identifier)" ~
			"\n\t[images]   all *.jpg, *.png in [path]" ~
			"\n\t[file]     [path]/output.pdf" ~
			"\n\t[stretch]  -strue" ~
			"\n\t[order]    -asc" ~
			"\n\t[orient]   -portrait\n" ~
			"\nEXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"\t\t-sfalse -asc -portrait\n" ~
			"=========================================================\n"
		).writeln;
		return;
	}

	// remove binary name
	args = args[1..$];
	
	auto findArg = (const string sfind, const string sdefault){
		auto temp = args.filter!(a => a.canFind(sfind)).array;
		return (
			temp.empty ?
			sdefault : 
			temp[0]
		);
	};

	// find path
	immutable path = findArg(dirSeparator, getcwd);
	if(!path.exists) {
		writefln("\n#img2pdf: directory <%s> is does not exist!\n", path);
		return;
	}
	
	// find pdf document name, stretch image to pdf, file sorting order, orientation
	immutable pdfDocumentName = path.buildPath(findArg(".pdf", "output.pdf"));
	immutable stretchToPDFSize = findArg("-sfalse", null).empty;
	immutable sortAscending = findArg("-desc", null).empty;
	immutable orientPortrait = findArg("-landscape", null).empty;

	// find images
	auto arg_images = args.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array;
	immutable images = (
		arg_images.empty ? 
		path.listdir.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array.sort!("a < b").map!(a => path.buildPath(a)).array :
		arg_images[0].splitter(',').map!(a => path.buildPath(a)).array
	).to!(immutable string[]);
	

	// if no images are found, exit
	if(images.empty) {
		writefln("\n#img2pdf: no images found!\n");
		return;
	}

	// start
	writefln("\n#img2pdf: starting conversion...\n");
	
	// convert images
	img2pdf(
		pdfDocumentName, 
		(sortAscending ? images : images.dup.to!(string[]).reverse), 
		stretchToPDFSize,
		orientPortrait
	);
	
	// end
	writefln("\n#img2pdf: finished...\n");
}

/++
List all files found in a directory

Params:
	dir = directory to inspect

Returns: an array of file names
+/
string[] listdir(const string dir) {
    return dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => baseName(a.name))
        .array;
}















