   if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close" );
    }
    
     if (isOpen("Log")) {
         selectWindow("Log");
         run("Close" );
    }
run("Bio-Formats Macro Extensions");
// Open file
path=getDirectory("image");
 // Here we'll use Bio-Formats to get the dimensions of the file without fully opening it
 run("Bio-Formats Importer", "location=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack");
filename=getTitle();
path=File.directory;
titleExt=File.nameWithoutExtension();

run("Duplicate...", "duplicate");
title=getTitle();

selectWindow(title);
getDimensions(width, height, channels, slices, frames);
w=width;
h=height;
setBatchMode("hide");
print("Filename= "+title);
selectWindow(title);
run("32-bit");
run("Split Channels");


//split now
run("Set Measurements...", "area mean min center integrated display redirect=None decimal=9");
selectWindow("C1-"+title);
ch1=getTitle();
selectWindow(ch1);
run("Measure");

arrayc1v=newArray(w); 
arrayc2v=newArray(h);
for (p=0; p<w; p++){
	for (i=0; i<h; i++){
	V=getPixel(p, i);
	n=i+(w-1)*p;
	arrayc1v[n]=V;
	}
}

ch1Mean = getResult("Mean", 0);
c1max=getResult("Max",0);
run("Subtract...", "value="+ch1Mean); // ch1 is now mean subtracted

//get the second image
selectWindow("C2-"+title);
ch2=getTitle();
selectWindow(ch2);
run("Measure");
for (p=0; p<w; p++){
	for (i=0; i<h; i++){
	V=getPixel(p, i);
	n=i+(w-1)*p;
	arrayc2v[n]=V;
	}
}
ch2Mean=getResult("Mean",1);
c2max=getResult("Max",1);
run("Subtract...", "value="+ch2Mean); //ch2 is now mean subtrtacted

//multiply two images an get raw density
imageCalculator("Multiply create 32-bit", ch1, ch2); // this is the value in the nuerator
selectWindow("Result of "+ch1);
meanSub_chanProd=getTitle(); 
run("Measure");
numerator_sum=getResult("RawIntDen",2);


selectWindow(ch1);
run("Square");
run("Measure");
ch1_meanSub_squared_sum=getResult("RawIntDen",3);


selectWindow(ch2);
run("Square");
run("Measure");
ch2_meanSub_squared_sum=getResult("RawIntDen",4);
//print(ch2_meanSub_squared_sum);


denom_product = ch1_meanSub_squared_sum*ch2_meanSub_squared_sum;
denom = Math.sqrt(denom_product);

//does this make sense
selectWindow(meanSub_chanProd);
run("Divide...", "value="+denom);
rename("pearsonsmaybeidunno");
pearsons=getTitle();
resetMinAndMax;
run("kTurbo");
run("Enhance Contrast", "saturated=0.35");



//print(denom);
pearson = numerator_sum/denom;

// Save Pearson's correlation to a text file

File.saveString(pearson, path + titleExt+ "Pearsons_Correlation.txt");



   if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close" );
    }
    
    selectWindow(ch1);
    close();
    selectWindow(ch2);
    close();
setBatchMode("exit and display");
print("Pearson's correlation="+pearson);

Plot.create("Scatter Plot", "C1", "C2");
Plot.setLimits(0, c1max, 0, c2max);
Plot.add("dots", arrayc1v, arrayc2v);