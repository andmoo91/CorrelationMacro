// ManualMask_Nucleus_CellMask_2023-05-09.ijm
// This Macro works on an open image
// It first adds a value of 1 to all channels which is only to ensure that 0 value pixel intensity values within the cytoplasm do not get converetd to NaNs along with the nuc and extracellular area
// Prompts user to trace teh nucleus with a polygon tool then spline fits to be a better trace
// prompts user to trace the cell border then interpoltes to get higher sampling density and spline fits
// Saves the roi in a directory of the user's choosing
// creates mask channels for nucleus and cell (these are 16bit so merging is easier and the values are binary but 0, 65535
// There's a bit that splits the original channel and merges the two masks back in and saves the new image as a tiff with n+2 channels where n = original channel #
// The image is then split and the nucleus and extracellular space are removed and set as 0 and the image is saved as a 16 bit
// because the 0 values affect the intensity mean this will skew the PCC, so I convert to 32 bit and NaN convert




macro "ManualMask_Nucleus_CellMask_2023-05-09" {
  
 
// Open file
path=getDirectory("image");
   run("Bio-Formats Importer", "location=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT open"); 

    originalImageName = getTitle();
    titleExt=File.nameWithoutExtension();
    path=File.directory();
    path = getDirectory("image");
if (!path.endsWith(File.separator)) {
    path += File.separator;
}

    print(path);
	 if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
  }

    
    run("Add...", "value=1 stack"); // this is just because I don't want any 0 values in the image getting nan'd later
    getDimensions(width, height, channels, slices, frames);
    print("Processing image: "+originalImageName);

    // Select the polygon tool and prompt user to select the nucleus
   
    Dialog.create("Nucleus Mask");
    Dialog.addMessage("This macro will prompt you to trace the nucleus and cell border with the polygon selection tool \n It will spline fit your ROI so don't worry too much about being perfect!");
    Dialog.show();
  
    
    waitForUser("Please select the nucleus");
     setTool("polygon");
    if (selectionType() == -1) {
        showMessage("No selection was made.");
        return;
    }
    run("Fit Spline");
    roiManager("Add");

    // Prompt user to select the cell boundary

    waitForUser("Please select the cell boundary using the polygon selection tool.");
    if (selectionType() == -1) {
        showMessage("No selection was made.");
        return;
    }
    run("Interpolate", "interval=100 smooth");
    run("Fit Spline");
    roiManager("Add");

 //--------------------------------- Save the ROIs------------------//
    
    roiManager("Save", path + titleExt+"ROIs.zip");

//-------------------------MakeTheMaskChannels--------------------//
newImage("nucleus_mask", "16-bit black", width, height, 1);
    roiManager("Select", 0);
    run("Set...","value=65535");
    newImage("cell_mask", "16-bit black", width, height, 1);
    roiManager("Select", 1);
    run("Set...","value=65535");



if (channels > 1) {
    selectWindow(originalImageName);
    run("Split Channels");
    mergeCommand = "";
    for (i = 1; i <= channels; i++) {
        mergeCommand += "c" + i + "=C" + i + "-" + originalImageName + " ";
    }
    mergeCommand += "c" + (channels + 1) + "=" + "nucleus_mask c" +  (channels + 2) + "=cell_mask create";
    run("Merge Channels...", mergeCommand);
} else {
    run("Merge Channels...", "c1=" + originalImageName + " c2=nucleus_mask c3=cell_mask create");
}



// If the number of characters before "COS7" is fixed and known, for example 24
trimmedFileName = substring(titleExt, 24);
print(trimmedFileName);


 // --------------Save the merged image---------------------------//
    saveAs("Tiff", path + trimmedFileName + "_NucAndCellMasks.tif");
    maskImage = getTitle();
//----------------------------------------------------------------//
    // Split channels again for subtraction
    run("Split Channels");

    // Loop through each original channel
    for (i = 1; i <= channels; i++) {
        selectWindow("C"+i+"-"+maskImage);
        nuc=channels+1;
        mask=nuc+1;
        imageCalculator("Subtract create", "C"+i+"-"+maskImage,"C"+nuc+"-"+maskImage);
        selectWindow("Result of C"+i+"-"+maskImage);
        rename("C"+i+"_subtracted");
        imageCalculator("AND create", "C"+i+"_subtracted", "C"+mask+"-"+maskImage);
        selectWindow("Result of C"+i+"_subtracted");
        rename("C"+i+"_final");
        close("C"+i+"_subtracted");
    }

    // Merge back all the channels
    mergeCommand = "";
    for (i = 1; i <= channels; i++) {
        mergeCommand += "c" + i + "=C" + i + "_final ";
    }
    mergeCommand += " create";
    run("Merge Channels...", mergeCommand);
	title3=getTitle();
	selectWindow(title3);
	run("32-bit");
	setThreshold(0.000000010, 1000000000000000000000000000000.000000000);
	run("NaN Background");
	selectWindow(title3);
	close("\\Others");
	run("Subtract...", "value=1 stack"); // This brings the values back to their original...it probably doesn't matter but its better this way
	
	saveAs("Tiff", path + trimmedFileName +"32NaN-Masked");
	run("Split Channels");
	selectWindow("C1-"+trimmedFileName+"32NaN-Masked.tif");
	saveAs("Tiff", path + trimmedFileName +"32NaN-Masked_C1");
	selectWindow("C2-"+trimmedFileName+"32NaN-Masked.tif");
	saveAs("Tiff", path + trimmedFileName +"32NaN-Masked_C2");
	close("*");
}