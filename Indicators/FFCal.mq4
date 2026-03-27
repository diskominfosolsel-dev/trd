
//-----------------------------------------------------------------------------+
//                                                                             |
//                               FFCal.mq4                                     |
//                                                                             |
//-----------------------------------------------------------------------------+
#property copyright "derkwehler, Copyright @ 2006"
#property link      "http://www.forexfactory.com" 
//                  (email: derkwehler@gmail.com)
//------------------------------------------------------------------------------
// FFCal_v20, dated 7/07/09:
//
// This indicator i written in cooperation with http://www.forexfactory.com and 
// with the assistance of those acknowledged below.
//
// This "indicator" calls DLLs to fetch a special XML file from the 
// ForexFactory web site.  It then parses it and writes it out as a .CSV 
// file, which it places in the folder: experts/files so that IsNewsTime() 
// can use that file to tell if it is near announcement time.
//
// It does this once when it starts up and once per 6 hours in case there  
// have been any updates to the annoucement calendar.  In order to lessen 
// sudden traffic on the FF site, it refreshes every 6 hours on a random 
// minute.
//
// SAMPLE CALLS TO THE INDICATOR:
//
//     int minutesSincePrevEvent = 
//            iCustom(NULL, 0, "FFCal", true, true, false, true, true, 1, 0);
//
//     int minutesUntilNextEvent = 
//            iCustom(NULL, 0, "FFCal", true, true, false, true, true, 1, 1);
//
//     // Use this call to get ONLY impact of previous event
//     int impactOfPrevEvent = 
//            iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 0);
//
//     // Use this call to get ONLY impact of nexy event
//     int impactOfNextEvent = 
//            iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 1);
//
// EXAMPLE CODE FOR USE IN AN EA:
// (NOTE I HAVE PUT IN CODE TO CALL THE INDICATOR ONLY ONCE PER MINUTE)
//
// // EA Setting variables
// extern int MinsBeforeNews = 60; // mins before an event to stay out of trading
// extern int MinsafterNews  = 60; // mins after  an event to stay out of trading
//
// // Global variable at top of file
// bool NewsTime;
//
// // Function to check if it is news time
// void NewsHandling()
// {
//     static int PrevMinute = -1;
//     if (Minute() != PrevMinute)
//     {
//         PrevMinute = Minute();   
//         int minutesSincePrevEvent =
//             iCustom(NULL, 0, "FFCal", true, true, false, true, true, 1, 0);
//         int minutesUntilNextEve nt =
//             iCustom(NULL, 0, "FFCal", true, true, false, true, true, 1, 1);
//         NewsTime = false;
//         if ((minutesUntilNextEvent <= MinsBeforeNews) || 
//             (minutesSincePrevEvent <= MinsAfterNews))
//         {
//             NewsTime = true;
//         }
//     }
// }//newshandling
//
//-----------------------------------------------------------------------------
// Acknowledgements:
//
// (Unknown) - Paul Hampton-Smith (WinInet.mqh, paul1000@pobox.com) showed 
//             me how to import functions from wininet.dll
//
// (Unknown) - Abhi, for GrebWeb and LogUtils functionality (and fixing my email 
//             address before mailing it to me) grabweb.mq4 Copyright © 2006.
//             http://www.megadelfi.com/experts/ (email: grabwebexpert{Q)megadelfi.com)
//            
// 2/14/2007:  Robert Hill added code for using text objects instead
//             of "Comment()" for easier reading
//
// 2/25/2007:  Paul Hampton-Smith for his TimeZone DLL code
// 3/31/2007:  Code replaces by simpler method from BurgerKing
//
// 2/26/2007:  Mike Nguyen (Added by MN) the following things: 
//           - Connection test so that MT4 doesnt hang when 
//             there is no server connection                 
//           - Fixed some minor syntax because was getting 
//             "too many files open error..."
//
// 4/02/2007:  Mike Nguyen (Added by MN) the following things: 
//           - Added ability to disable Web/URL updates. This is so that the 
//             multiple instances of the indicator used by other charts or EAs
//             dont fight with each other (Error code 4103)
//           - Made file name global and indicator now deletes the xml file  
//             each time the indicator is put on or removed from chart. Fixed 
//             one case of divide by zero where multiple charts indicator is 
//             on was trying to overwrite the same file (forces a new 
//             download of the xml)
//
// 4/29/2007:  Derk Wehler
//           - Fixed problem where indicator returns zero for "Minutes Until 
//             Next Event" when there are no more events for the week for 
//             that currency pair.  That caused EAs calling it to think that
//             it was always new time.  Instead, we now set it to a flag
//             value, which EAs can test for.
//
// 5/16/2007:  Derk Wehler
//           - Added sample code to header
//
// 6/02/2007:  Derk Wehler (thanks to "Flourishing")
//           - Changed how often it updates the file from the FF site web 
//             page.  Now it uses a global variable, so that when you have 
//             it running on multiple charts, it should only update once 
//             every 4 hours for all of them.
//
// 6/05/2007:  Derk Wehler
//           - Fixed logHandle error by resetting to -1 when closed
//           - Added "NeedToGetFile" variable for getting the XML if it 
//             does not already exist
//           - Added extern "SaveXmlFiles", so that when FFCal de-inits, 
//             the user can choose whether or not to delete old XML files
//
/*=================================================================================================
FFCal Headlines Overview:

This is a trimmed down version of FFCal_v20 dated 07/07/2009.  All three impact level news events 
are selected for display.  What is not displayed is the impact level ID, and the Previous and 
Forecast data, as it is the timing of the news event that is important, not the contents thereof.  
The individual line for a news event can be colored based on the impact level.  The display is on 
top of a background which hides the chart underneath.  All four window corners can be used.  Text 
sizes 8-10 are supported with their own custom sized backgrounds.  If an out-of-range text size is
entered, it defaults to aize 9.  The vertical display and second alert are removed.

The following enhancements are added to FFCal revision 20, released July 07, 2009 -

 1. Ability to turn the indicator off without deleting it from the chart is added.  For the input 
    "Indicator_On" select "false".  The indicator will retain your chart settings but not display. 
 2. The display order of lines is now identical for upper and lower chart corners; no inversion! 
 3. An optional custom sized colored background is available for each text size, 8-10, allowing
    a clear FFCal display by hiding the chart beneath.
 4. Ability to display either normal or bold font is added.
 5. Ability to display other fonts is added.  When using the optional background with fonts other 
    than Arial, you may have to increase the width of the background (input provided).
 7. The compile is somewhat edited and "dressed up" for improved simplicity and clarity of 
    organization.  And the External Inputs are re-worked and re-arranged for improved clarity.
    
What is the "Broker_Watermark" input about?  Each broker has their name appear in pictures of MT4
charts.  This Watermark is typically in the lower left of the chart picture, which means it will
appear in corner 2 of the chart itself if there are no chart sub-windows being used.  In order for
the Watermark to appear clearly, and not overlay/obscure information in the FFCal corner 2 display,
select "true" for this input.  If the chart contains no sub-window, then the TxtVShift for display
in corner 2 increases to "18" to allow space for the Watermark.  If the optional background is 
being used, it is automatically increased in height, and the text within is raised to allow space 
for the Watermark to appear within the background.     
                                                                      - Traderathome (03-30-2010)
=================================================================================================*/	
 
 
//+-----------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                       |
//+-----------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2006, Derk Wehler"
#property link      "http://www.forexfactory.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 CLR_NONE
#property indicator_color2 CLR_NONE
#property indicator_color3 CLR_NONE

#define TITLE		0
#define COUNTRY   1
#define DATE		2
#define TIME		3
#define IMPACT		4
#define FORECAST	5
#define PREVIOUS	6

/*-------------------------------------------------------------------------------------------------
Suggtested Settings:                 White Charts          Black Charts

TxtStyle                             Verdana Bold          Arial
FFCal_Title                          Black                 DarkGray
News_High_Impact                     Crimson               Red
News_Medium_Impact                   Blue                  CornflowerBlue
News_Low_Impact                      Green                 LimeGreen
News_No_Impact                       DarkViolet            Orchid     
Color_Background                     White                 C'15,15,15'

-------------------------------------------------------------------------------------------------*/
//global external inputs---------------------------------------------------------------------------
extern bool    Indicator_ON         = true;
extern int     DisplayWindow_0123   = 0;
extern int		DisplayCorner        = 2;		        // corners: 0=Upper Left, 1=Upper Right, 2=lower left, 3=lower right
extern string  TxtStyle             = "Verdana Bold";// choices of font style (Arial, Arial Bold, Verdana, Verdana Bold, etc.)
extern int 		TxtSize_8_9_10 	   = 8;             // Text sizes 8-10 are accomodated with custom background box sizes     
extern color 	FFCal_Title 	      = Black;      
extern color 	News_Impact_High     = Crimson;       
extern color 	News_Impact_Medium   = Blue;      
extern color 	News_Impact_Low      = Green;
extern color   News_Impact_None     = DarkViolet;     
extern color   Color_Background     = White; 
extern int     Widen_Background     = 0;             // +/- #s vary background width to accomdate font styles, etc.
extern bool    Broker_Watermark     = true;          // Incr. V in corner 2 so Watermark will not obscure text in pictures   
extern int		Alert_Minutes_Before = 0;			     // Set to "0" for no Alert
extern int		Offset_Hours	      = 0;             // Set to "0" to not adjust time/DST time settings from their default
extern bool    Exclude_Impact_Low   = false;
extern bool	   Put_USD_News_On_All  = false;         // "true" puts USD news on non-USD pair charts

//global buffers and variables---------------------------------------------------------------------
int 	      xmlHandle, BoEvent, finalend, end, begin, minsTillNews, tmpMins, idxOfNext, dispMinutes[2];
int         dispMins,Days,Hours,Mins;
int         i,curX,curY,W,Box,x1,x2,x3,y1,y2,y3,EventSpacer,TitleSpacer,TxtSize;
int         WebUpdateFreq   = 240;     // Minutes between web updates to not overload FF server
int	   	DebugLevel      =  5;
int 	      logHandle       = -1;
static int	PrevMinute      = -1;
static int	RefreshMin      =  0;
static int	RefreshHour     =  0;
static bool NeedToGetFile   = false;
bool		   IsEA_Call		 = false;
bool	   	AllowWebUpdates = true;		// Set "false" if in multiple EA/Chart so indicators don't fight each other
bool	   	SaveXmlFiles	 = false;   // If true, this will keep the daily XML files
bool 	      EnableLogging   = false;   // Perhaps remove this from externs once its working well
double   	ExtMapBuffer0[];     	   // Contains (minutes until) each news event
double   	ExtMapBuffer1[];        	// Contains only most recent and next news event ([0] & [1])
double    	ExtMapBuffer2[];	         // Contains impact value for most recent and next news event
string 		xmlFileName;  		     
string      sUrl = "http://cloud.forexfactory.com/ffcal_week_this.xml";
string   	mainData[100][7], sData, csvoutput, Title;
string    	dispTitle[2], dispCountry[2], dispImpact[2], dispForecast[2], dispPrevious[2];
string   	sTags[7] = { "<title>", "<country>", "<date>", "<time>", "<impact>", "<forecast>", "<previous>" };
string 	   eTags[7] = { "</title>", "</country>", "</date>", "</time>", "</impact>", "</forecast>", "</previous>" };
string      sinceUntil, TimeStr,Sponsor, Minutes1, Minutes2, box1, box2, box3;       
color       TxtColorNews; //= White;
bool        FLAG_deinit;

//+-----------------------------------------------------------------------------------------------+
//| Indicator Initialization                                                                      |
//+-----------------------------------------------------------------------------------------------+
int init()
   {
   FLAG_deinit = false; 
      	
	SetIndexBuffer(0, ExtMapBuffer0);
   SetIndexBuffer(1, ExtMapBuffer1);
   SetIndexBuffer(2, ExtMapBuffer2);

	SetIndexStyle(0, DRAW_NONE);	
	SetIndexStyle(1, DRAW_NONE);
	SetIndexStyle(2, DRAW_NONE);
	
	IndicatorShortName("FFCal");
   //SetIndexLabel(0, "MinsBeforeNews");
   //SetIndexLabel(1, "MinsAfterNews"); 
	
	MathSrand(TimeLocal());
	RefreshMin  = (MathRand() % 60);
	RefreshHour = (MathRand() % 6);

	if (DebugLevel > 0)
	   {
	   Print("In Init()...\n");
		Print("RefreshMin  == ", RefreshMin);
		Print("RefreshHour == ", RefreshHour);
   	}
   		
	return(0);
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Indicator De-initialization                                                                   |
//+-----------------------------------------------------------------------------------------------+
int deinit()
   {   
   int obj_total= ObjectsTotal();  
   for (i= obj_total; i>=0; i--) {
      string name= ObjectName(i);
      if (StringSubstr(name,0,7)=="[FFCal]") {ObjectDelete(name);}} 
	   	  
	//Fixed one case of divide by zero where multiple charts 
	//indicator is on was trying to overwrite the same file	
	xmlFileName = GetXmlFileName();
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ|FILE_WRITE);
	//File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103)
	if (xmlHandle >= 0)
	   {
		//Since file exists, Close what we just opened
		FileClose(xmlHandle);		
		//Delete our news file and redownload a new one to prevent a remainder from zero divide error
		if (!SaveXmlFiles)	FileDelete(xmlFileName);
	   }	     
	return(0);
   }

string GetXmlFileName()
   {
	return (Month() + "-" + Day() + "-" + Year() + "-" + Symbol() + Period() + "-" + "FFCal.xml");
   }

//+-----------------------------------------------------------------------------------------------+
//| Indicator Start                                                                               |
//+-----------------------------------------------------------------------------------------------+  
int start()
   {
   //Deinitialize once when turned off, not on every tick while off----------------------------
   if(!Indicator_ON)
      {
      if (!FLAG_deinit) deinit(); FLAG_deinit = true; return(0);
      }
   FLAG_deinit = false;        
   //Clear variables to refresh labels.  Then exit if "Off".
   if (!Indicator_ON) {return(0);}
   
	int 		newsIdx = 0;
	int 		nextNewsIdx = -1;
	int 		next;
	string 	myEvent;
	bool 		skip;
	datetime newsTime;
      
	//Make sure we are connected.  Otherwise exit. Added by MN
	if (!IsConnected()) {Print("News Indicator is disabled because NO CONNECTION to Broker!"); return(0);}   
	//If we are not logging, then do not output debug statements either
	if (!EnableLogging)	DebugLevel = 0;	
	//Added this section to check if the XML file already exists.  
	//If it does NOT, then we need to set a flag to go get it
	xmlFileName = GetXmlFileName();
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ);
	//File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103)
   //Since file exists, close what we just opened	
	if (xmlHandle >= 0) {FileClose(xmlHandle); NeedToGetFile = false;}
	else NeedToGetFile = true;
	
	//---------------------------------------------------------------------------------------------
	//Set this to false when using in another EA or Chart, so that the multiple 
	//instances of the indicator don't fight with each other (added by MN).
	if (AllowWebUpdates)
	   {
		//New method: Use global variables so that when put on multiple charts, it 
		//will not update overly often; only first time and every 4 hours
		if (DebugLevel > 1)
			Print(GlobalVariableGet("LastUpdateTime") + " " + (TimeCurrent() - GlobalVariableGet("LastUpdateTime")));			
  		if (NeedToGetFile || GlobalVariableCheck("LastUpdateTime") == false || 
  			(TimeCurrent() - GlobalVariableGet("LastUpdateTime")) > WebUpdateFreq)
		   {
			if (DebugLevel > 1) Print("sUrl == ", sUrl);		
			if (DebugLevel > 0)Print("Grabbing Web, url = ", sUrl);	
			//THIS CALL WAS DONATED BY PAUL TO HELP FIX THE RESOURCE ERROR
			GrabWeb(sUrl, sData);
			if (DebugLevel > 0) {Print("Opening XML file...\n"); Print(sData);}
			//Delete existing file
			FileDelete(xmlFileName);			
			//Write the contents of the ForexFactory page to an .htm file
			//If it is still open from the above FileOpen call, close it.
			xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_WRITE);
			if (xmlHandle < 0)
		   	{
				if (DebugLevel > 0) Print("Can\'t open new xml file, the last error is ", GetLastError()); return(false);
			   }
			FileWriteString(xmlHandle, sData, StringLen(sData));
			FileClose(xmlHandle);
			if (DebugLevel > 0) Print("Wrote XML file...\n");
			//THIS BLOCK OF CODE DONATED BY WALLY TO FIX THE RESOURCE ERROR
			//--- Look for the end XML tag to ensure that a complete page was downloaded ---//
			end = StringFind(sData, "</weeklyevents>", 0);
			if (end <= 0) {Alert("FFCal Error - Web page download was not complete!"); return(false);}
			else {GlobalVariableSet("LastUpdateTime", TimeCurrent());} // set global to time of last update			
		   }
	   }//end of allow web updates--------------------------------------------------------------------

	//Perform remaining checks once per minute
	if (!IsEA_Call && Minute() == PrevMinute) return (true);
	PrevMinute = Minute();
   //Print("FFCal NEW MINUTE...Refreshing News from XML file...");

	//Open the log file (will not open if logging is turned off)
	OpenLog("FFCal");

	//Init the buffer array to zero just in case
	ArrayInitialize(ExtMapBuffer0, 0);
	ArrayInitialize(ExtMapBuffer1, 0);
	
	//Open the XML file
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ);
	if (xmlHandle < 0)
   	{
		Print("Can\'t open xml file: ", xmlFileName, ".  The last error is ", GetLastError());	return(false);
	   }
	if (DebugLevel > 0) Print("XML file open must be okay");
	
	//Read in the whole XML file
	//Avg. file length == ~7K, so 65536 should always read whole file
	sData = FileReadString(xmlHandle, 65536);	
   if (StringLen(sData) < FileSize(xmlHandle)) sData = sData + FileReadString(xmlHandle, FileSize(xmlHandle));	
	
	//Because MT4 build 202 complained about too many files open and MT4 hung. Added by MN
	if (xmlHandle > 0) FileClose(xmlHandle);

	//Get the currency pair, and split it into the two countries
	string pair = Symbol();
	string cntry1 = StringSubstr(pair, 0, 3);
	string cntry2 = StringSubstr(pair, 3, 3);
	if (DebugLevel > 0) Print("cntry1 = ", cntry1, "    cntry2 = ", cntry2);	
	if (DebugLevel > 0) Log("Weekly calendar for " + pair + "\n\n");

	//Parse the XML file looking for an event to report	
	tmpMins = 10080;	// (a week)
	BoEvent = 0;
	while (true)
   	{
		BoEvent = StringFind(sData, "<event>", BoEvent);
		if (BoEvent == -1) break;			
		BoEvent += 7;	
		next = StringFind(sData, "</event>", BoEvent);
		if (next == -1) break;	
		myEvent = StringSubstr(sData, BoEvent, next - BoEvent);
		BoEvent = next;		
		begin = 0;
		skip = false;
		for (i=0; i < 7; i++)
		   {
			mainData[newsIdx][i] = "";
			next = StringFind(myEvent, sTags[i], begin);			
			// Within this event, if tag not found, then it must be missing; skip it
			if (next == -1) continue;
			else
			   {
				// We must have found the sTag okay...
				begin = next + StringLen(sTags[i]);			// Advance past the start tag
				end = StringFind(myEvent, eTags[i], begin);	// Find start of end tag
				//Get data between start and end tag
				if (end > begin && end != -1) {mainData[newsIdx][i] = StringSubstr(myEvent, begin, end - begin);}
			   }
		   }//End "for" loop
		
		//Test against filters that define whether we want to skip this particular annoucement
		if (cntry1 != mainData[newsIdx][COUNTRY] && cntry2 != mainData[newsIdx][COUNTRY] &&
			(!Put_USD_News_On_All || mainData[newsIdx][COUNTRY] != "USD")) skip = true;
		if (mainData[newsIdx][TIME] == "All Day" || mainData[newsIdx][TIME] == "Tentative" ||
		  	 mainData[newsIdx][TIME] == "") skip = true;
		if (Exclude_Impact_Low && mainData[newsIdx][IMPACT] == "Low") skip = true;  	 
		//If not skipping this event, then log it into the draw buffers
		if (!skip)
		   {   
			//If we got this far then we need to calc the minutes until this event
			//First, convert the announcement time to seconds (in GMT)
			newsTime = StrToTime(MakeDateTime(mainData[newsIdx][DATE], mainData[newsIdx][TIME]));			
			// Now calculate the minutes until this announcement (may be negative)
			minsTillNews = (newsTime - TimeGMT()) / 60;
			if (DebugLevel > 0)
			   {
				Log("FOREX FACTORY\nTitle: " + mainData[newsIdx][TITLE] + "\n" + minsTillNews + "\n\n");
			   }					

			//Keep track of the most recent news announcement.  Do that by saving each one until we get to the 
			//first annoucement that isn't in the past; i.e. minsTillNews > 0.  Then, keep this one instead for
			//display, but only once the minutes until the next news is SMALLER than the minutes since the last.
         //Print("Mins till event: ", minsTillNews);
			if (minsTillNews < 0 || MathAbs(tmpMins) > minsTillNews)	{idxOfNext = newsIdx; tmpMins	= minsTillNews;}			
			Log("Weekly calendar for " + pair + "\n\n");
			if (DebugLevel > 0)
			   {
				Log("FOREX FACTORY\nTitle: " + mainData[newsIdx][TITLE] + 
				"\nCountry: " + mainData[newsIdx][COUNTRY] + 
				"\nDate: " + mainData[newsIdx][DATE] + 
				"\nTime: " + mainData[newsIdx][TIME] + 
				"\nImpact: " + mainData[newsIdx][IMPACT] + 
				"\nForecast: " + mainData[newsIdx][FORECAST] + 
				"\nPrevious: " + mainData[newsIdx][PREVIOUS] + "\n\n");
			   }
			   			
			//Do alert if user has enabled
			if (Alert_Minutes_Before != 0 && minsTillNews == Alert_Minutes_Before)
				Alert(Alert_Minutes_Before, " minutes until news for ", pair, ": ", mainData[newsIdx][TITLE]);
						
			//Buffers are set up as so: 
			//ExtMapBuffer0 contains the time UNTIL each announcement (can be negative)
			//e.g. [0] = -372; [1] = 25; [2] = 450; [3] = 1768 (etc.)
			//ExtMapBuffer1[0] has the mintutes since the last annoucement.
			//ExtMapBuffer1[1] has the mintutes until the next annoucement.
			ExtMapBuffer0[newsIdx] = minsTillNews;
			newsIdx++;
		   }//End "skip" routine
	   }//End "while" routine

	//Cycle through the events array and pick out the most recent past and the next coming event
	//to put into ExtMapBuffer1. Put the corresponding impact for these two into ExtMapBuffer2.
	bool first = true;
	ExtMapBuffer1[0] = 99999;
	ExtMapBuffer1[1] = 99999;
	ExtMapBuffer2[0] = 0;
	ExtMapBuffer2[1] = 0;
	string outNews = "Minutes until news events for " + pair + " : ";
	for (i=0; i < newsIdx; i++)	
	   {
		outNews = outNews + ExtMapBuffer0[i] + ", ";
		if (ExtMapBuffer0[i] >= 0 && first)
		   {
			first = false;			
			//Put the relevant info into the indicator buffers...
			//Minutes SINCE - - - - - - - - - - - - - - - - - - - - - - - - -
			//(does not apply if the first event of the week has not passed)
			if (i > 0)
			   {
				ExtMapBuffer1[0] = MathAbs(ExtMapBuffer0[i-1]);
				ExtMapBuffer2[0] = ImpactToNumber(mainData[i-1][IMPACT]);
			   }			
			//Minutes UNTIL - - - - - - - - - - - - - - - - - - - - - - - - -
			//Check if past the last event.  
			if (ExtMapBuffer0[i] > 0 || (ExtMapBuffer0[i] == 0 && ExtMapBuffer0[i+1] > 0))
			   {
				ExtMapBuffer1[1] = ExtMapBuffer0[i];
			   }
			ExtMapBuffer2[1] = ImpactToNumber(mainData[i][IMPACT]);
		   }		
		//Also use this loop to set which information to display
		if (i == idxOfNext)
		   {
			dispTitle[0]	   = mainData[i][TITLE];
			dispCountry[0] 	= mainData[i][COUNTRY];
			dispImpact[0]  	= mainData[i][IMPACT];
			dispForecast[0]   = mainData[i][FORECAST];
			dispPrevious[0]   = mainData[i][PREVIOUS];
			dispMinutes[0] 	= ExtMapBuffer0[i];
		   }		
		if (i == idxOfNext + 1)
	   	{
			dispTitle[1]   	= mainData[i][TITLE];
			dispCountry[1] 	= mainData[i][COUNTRY];
			dispImpact[1] 	   = mainData[i][IMPACT];
			dispForecast[1]   = mainData[i][FORECAST];
			dispPrevious[1]   = mainData[i][PREVIOUS];
			dispMinutes[1] 	= ExtMapBuffer0[i];
	      }		
	   }//End "for" loop
		
	//If we are past all news events, then neither one will have been 
	//set, so set the past event to the last (negative) minutes
	if (ExtMapBuffer1[0] == 0 && ExtMapBuffer1[1] == 0)
	   {
		ExtMapBuffer1[0] = ExtMapBuffer0[i-1];
		ExtMapBuffer1[1] = 999999;
	   }      	
	//For debugging...Print the tines until news events, as a "Comment"
	if (DebugLevel > 0)
	   {
		Print(outNews);
		Print("LastMins (ExtMapBuffer1[0]) = ", ExtMapBuffer1[0]);
		Print("NextMins (ExtMapBuffer1[1]) = ", ExtMapBuffer1[1]);
	   }
	if (!IsEA_Call) OutputToChart();
	if (logHandle > 0) {FileClose(logHandle); logHandle = -1;}		
	return (0);
   }

//+-----------------------------------------------------------------------------------------------+
//| Indicator Routine For Normal Display                                                          |
//+-----------------------------------------------------------------------------------------------+  
void OutputToChart()
   {
   //Set variables 
   TxtSize =  TxtSize_8_9_10;
	if (TxtSize <8 || TxtSize >10) {TxtSize = 9;}   
   TitleSpacer = 10;
   EventSpacer = 6; 
   curX = 7;
   curY = 9;           
   box1      = "[FFCal] Background1";
   box2      = "[FFCal] Background2"; 
   box3      = "[FFCal] Background3";            	
	W = WindowsTotal( );
	
 
	     
   //Do background---------------------------------------------------------------------------------  	             
   if(TxtSize ==  8) 
      {   
      Box= 45; x1= 0; y1= 0; x2=180+Widen_Background; y2= 0; x3= 180+ Widen_Background; y3= 0; 
      if(DisplayCorner==2 && Broker_Watermark && W ==1) {Box=53; x2=90+Widen_Background; x3= 187+ Widen_Background; y3= 0;  curY = curY+12;}         
      }
    
   if(TxtSize ==  9) 
      {   
      //Box= 51; x1= 0; y1= 0; x2=140+Widen_Background; y2= 0;
      Box= 47; x1= 0; y1= 0; x2=130+Widen_Background; y2= 0; x3= 252+ Widen_Background; y3= 0;    
      if(DisplayCorner==2 && Broker_Watermark && W ==1) {Box=55; x2=120+Widen_Background; x3= 220+ Widen_Background; y3= 0; curY = curY+11;}                  
      } 
           
   if(TxtSize == 10) 
      {      
      Box= 51; x1= 0; y1= 0; x2=140+Widen_Background; y2= 0; x3= 244+ Widen_Background; y3= 0;  
      if(DisplayCorner==2 && Broker_Watermark && W ==1) {Box=57; x2=130+Widen_Background; x3= 220+ Widen_Background; y3= 0; curY = curY+10;}                  
      }
        
      if (DisplayCorner == 1 || DisplayCorner == 3) {x1= 1;} 
      if (DisplayCorner == 2 || DisplayCorner == 3) {y1= 1; y2= 1; y3= 1;}                  
	                 
	   if (ObjectFind(box1) == -1){
         ObjectCreate(box1, OBJ_LABEL, DisplayWindow_0123, 0,0);
         ObjectSetText(box1, "ggg", Box, "Webdings");          
         ObjectSet(box1, OBJPROP_CORNER, DisplayCorner);
         ObjectSet(box1, OBJPROP_XDISTANCE, x1);        
         ObjectSet(box1, OBJPROP_YDISTANCE, y1);      
         ObjectSet(box1, OBJPROP_COLOR, Color_Background);
         ObjectSet(box1, OBJPROP_BACK, false);}
	   else {ObjectMove(box1, DisplayWindow_0123, x1, y1);}
	         
	   if (ObjectFind(box2) == -1){
         ObjectCreate(box2, OBJ_LABEL, DisplayWindow_0123, 0,0);
         ObjectSetText(box2, "ggg", Box, "Webdings");          
         ObjectSet(box2, OBJPROP_CORNER, DisplayCorner);
         ObjectSet(box2, OBJPROP_XDISTANCE, x2);       
         ObjectSet(box2, OBJPROP_YDISTANCE, y2);      
         ObjectSet(box2, OBJPROP_COLOR, Color_Background);
         ObjectSet(box2, OBJPROP_BACK, false);}
	   else {ObjectMove(box1, DisplayWindow_0123, x2, y2);}
	         
	   if (ObjectFind(box3) == -1){
         ObjectCreate(box3, OBJ_LABEL, DisplayWindow_0123, 0,0);
         ObjectSetText(box3, "ggg", Box, "Webdings");          
         ObjectSet(box3, OBJPROP_CORNER, DisplayCorner);
         ObjectSet(box3, OBJPROP_XDISTANCE, x3);       
         ObjectSet(box3, OBJPROP_YDISTANCE, y3);      
         ObjectSet(box3, OBJPROP_COLOR, Color_Background);
         ObjectSet(box3, OBJPROP_BACK, false);}
	   else {ObjectMove(box3, DisplayWindow_0123, x3, y3);}     
            
   //Do labels------------------------------------------------------------------------------------       
   Title     = "FOREX FACTORY CALENDAR  HEADLINES:";          
   Sponsor   = "[FFCal] Sponsor";  
   Minutes1  = "[FFCal] Minutes1";   
   Minutes2  = "[FFCal] Minutes2"; 
   int index;
        
   if (DisplayCorner < 2) //Code to display in upper corners
      {     
      //Start with title------------------------------------------------------      
	   if (ObjectFind(Sponsor) == -1){
	  	   ObjectCreate(Sponsor, OBJ_LABEL, DisplayWindow_0123, 0, 0);
 	      ObjectSetText(Sponsor, Title, TxtSize_8_9_10, TxtStyle, FFCal_Title);
	      ObjectSet(Sponsor, OBJPROP_CORNER, DisplayCorner);
	      ObjectSet(Sponsor, OBJPROP_XDISTANCE, curX);
	      ObjectSet(Sponsor, OBJPROP_YDISTANCE, curY);}
	   else {ObjectMove(Sponsor, DisplayWindow_0123, curX, curY);}		   
	      	        
	   //Then do first news event description line & Impact---------------------
	   //If time is 0 or negative, we want to say "xxx mins SINCE ... news event", else say "UNTIL ... news event"
	   sinceUntil = "until ";
  	   dispMins = dispMinutes[0];
	   if (dispMinutes[0] <= 0) {sinceUntil = "since "; dispMins *= -1;}	//"*= -1" = multiply by "-1"
	   if (dispMins < 60) {TimeStr = dispMins + " mins ";}
	   else // time is 60 minutes or more
	      {
		   Hours = MathRound(dispMins / 60);
		   Mins = dispMins % 60;
		   if (Hours < 24) // less than a day: show hours and minutes
	  	      {
			   TimeStr = Hours + " hrs " + Mins + " mins ";
		      }
		   else  // days, hours, and minutes
		      {
			   Days = MathRound(Hours / 24);
			   Hours = Hours % 24;
			   TimeStr = Days + " days " + Hours + " hrs " + Mins + " mins ";
		      }
	      }
	      
	   index = StringFind(TimeStr+sinceUntil+dispCountry[0], "since  mins", 0); 
	   if(index == -1)
	   {	      
	   curY = curY + TxtSize + TitleSpacer;	      
	 	TxtColorNews = ImpactToColor(dispImpact[0]);     	      
	   ObjectDelete(Minutes1);  	      	
	   if (ObjectFind(Minutes1) == -1){
		   ObjectCreate(Minutes1, OBJ_LABEL, DisplayWindow_0123, 0, 0);
		      //if(index != -1){
            if (sinceUntil == "since " && dispMins > WebUpdateFreq + 1) {TxtColorNews = News_Impact_None;			         
		         ObjectSetText(Minutes1, "Event 1: No H/M impact events currently scheduled", TxtSize_8_9_10, TxtStyle, TxtColorNews);}	
	         else {
		         ObjectSetText(Minutes1, TimeStr + sinceUntil + dispCountry[0] + ": " + dispTitle[0], TxtSize_8_9_10, TxtStyle, TxtColorNews);}
	      ObjectSet(Minutes1, OBJPROP_CORNER, DisplayCorner);
	      ObjectSet(Minutes1, OBJPROP_XDISTANCE, curX);
	      ObjectSet(Minutes1, OBJPROP_YDISTANCE, curY);}
	   else {ObjectMove(Minutes1, DisplayWindow_0123, curX, curY);}
      }
		
	   //Finish with second news event description line------------------------
		   sinceUntil = "until ";
		   dispMins = dispMinutes[1];
		   if (dispMinutes[1] <= 0) {sinceUntil = "since "; dispMins *= -1;}
		   if (dispMins < 60) {TimeStr = dispMins + " mins ";}
		   else // time is 60 minutes or more
		      {
			   Hours = MathRound(dispMins / 60);
		  	   Mins = dispMins % 60;
			   if (Hours < 24) // less than a day: show hours and minutes 
			      {
				   TimeStr = Hours + " hrs " + Mins + " mins ";
			      }
			   else // days, hours, and minutes
			      {
				   Days = MathRound(Hours / 24);
				   Hours = Hours % 24;
				   TimeStr = Days + " days " + Hours + " hrs " + Mins + " mins ";
			      }
		      }
		      
	      index = StringFind(TimeStr+sinceUntil+dispCountry[1], "since  mins", 0); 
	      if(index == -1)
	      {			      
		   curY = curY+ TxtSize + EventSpacer;  		   
		   TxtColorNews = ImpactToColor(dispImpact[1]);		   
		   ObjectDelete(Minutes2);     
		   if (ObjectFind(Minutes2) == -1){
			   ObjectCreate(Minutes2, OBJ_LABEL, DisplayWindow_0123, 0, 0);
		      if(index != -1){   
		         ObjectSetText(Minutes2, "Event 2: No events currently scheduled", TxtSize_8_9_10, TxtStyle, TxtColorNews);}	
		      else {
			      ObjectSetText(Minutes2, TimeStr + "until " + dispCountry[1] + ": " + dispTitle[1], TxtSize_8_9_10, TxtStyle, TxtColorNews);}
		      ObjectSet(Minutes2, OBJPROP_CORNER, DisplayCorner);
		      ObjectSet(Minutes2, OBJPROP_XDISTANCE, curX);
		      ObjectSet(Minutes2, OBJPROP_YDISTANCE, curY);}
	      else {ObjectMove(Minutes2, DisplayWindow_0123, curX, curY);}	 		   		   
         }
         
      }//End display code for upper corners


   //---------------------------------------------------------------------------------------------
   else if (DisplayCorner > 1) //Code to display in lower corners
      {       
	      //Do second event description line----------------------------------- 	           
      	sinceUntil = "until ";
   		dispMins = dispMinutes[1];
	   	if (dispMinutes[1] <= 0) {sinceUntil = "since "; dispMins *= -1;} //"*= -1" = multiply by "-1"  	
   		if (dispMins < 60) {TimeStr = dispMins + " mins ";}
	   	else // time is 60 minutes or more
	      	{
		   	Hours = MathRound(dispMins / 60);
	   		Mins = dispMins % 60;
	   		if (Hours < 24) // less than a day: show hours and minutes 
		      	{
			   	TimeStr = Hours + " hrs " + Mins + " mins ";
		       	}
		   	else // days, hours, and minutes
		      	{
		   		Days = MathRound(Hours / 24);
			   	Hours = Hours % 24;
			   	TimeStr = Days + " days " + Hours + " hrs " + Mins + " mins ";
		      	}
	      	}
               	
	      index = StringFind(TimeStr+sinceUntil+dispCountry[1], "since  mins", 0); 		      	
	      TxtColorNews = ImpactToColor(dispImpact[1]); 		      	
	      ObjectDelete(Minutes2);
		   if (ObjectFind(Minutes2) == -1){	       	
		   	ObjectCreate(Minutes2, OBJ_LABEL, DisplayWindow_0123, 0, 0);
		         if(index != -1){   
		            ObjectSetText(Minutes2, "Event 2: Additional events not currently scheduled", TxtSize_8_9_10, TxtStyle, TxtColorNews);}		   	   
	         	else {
		   	      ObjectSetText(Minutes2, TimeStr + "until " + dispCountry[1] + ": " + dispTitle[1], TxtSize_8_9_10, TxtStyle, TxtColorNews);}		  
		      ObjectSet(Minutes2, OBJPROP_CORNER, DisplayCorner);
	   	   ObjectSet(Minutes2, OBJPROP_XDISTANCE, curX);
	   	   ObjectSet(Minutes2, OBJPROP_YDISTANCE, curY);} 
	      else {ObjectMove(Minutes2, DisplayWindow_0123, curX, curY);}		   	   	
         curY = curY + TxtSize + EventSpacer;     
         
	      //Do first event description line------------------------------------  
	      //If time is 0 or negative, we want to say "xxx mins SINCE ... news event", else say "UNTIL ... news event"
	      sinceUntil = "until ";
	      dispMins = dispMinutes[0];
	      if (dispMinutes[0] <= 0) {sinceUntil = "since "; dispMins *= -1;}	      
	      if (dispMins < 60) {TimeStr = dispMins + " mins ";}
	      else // time is 60 minutes or more
	         {
		      Hours = MathRound(dispMins / 60);
		      Mins = dispMins % 60;
		      if (Hours < 24) // less than a day: show hours and minutes
		         {
		   	   TimeStr = Hours + " hrs " + Mins + " mins ";
		         }
		      else  // days, hours, and minutes
		         {
		   	   Days = MathRound(Hours / 24);
			      Hours = Hours % 24;
			      TimeStr = Days + " days " + Hours + " hrs " + Mins + " mins ";
		         }
	         }
	  		         
	      index = StringFind(TimeStr+sinceUntil+dispCountry[0], "since  mins", 0); //Comment (index);		         
	      TxtColorNews = ImpactToColor(dispImpact[0]);  	       	   
	      ObjectDelete(Minutes1);
		   if (ObjectFind(Minutes1) == -1){		         	    
		      ObjectCreate(Minutes1, OBJ_LABEL, DisplayWindow_0123, 0, 0);
		      //if(index != -1) {
            if (sinceUntil == "since " && dispMins > WebUpdateFreq + 1) {TxtColorNews = News_Impact_None;		      		         
		         ObjectSetText(Minutes1, "Event 1: Additional events not currently scheduled", TxtSize_8_9_10, TxtStyle, TxtColorNews);}	
		      else
		         {
	   	      ObjectSetText(Minutes1, TimeStr + sinceUntil + dispCountry[0] + ": " + dispTitle[0], TxtSize_8_9_10, TxtStyle, TxtColorNews);
	   	      }
	         ObjectSet(Minutes1, OBJPROP_CORNER, DisplayCorner);
	         ObjectSet(Minutes1, OBJPROP_XDISTANCE, curX);
	         ObjectSet(Minutes1, OBJPROP_YDISTANCE, curY);}
	      else {ObjectMove(Minutes1, DisplayWindow_0123, curX, curY);}	         	
   	  	   curY = curY + TxtSize + TitleSpacer;    
   	       
         //Finish with title--------------------------------------------------	     	         	
	      if (ObjectFind(Sponsor) == -1){
	  	      ObjectCreate(Sponsor, OBJ_LABEL, DisplayWindow_0123, 0, 0);
 	         ObjectSetText(Sponsor, Title, TxtSize_8_9_10, TxtStyle, FFCal_Title);
	         ObjectSet(Sponsor, OBJPROP_CORNER, DisplayCorner);
	         ObjectSet(Sponsor, OBJPROP_XDISTANCE, curX);
	         ObjectSet(Sponsor, OBJPROP_YDISTANCE, curY);}
	      else {ObjectMove(Sponsor, DisplayWindow_0123, curX, curY);}	               
      }//End display code for lower corners

	return (0);
   }

//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Impact Color                                                         |
//+-----------------------------------------------------------------------------------------------+  
double ImpactToColor (string impact)
   {
	if (impact == "High") return (News_Impact_High);
	else {if (impact == "Medium") return (News_Impact_Medium);
	else {if (impact == "Low") return (News_Impact_Low); 
	else {return (News_Impact_None);} }}  
	//else return (0);
   }
  
//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Impact Number                                                        |
//+-----------------------------------------------------------------------------------------------+  
double ImpactToNumber(string impact)
   {
	if (impact == "High") return (3);
	if (impact == "Medium") return (2);
	if (impact == "Low") return (1);
	else return (0);
   }
   
//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Date/Time                                                            |
//+-----------------------------------------------------------------------------------------------+ 
string MakeDateTime(string strDate, string strTime)
   {
	//Print("Converting Forex Factory Time into Metatrader time..."); //added by MN
	//Converts forexfactory time & date into yyyy.mm.dd hh:mm
	int n1stDash = StringFind(strDate, "-");
	int n2ndDash = StringFind(strDate, "-", n1stDash+1);

	string strMonth = StringSubstr(strDate, 0, 2);
	string strDay = StringSubstr(strDate, 3, 2);
	string strYear = StringSubstr(strDate, 6, 4); 
   //strYear = "20" + strYear;
	
	int nTimeColonPos = StringFind(strTime, ":");
	string strHour = StringSubstr(strTime, 0, nTimeColonPos);
	string strMinute = StringSubstr(strTime, nTimeColonPos+1, 2);
	string strAM_PM = StringSubstr(strTime, StringLen(strTime)-2);

	int nHour24 = StrToInteger(strHour);
	if (strAM_PM == "pm" || strAM_PM == "PM" && nHour24 != 12) {nHour24 += 12;}
	if (strAM_PM == "am" || strAM_PM == "AM" && nHour24 == 12) {nHour24 = 0;}
 	string strHourPad = "";
	if (nHour24 < 10) strHourPad = "0";

	return(StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
   }

//=================================================================================================
//====================================   GrabWeb Functions   ======================================
//=================================================================================================
// Main Webscraping function
// ~~~~~~~~~~~~~~~~~~~~~~~~~
// bool GrabWeb(string strUrl, string& strWebPage)
// returns the text of any webpage. Returns false on timeout or other error
// 
// Parsing functions
// ~~~~~~~~~~~~~~~~~
// string GetData(string strWebPage, int nStart, string strLeftTag, string strRightTag, int& nPos)
// obtains the text between two tags found after nStart, and sets nPos to the end of the second tag
//
// void Goto(string strWebPage, int nStart, string strTag, int& nPos)
// Sets nPos to the end of the first tag found after nStart 

bool bWinInetDebug = false;
int  hSession_IEType;
int  hSession_Direct;
int  Internet_Open_Type_Preconfig = 0;
int  Internet_Open_Type_Direct = 1;
int  Internet_Open_Type_Proxy = 3;
int  Buffer_LEN = 80;

#import "wininet.dll"
//Forces the request to be resolved by the origin server, even if a cached copy exists on the proxy.
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100 

//Does not add the returned entity to the cache. 
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000 
 
//Forces a download of the requested file, object, or directory listing from the origin server, not from the cache.
#define INTERNET_FLAG_RELOAD            0x80000000 

int InternetOpenA(
	string 	sAgent,
	int		lAccessType,
	string 	sProxyName="",
	string 	sProxyBypass="",
	int 	lFlags=0);

int InternetOpenUrlA(
	int 	hInternetSession,
	string 	sUrl, 
	string 	sHeaders="",
	int 	lHeadersLength=0,
	int 	lFlags=0,
	int 	lContext=0);

int InternetReadFile(
	int 	hFile,
	string 	sBuffer,
	int 	lNumBytesToRead,
	int& 	lNumberOfBytesRead[]);

int InternetCloseHandle(
	int 	hInet);
	
#import

//-----------------------------------------------------------------------------------------------
int hSession(bool Direct)
   {
	string InternetAgent;
	if (hSession_IEType == 0)
	   {
		InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
		hSession_IEType = InternetOpenA(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
		hSession_Direct = InternetOpenA(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
	   }
	if (Direct) {return(hSession_Direct);}
	else {return(hSession_IEType);}
   }

//------------------------------------------------------------------------------------------------
bool GrabWeb(string strUrl, string& strWebPage)
   {
	int   	hInternet;
	int		iResult;
	int   	lReturn[]	= {1};
	string 	sBuffer		= "                                                                                                                                                                                                                                                               ";	// 255 spaces
	int   	bytes;
	
	hInternet = InternetOpenUrlA(hSession(FALSE), strUrl, "0", 0, 
								INTERNET_FLAG_NO_CACHE_WRITE | 
								INTERNET_FLAG_PRAGMA_NOCACHE | 
								INTERNET_FLAG_RELOAD, 0);
								
	if (bWinInetDebug) Log("hInternet: " + hInternet);   
	if (hInternet == 0) return(false);

	Print("Reading URL: " + strUrl);	   //added by MN	
	iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
	
	if (bWinInetDebug) Log("iResult: " + iResult);
	if (bWinInetDebug) Log("lReturn: " + lReturn[0]);
	if (bWinInetDebug) Log("iResult: " + iResult);
	if (bWinInetDebug) Log("sBuffer: " +  sBuffer);
	if (iResult == 0)  return(false);
	bytes = lReturn[0];
	strWebPage = StringSubstr(sBuffer, 0, lReturn[0]);
	
	//If there's more data then keep reading it into the buffer
	while (lReturn[0] != 0)
	   {
		iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
		if (lReturn[0]==0) break;
		bytes = bytes + lReturn[0];
		strWebPage = strWebPage + StringSubstr(sBuffer, 0, lReturn[0]);
   	}
	Print("Closing URL web connection");   //added by MN
	iResult = InternetCloseHandle(hInternet);
	if (iResult == 0) return(false);		
	return(true);
   }

//===================================   LogUtils Functions   ======================================
void OpenLog(string strName)
   {
	if (!EnableLogging) return;
	if (logHandle <= 0)
   	{
		string strMonthPad = "";
 	 	string strDayPad = "";
  		if (Month() < 10) strMonthPad = "0";
  		if (Day() < 10) strDayPad = "0"; 			
  		string strFilename = StringConcatenate(strName, "_", Year(), strMonthPad, Month(), strDayPad, Day(), "_log.txt");  		
		logHandle = FileOpen(strFilename,FILE_CSV|FILE_READ|FILE_WRITE);
		Print("logHandle =================================== ", logHandle);
   	}
	if (logHandle > 0) {FileFlush(logHandle); FileSeek(logHandle, 0, SEEK_END);}
   }

//------------------------------------------------------------------------------------------------
void Log(string msg)
   {
	if (!EnableLogging) return;		
	if (logHandle <= 0) return;		
	msg = TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS) + " " + msg;
	FileWrite(logHandle,msg);
   }

//===================================   Timezone Functions   ======================================
#import "kernel32.dll"
int  GetTimeZoneInformation(int& TZInfoArray[]);
#import
#define TIME_ZONE_ID_UNKNOWN   0
#define TIME_ZONE_ID_STANDARD  1
#define TIME_ZONE_ID_DAYLIGHT  2
int TZInfoArray[43];	
datetime TimeGMT() 
   {
	int DST = GetTimeZoneInformation(TZInfoArray);
	if (DST == 1) DST = 3600;
	else DST = 0;
	return( TimeLocal() + DST + (Offset_Hours * 3600) + (TZInfoArray[0] + TZInfoArray[42]) * 60 );
   }

//=================================================================================================
//=================================   END IMPORTED FUNCTIONS  =====================================
//=================================================================================================

//+-----------------------------------------------------------------------------------------------+
//| Indicator End                                                                                 |                                                        
//+-----------------------------------------------------------------------------------------------+