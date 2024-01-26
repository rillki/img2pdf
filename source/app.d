// built with DMD v2.100
module app;

// phobos
import std.stdio: writefln;
import std.array: array, empty;
import std.file: write, exists, getcwd, dirEntries, SpanMode;
import std.path: dirSeparator, buildPath, baseName;
import std.conv: to;
import std.algorithm: splitter, filter, map, canFind, sort, reverse;
import std.getopt: getopt, GetoptResult, defaultGetoptPrinter;

// printed
import printed.canvas: PDFDocument, IRenderingContext2D, Image;

// version
enum v = "1.8";

// page size in millimeters
enum PageSize: float[2] {
    A1 = [594, 841],
    A2 = [420, 594],
    A3 = [297, 420],
    A4 = [210, 297],
    A5 = [148, 210],
    A6 = [105, 148],
    A7 = [74, 105],
    Letter = [215.9, 279.4],
}

void main(string[] args) {
    if(args.length < 2 || args[1][0] != '-') {
        writefln("\n#img2pdf: incorrect or no commands provided! See \'img2pdf -h\' for more info.\n");
        return;
    }

    // command line boolean arguments
    bool opt_version = false;
    bool opt_sortAscending = true;
    bool opt_orientLandscape = false;

    // command line arguments
    string 
        opt_printType = "stretch",
        opt_path = getcwd(), 
        opt_images = null,
        opt_pageSize = "A4",
        opt_outputFile = "output.pdf";
    string[] imageList = null;

    // parsing arguments
    GetoptResult argInfo;
    try {
        argInfo = getopt(
            args,
            "version|v", "command utility version", &opt_version,
            "printType|t", "print type <stretch, fill, fit> (default: stretch)", &opt_printType,
            "ascending|a", "sort asceding", &opt_sortAscending,
            "landscape|l", "landscape PDF page orientation", &opt_orientLandscape,
            "path|p", "path to images directory", &opt_path,
            "images|i", "specify image names seperated by \',\'", &opt_images, 
            "size|s", "specify page size <A1, ..., A7> (default: A4)", &opt_pageSize, 
            "output|o", "output PDF file name", &opt_outputFile
        );

        // print help if needed
        if(argInfo.helpWanted) {
            defaultGetoptPrinter("\nimg2pdf version v" ~ v ~ " -- Image to PDF converter.", argInfo.options);
            writefln("\nEXAMPLE: img2pdf --path=../temp --images=img1.png,img2.jpg --printType=fit --size=A4 --output=myImages.pdf\n");
            return;
        }

        // print version
        if(opt_version) {
            import std.compiler: version_major, version_minor;
            writefln("img2pdf version " ~ v ~ " -- Image to PDF converter.");
            writefln("Built with %s v%s.%s on %s", __VENDOR__, version_major, version_minor, __DATE__);
            return;
        }

        // split images
        imageList = (opt_images is null) ? opt_path.listdir.filter!(
                a => a.canFind(".jpg", ".jpeg", ".png")
            ).array.sort!("a < b").map!(
                a => opt_path.buildPath(a)
            ).array : opt_images.splitter(',').map!(a => opt_path.buildPath(a)).array;

        // if no images are found, exit
        if(imageList.empty) {
            writefln("\n#img2pdf: no images found!\n");
            return;
        }

        // start
        writefln("\n#img2pdf: STARTING conversion...");

        // convert images
        img2pdf(
            opt_outputFile,
            opt_pageSize.convStringToPageSize,
            opt_sortAscending ? imageList : imageList.dup.reverse,
            opt_printType,
            opt_orientLandscape
        );

        // end
        writefln("#img2pdf: FINISHED...\n");
    } catch(Exception e) {
        writefln("\n#img2pdf: error! %s\n", e.msg);
        return;
    }
}

/++
List all files found in a directory

Params:
    dir = directory to inspect

Returns: an array of file names
+/
string[] listdir(in string dir) {
    return dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => baseName(a.name))
        .array;
}

/++
Converts images to a PDF file

Params:
    pdfDocumentName = pdf file name
    pageSize = pdf page size in millimeters
    images = an array image names including the path
    printType = fill image to pdf, stretch image to pdf, fit image to pdf
    orientLandscape = landscape page orientation, `false` by default
+/
void img2pdf(in string pdfDocumentName, in PageSize pageSize, in string[] images, in string printType = "stretch", in bool orientLandscape = false) {
    // create a pdf document
    PDFDocument pdf;
    if(!orientLandscape) {
        pdf = new PDFDocument(pageSize[0], pageSize[1]);
    } else {
        pdf = new PDFDocument(pageSize[1], pageSize[0]);
    }
    auto context = cast(IRenderingContext2D)(pdf);

    // prints images to pdf
    int nfdontExist = 0;	// for tracking when a new page should be added
    foreach(i, img; images) {
        // checks if image exists
        if(!img.exists) {
            nfdontExist++;

            writefln("#img2pdf: (%s) <%s> does not exist! Skipping...", i, img);
            continue;
        } else {
            // create a new page
            if(i > 0 + nfdontExist) {
                context.newPage();
            }
        }

        // opens an image (skips the image upon failure)
        Image currentImg;
        try {
            currentImg = new Image(img);
        } catch(Exception e) {
            writefln("#img2pdf: (%s) <%s> failed to open; %s", i, img, e.msg);
            continue;
        }

        // prints an image to a blank pdf page
        if(printType == "stretch") {
            context.drawImage(currentImg, 0, 0, context.pageWidth, context.pageHeight);
        } else if(printType == "fill") {
            context.drawImage(currentImg, 0, 0);
        } else if(printType == "fit") {
            if(!orientLandscape) {
                immutable fitImgWidth = context.pageWidth > currentImg.printWidth ? currentImg.printWidth : context.pageWidth;
                immutable fitImgHeight = fitImgWidth / currentImg.printWidth * currentImg.printHeight;
                context.drawImage(currentImg, 0, 0, fitImgWidth, fitImgHeight);
            } else {
                immutable fitImgHeight = context.pageHeight > currentImg.printHeight ? currentImg.printHeight : context.pageHeight;
                immutable fitImgWidth = fitImgHeight / currentImg.printHeight * currentImg.printWidth;
                context.drawImage(currentImg, 0, 0, fitImgWidth, fitImgHeight);
            }
        } else { // error: unrecognized option
            writefln("#img2pdf: Unrecognized option --opt_printType=%s! Only <stretch>, <fill>, <fit> available.", printType);
            return;
        }

        writefln("#img2pdf: (%s) <%s> converted!", i, img.splitter(dirSeparator).array[$-1]);
    }

    // writes data to pdf file
    writefln("#img2pdf: saving <%s>", pdfDocumentName);
    try {
        pdfDocumentName.write(pdf.bytes);
    } catch(Exception e) {
        writefln("#img2pdf: failed to save <%s>; %s", pdfDocumentName, e.msg);
    }
}

/// Converts a string to PageSize enum
PageSize convStringToPageSize(in string pageSize) {
    switch(pageSize) {
        case "A1":
            return PageSize.A1;
        case "A2":
            return PageSize.A2;
        case "A3":
            return PageSize.A3;
        case "A4":
            return PageSize.A4;
        case "A5":
            return PageSize.A5;
        case "A6":
            return PageSize.A6;
        case "A7":
            return PageSize.A7;
        case "Letter":
            return PageSize.Letter;
        default:
            return PageSize.A4;
    }
}







