//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                         Market Panel Display Controller.mq4                               | 
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+ 

#property copyright "Traderathome, Copyright @ 2010"
#property link      "email: traderathome@msn.com" 

/*=============================================================================================
Overview:

This indicator places a colored panel in the upper left corner of the chart.  Within the panel 
are five labels: (1) the pair symbol and time frame, (2) the spread, (3) the range (average
and current for the session), (4) the time to the next candle, and (5) the market bid price.  
Color selection is available for the panel and labels.  The market price uses three colors for: 
when price is increased, decreased, or unchanged (static).  In Chart Properties, the Common tab 
item "Show OHLC" must be unchecked for proper display of this panel. The indicator optionally 
charts range high/low lines and vertical lines at the time key markets open.

The indicator can be used for both forex and non-forex items. In the Forex mode, you can show
either 4 digit or 5 digits.  If your platform is 4 digit and you select the 5 digit display, 
a "0" is added to displayed numbers. If it is a 5 digit platform and you select to display 4 
digits, numbers are rounded off to 4 digits.   

Range averaging eliminates brief Sunday sessions from the process.  For each Sunday eliminated
during the averaging, another full session day is added.  So, no matter the averaging period, 
there are no short Sunday sessions to drag the average down, and no days missing from the 
averaging process.

The optional range H/L lines are displayed in two different ways, according to two different
conditions.  Condition #1 is that the session range has not exceeded the computed average
range.  The RgH line is the computed average range distance above the session Low, and the
RgL line is the computed average range distance below the session high.  The lines will move
as new highs/lows are achieved during the session.  This display shows how far price can move 
in either direction before exceeding the computed average range.  Condition #2 occurs if PA 
exceeds the average computed range.  Then, if price is in the upper half of the new increased 
range the RgL line is at the session low and the RgH line is at the computed average range 
distance above the RgL line.  And if price is in the lower half of the new increased range the 
RgH line is at the session high and the RgL line is at the computed average range distance 
below RgH line.  This display shows the relationship between the computed average range and
the session PA, which has moved beyond.

There are choices for the way range H/L lines are shown. The "StartLines_Number" determines 
these.  "2" starts lines at the beginning of the current session with the option to stop lines 
at the current candle.  Range line labels appear just to the right of the start of the current 
session and you can use "RangeLabels_MaxRight" to right shift them.   "3" starts lines at the
current candle.  Range line labels appear just to the right of the current candle. You can use
"RangeLabels_MaxRight" here also. 

This indicator creates vertical lines marking the session opens for Sydney, Tokyo, Moscow, 
Frankfurt, London and New York.  These lines can be displayed for the current session and you 
can select to display the lines for a choice of prior sessions also.  They can be relabeled and 
timed for a different market open location (Hong Kong, Dubai, Helsinki, etc.). The indicator 
also creates session divider lines. 

The location of each market open vline is determined by the number of hours you input.  These 
hours are the number of hours they occur after the start of the session at "0" hours per your
server.  For example, if the London open starts 10 hours into the session, then you would enter
"10" for the London_Open_Time.  However, by default the hours are set for a GMT based server
during DST.  A quick way to correct these times if your server is not at GMT is to enter the 
hours that your server is ahead of GMT (+), or after GMT (-) into the special External Input 
"MktOpen_vLines_Server_GMToffset".  During the non-DST time of year you will have to reset
the MktOpen settings (per suggestions below) as well as possibly your server GMT shift.

An easy way to find the number of hours to input for any location is to use the P4L Clock
indicator.  Set the indicator to display in 24 hour format, showing "broker" and the locations
you want vlines for.  When each vline location has a market open (8am, 7am for Sydney) the 
clock will let you know.  At the same time you can see your "broker" time.  Whatever "broker"
time is displayed, that is the number of hours you input.  If the "broker" time reads 15:00 
hours at the time the NY market opens and reads 08:00 hours, then you input "15" for the vline
for the NY market open.

Another way to find the number of hours to input for any location is to first determine the 
time zone difference between where your server is, and the market open city you want a vline
for.  The http://www.timeanddate.com/worldclock/ site will give you the time differences.  If
the time for your vline location is later than for your server location, then you subtract
the hours difference from "8" (from "7" for Sydney) to get the required hours to input.  If
the time for your vline location is earlier than for your server location, then add the hours
difference to "8" (to "7" for Sydney) to get the required hours to input.

Some servers/brokers have a very brief Sunday session.  This causes some or all of the vlines
for that session to "stack" up.  When the next session starts, the new current session vlines 
will display properly, but the vlines for that brief previous session will still be "stacked".   
There is no known easy coding solution available. 
                                                                    - Traderathome, 05-17-2010
                                                                    
Since release on 05-17-2010, made correction to vLines coding of session dividers.

                                                                    - Traderathome, 05-18-2010                                                                    
-----------------------------------------------------------------------------------------------
Acknowlegements:

Domas4 - "THANKS!" are owed to Domas4 for providing price labeling code compatible with non-
         forex items, and exit code enabling the indicator to not display above an input TF.                                                                                                                                                               
=============================================================================================*/


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |                                                        
//+-------------------------------------------------------------------------------------------+ 
#property indicator_chart_window

/*---------------------------------------------------------------------------------------------
Suggested Settings:             White Chart         Black Chart   
                    
Market_Panel_Color              C'226,226,250'    C'15,15,15'
Symbol_And_TF_Color             Black             Gray
Spread_Color                    Black             DarkOrange
Time_To_New_Bar_Color           Black             DarkOrange
PriceLabel_Up                   ForestGreen       LimeGreen
PriceLabel_Down                 Crimson           Red 
PriceLabel_Static               Blue              DodgerBlue
RangeHigh_Color                 Tomato            FireBrick
RangeLow_Color                  LimeGreen         Green
RangeLabels_Color               C'70,52,173'      DarkGray
vLines_Color                    C'83,83,0'        C'83,83,0'
vLinesLabels_Color              BlueViolet        Orange

MktOpen vLines/Times for GMT based server:        DST        Non-DST

Sydney                                            -3           -2
Tokyo                                             -1            0
1am EST                                            5            6
Moscow                                             4            5
Frankfurt                                          6            7
London                                             7            8
New York                                          12           13
11am EST                                          15           16
---------------------------------------------------------------------------------------------*/

//Global External Inputs----------------------------------------------------------------------- 
extern string Part_1                          = "Indicator Display Controls:";
extern bool   Indicator_On                    = true;
extern string Indicator_Max_Display_TF        = "M";
extern bool   Range_H\L_Lines_Show            = true;  
extern string Range_H\L_Lines_Max_Display_TF  = "H1";
extern bool   vLines_Show                     = true;
extern int    vLines_Server_GMToffset         = 3;
extern string vLines_Max_Display_TF           = "H1";
extern int    Prior_Sessions_To_Show          = 6;
extern string TF_Choices                      = "M1, M5, M15, M30, H1, H4, D, W, M";

extern string __                              = "";
extern string Part_2                          = "Market Panel Settings:";
extern bool   Use_For_Forex                   = true;
extern bool   Display_5_Digits_Forex          = false;
extern int    Digits_To_Show_In_Spread        = 0;
extern int    Days_For_Range_Average          = 14;  
extern color  Market_Panel_Color              = C'226,226,250';
extern color  Symbol_And_TF_Color             = Black; 
extern color  Spread_Color                    = Black;
extern color  Range_Color                     = Black;
extern color  Time_Color                      = Black;
extern color  PriceLabel_UP_Color             = ForestGreen;
extern color  PriceLabel_DOWN_Color           = Crimson;
extern color  PriceLabel_SAME_Color           = Blue;

extern string ___                             = "";
extern string Part_3                          = "Range Lines Start/Stop Settings:";
extern string note2                           = "Start lines at Day Separator, enter '2'";
extern string note3                           = "Start lines at current candle, enter '3'";
extern int    StartLines_Number               = 2;
extern bool   StopLines_At_Current_Candle     = false;

extern string ____                            = "";
extern string Part_4                          = "Range Lines Configuration:";
extern color  RangeHigh_Color                 = Tomato;
extern color  RangeLow_Color                  = C'0,191,48';
extern int    RG_LineStyle_01234              = 0;    
extern int    RG_SolidLineThickness           = 2;

extern string _____                           = "";
extern string Part_5                          = "Range Lines Label Settings:";
extern color  RangeLabels_Color               = MidnightBlue;
 extern bool  RangeLabels_Shown               = true;
extern string RangeLabels_FontStyle           = "Verdana"; 
extern int    RangeLabels_FontSize            = 8; 
extern bool   RangeLabels_Prices              = false;
extern bool   RangeLabels_MaxRight            = false;
extern bool   RangeLabels\Lines_Subordinate   = true; 

extern string ______                          = "";
extern string Part_6                          = "vLines Configuration:";
extern color  vLines_Color                    = C'83,83,0';
extern int    vLines_LineStyle_01234          = 2;    
extern int    vLines_SolidLineThickness       = 1;

extern string _______                         = "";
extern string Part_7                          = "vLines Selection and Time Settings:";
extern bool   Session_Lines_Shown             = false;
extern string Session_Lines_Label             = "day";  
extern bool   Sydney_Open_Shown               = true;
extern string Sydney_Open_Label               = " <   ";
extern int    Sydney_Open_Time                = 5;  
extern bool   Tokyo_Open_Shown                = true;
extern string Tokyo_Open_Label                = "    >";
extern int    Tokyo_Open_Time                 = 15;
extern bool   Moscow_Open_Shown               = false;
extern string Moscow_Open_Label               = "    M";
extern int    Moscow_Open_Time                = 4; 
extern bool   FrankFurt_Open_Shown            = false;
extern string Frankfurt_Open_Label            = "    F";
extern int    Frankfurt_Open_Time             = 6; 
extern bool   London_Open_Shown               = true;
extern string London_Open_Label               = "    L";
extern int    London_Open_Time                = 7; 
extern bool   NewYork_Open_Shown              = true;
extern string NewYork_Open_Label              = "    N";
extern int    NewYork_Open_Time               = 12; 

extern string ________                        = "";
extern string Part_8                          = "vLines Label Settings:";
extern color  vLineLabels_Color               = BlueViolet;
extern string vLineLabels_FontStyle           = "Verdana Bold";
extern int    vLineLabels_FontSize            = 8;
extern bool   vLineLabels_Chart_Top           = true;
extern int    vLineLabels_Dist_To_Border      = 1;

//Buffers, Constants and Variables------------------------------------------------------------
int      obj_total,E,fxDigits,modifier,Color,Factor,a,b,c,k,h,i,m,s,t,Z,F,G, bps,TodayBar,RgC;
double   Old_Price, Spread, ARg, Range, RangeAvg, RangeHigh, RangeLow, RH, RL;
double   top, bottom, scale,YadjustTop,YadjustBot,level;
double   HiToday,LoToday,startToday,endToday,TodayRange;
datetime startline, stopline, startlabel, startpivottoday, shift; 
string   item1 = "[Market Panel] Box1";  
string   item2 = "[Market Panel] Box2"; 
string   item3 = "[Market Panel] Data1";
string   item4 = "[Market Panel] Data2"; 
string   item5 = "[Market Panel] Data3";     
string   item6 = "[Market Panel] Data4"; 
string   item7 = "[Market Panel] Data5"; 
string   sub,name,Price,C,rangeline,rangelabel,spc,tab,tab2,vline,vlabel,dt;
bool     FLAG_deinit;

//+-------------------------------------------------------------------------------------------+
//| Indicator Initialization                                                                  |                                                        
//+-------------------------------------------------------------------------------------------+      
int init()
   {
   RgC=0;
   FLAG_deinit = false;     
   if (Use_For_Forex)
      {
      sub=StringSubstr(Symbol(), 3, 3);
      if (Display_5_Digits_Forex) {if (sub == "JPY") {fxDigits = 3;} else {fxDigits = 5;}}
      else {if (sub == "JPY") {fxDigits = 2;} else {fxDigits = 4;}}
      } 
   if (Digits == 5 || Digits == 3) Factor = 10; else Factor = 1; //cater for 5 digits       
   return(0);
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator De-initialization                                                               |                                                        
//+-------------------------------------------------------------------------------------------+       
int deinit()
   {   
   obj_total= ObjectsTotal();  
   for (k= obj_total; k>=0; k--){
      name= ObjectName(k); 
      if (StringSubstr(name,0,14)=="[Market Panel]"){ObjectDelete(name);}}
   Comment("");     
   return(0);
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator Start                                                                           |                                                        
//+-------------------------------------------------------------------------------------------+         
int start()
   {
   //If Indicator is "Off" deinitialize only once, not every tick-------------------------------  
   if(!Indicator_On) 
      {
      if (!FLAG_deinit) {deinit(); FLAG_deinit = true;}
      return(0);
      }
   //If indicator is "ON", deinitialize and run------------------------------------------------   
   deinit(); FLAG_deinit = false;        
        
   //Exit if period is greater than -----------------------------------------------------------
         if(Indicator_Max_Display_TF== "M1") {E= 1;}
   else {if(Indicator_Max_Display_TF== "M5") {E= 5;}
   else {if(Indicator_Max_Display_TF== "M15"){E= 15;}
   else {if(Indicator_Max_Display_TF== "M30"){E= 30;}
   else {if(Indicator_Max_Display_TF== "H1") {E= 60;}
   else {if(Indicator_Max_Display_TF== "H4") {E= 240;}
   else {if(Indicator_Max_Display_TF== "D")  {E= 1440;}
   else {if(Indicator_Max_Display_TF== "W")  {E= 10080;}
   else {if(Indicator_Max_Display_TF== "M")  {E= 43200;}}}}}}}}} 
   if(Period() > E) {deinit(); return(-1);} 
 
   //Create Background Boxes      
   ObjectCreate(item1, OBJ_LABEL, 0, 0, 0, 0, 0);
   ObjectSetText(item1, "g", 69, "Webdings");
   ObjectSet(item1, OBJPROP_CORNER, 0);
   ObjectSet(item1, OBJPROP_XDISTANCE, 0);
   ObjectSet(item1, OBJPROP_YDISTANCE, 0);   
   ObjectSet(item1, OBJPROP_COLOR, Market_Panel_Color);
   ObjectSet(item1, OBJPROP_BACK, false);     
            
   ObjectCreate(item2, OBJ_LABEL, 0, 0, 0, 0, 0);
   ObjectSetText(item2, "g", 69, "Webdings");
   ObjectSet(item2, OBJPROP_CORNER, 0);
   ObjectSet(item2, OBJPROP_XDISTANCE, 58);//52
   ObjectSet(item2, OBJPROP_YDISTANCE, 0);   
   ObjectSet(item2, OBJPROP_COLOR, Market_Panel_Color);
   ObjectSet(item2, OBJPROP_BACK, false);
         
   //Symbol and Time Frame   
   C= " "; if(Symbol()!="GBPUSD" || Symbol() !="EURUSD") {C= C+" ";}	         
            if (Period()== 1)  C =C +  "     "+Symbol()+"   M1";
      else {if (Period()== 5)  C =C +  "     "+Symbol()+"   M5";
      else {if (Period()== 15) C =C +  "    "+Symbol()+"   M15";
      else {if (Period()== 30)  C =C +  "    "+Symbol()+"   M30";
      else {if (Period()== 60)  C =C +  "     "+Symbol()+"   H1";
      else {if (Period()== 240)  C =C +  "     "+Symbol()+"   H4";
      else {if (Period()== 1440)  C =C +  "   "+Symbol()+"   Daily";
      else {if (Period()== 10080) C =C +  " "+Symbol()+"   Weekly";
      else {if (Period()== 43200) C =C +  ""+Symbol()+"   Monthly"; }}}}}}}}                          
   ObjectCreate(item3, OBJ_LABEL, 0, 0, 0);
   ObjectSet(item3,OBJPROP_CORNER, 0);
   ObjectSet(item3,OBJPROP_XDISTANCE, 0);
   ObjectSet(item3,OBJPROP_YDISTANCE, 3);
   ObjectSet(item3, OBJPROP_COLOR, Symbol_And_TF_Color);         
   ObjectSetText(item3, C, 11, "Arial Bold");
                         
   //Spread
   Spread = MarketInfo(Symbol(), MODE_SPREAD);
   Spread = Spread/Factor;                                        
   ObjectCreate(item4, OBJ_LABEL, 0, 0, 0);
   ObjectSet(item4,OBJPROP_CORNER, 0);
   ObjectSet(item4,OBJPROP_XDISTANCE, 34);
   ObjectSet(item4,OBJPROP_YDISTANCE, 20);
   ObjectSet(item4, OBJPROP_COLOR, Spread_Color);         
   ObjectSetText(item4, "Spread   " + DoubleToStr(Spread,Digits_To_Show_In_Spread), 9, "Arial");

   //Average Range is total period for range, Sundays replaced with additional non-Sunday days.   
   Ranges(Days_For_Range_Average);
   Range = (ARg/(Days_For_Range_Average)/Point)/Factor; 
                         
   //Define today's bar and it's data                    
   TodayBar   = iBarShift(NULL,PERIOD_D1,Time[0]);
   HiToday    = iHigh (NULL,PERIOD_D1,TodayBar);
   LoToday    = iLow  (NULL,PERIOD_D1,TodayBar); 
   TodayRange = ((HiToday - LoToday)/Point)/Factor;                          
          
   ObjectCreate(item7, OBJ_LABEL, 0, 0, 0);
   ObjectSet(item7,OBJPROP_CORNER, 0);
   ObjectSet(item7,OBJPROP_XDISTANCE, 34);
   ObjectSet(item7,OBJPROP_YDISTANCE, 34);
   ObjectSet(item7, OBJPROP_COLOR, Range_Color);              
   ObjectSetText(item7, "Range    " +DoubleToStr(Range,0)+", "+DoubleToStr(TodayRange,0), 9, "Arial");                     
                                       
   //Time To New Candle	   
   t=Time[0]+(Period()*60)-CurTime();
   s=t%60; string seconds = (s); if (s<10) {seconds = ("0"+seconds);} 
   m=(t-t%60)/60; 
   h=0;  
   for(i=0; i<24; i++){
      if(m>=60){m=m-60;h=h+1;}
      string minutes = (m); if (m<10) {minutes = ("0"+minutes);}   
      string hours = (h); if (h<10) {hours = ("0"+hours);} 
      string timeleft = (minutes+":"+seconds);    
      if (h>=1) timeleft= hours+":"+minutes+":"+seconds;                        
      if (Period()>1440){timeleft = " (OFF)";}}             
   ObjectCreate(item5, OBJ_LABEL, 0, 0, 0);
   ObjectSet(item5,OBJPROP_CORNER, 0);
   ObjectSet(item5,OBJPROP_XDISTANCE, 34);
   ObjectSet(item5,OBJPROP_YDISTANCE, 48);           
   ObjectSet(item5, OBJPROP_COLOR, Time_Color);        
   ObjectSetText(item5, "Candle   "+timeleft, 9, "Arial");         
   
   //Market Price            	
   Color = PriceLabel_SAME_Color; 
   if (Bid > Old_Price) {Color = PriceLabel_UP_Color;}
   if (Bid < Old_Price) {Color = PriceLabel_DOWN_Color;}
   Old_Price=Bid;    
   //----Add leading spaces to center price labels
   tab="  "; tab2=" "; if (Display_5_Digits_Forex) {tab=" "; tab2="";}                  
	      if(Symbol()== "USDMXN"){tab= tab2+"";}	   
   else {if(Symbol()== "XAUUSD"){tab= tab2+"";} 	      	 
   else {if(Symbol()== "USDJPY"){tab= tab2+"  ";}
	else {if(Symbol()== "CHFJPY"){tab= tab2+"  ";}
	else {if(Symbol()== "AUDJPY"){tab= tab2+"  ";}
	else {if(Symbol()== "CADJPY"){tab= tab2+"  ";}
	else {if(Symbol()== "XAGUSD"){tab= tab2+"  ";}  }}}}}} 
	 //----Set digits in Price & convert Price to string  
   if (Use_For_Forex)
      {
      if(Symbol()== "XAGUSD" || Symbol()== "XAUUSD") 
         {
         fxDigits = 2;
         if (Display_5_Digits_Forex) {fxDigits = 3;}         
         }      
      Price=DoubleToStr(Bid, fxDigits);      
      }         
   else {Price=DoubleToStr(Bid, Digits);}  
   //----Create/move label
   ObjectCreate(item6, OBJ_LABEL, 0, 0, 0);
   ObjectSet(item6,OBJPROP_CORNER, 0);
   ObjectSet(item6,OBJPROP_XDISTANCE, 11); //12
   ObjectSet(item6,OBJPROP_YDISTANCE, 61); //62
   ObjectSet(item6, OBJPROP_COLOR, Color);     
   ObjectSetText(item6, tab+Price, 18, "Verdana Bold"); //17
   
   //Range High/Low----------------------------------------------------------------------------
   if (Range_H\L_Lines_Show)
      {
            if(Range_H\L_Lines_Max_Display_TF== "M1") {E= 1;}
      else {if(Range_H\L_Lines_Max_Display_TF== "M5") {E= 5;}
      else {if(Range_H\L_Lines_Max_Display_TF== "M15"){E= 15;}
      else {if(Range_H\L_Lines_Max_Display_TF== "M30"){E= 30;}
      else {if(Range_H\L_Lines_Max_Display_TF== "H1") {E= 60;}
      else {if(Range_H\L_Lines_Max_Display_TF== "H4") {E= 240;}
      else {if(Range_H\L_Lines_Max_Display_TF== "D")  {E= 1440;}
      else {if(Range_H\L_Lines_Max_Display_TF== "W")  {E= 10080;}
      else {if(Range_H\L_Lines_Max_Display_TF== "M")  {E= 43200;}}}}}}}}} 
      if(Period()<= E)         
         {    
         Ranges(Days_For_Range_Average);
         RangeAvg = NormalizeDouble(ARg/Days_For_Range_Average,4);                
         RangeHigh =  RangeAvg + iLow(NULL,PERIOD_D1,0);  //Comment(RangeHigh);
         RangeLow  = -RangeAvg + iHigh(NULL,PERIOD_D1,0); 

         if (HiToday - LoToday > RangeAvg)
            {            
            if (Bid >= HiToday- (HiToday-LoToday)/2) {RangeHigh = LoToday + RangeAvg; RangeLow  = LoToday;}
            else {RangeHigh  = HiToday; RangeLow = HiToday - RangeAvg;}
            }
             
         //Range Lines data to subroutine                                                          
         if(RG_LineStyle_01234>0){RG_SolidLineThickness=0;}    
         Pivots(" RgH", RangeHigh, RangeHigh_Color, RG_LineStyle_01234, RG_SolidLineThickness);   
         Pivots(" RgL",  RangeLow,  RangeLow_Color, RG_LineStyle_01234, RG_SolidLineThickness);      
         }  
      }
   
   //MktOpen and Session Separator vLines-----------------------------------------------------   
   if (vLines_Show)
      {
      if(vLines_Max_Display_TF== "M1") {E= 1;}
      else {if(vLines_Max_Display_TF== "M5") {E= 5;}
      else {if(vLines_Max_Display_TF== "M15"){E= 15;}
      else {if(vLines_Max_Display_TF== "M30"){E= 30;}
      else {if(vLines_Max_Display_TF== "H1") {E= 60;}
      else {if(vLines_Max_Display_TF== "H4") {E= 240;}
      else {if(vLines_Max_Display_TF== "D")  {E= 1440;}
      else {if(vLines_Max_Display_TF== "W")  {E= 10080;}
      else {if(vLines_Max_Display_TF== "M")  {E= 43200;}}}}}}}}} 
      if(Period()<= E)         
         {       
         //Calculate position for vline labels------------------------------------------------              
         if (vLineLabels_Dist_To_Border < 1) {vLineLabels_Dist_To_Border = 1;}            
         top = WindowPriceMax();
         bottom = WindowPriceMin();
         scale = top - bottom;            
         YadjustTop = scale/(9000/vLineLabels_FontSize);      
         YadjustTop = YadjustTop + (vLineLabels_Dist_To_Border * YadjustTop);      
         YadjustBot = scale/(500/vLineLabels_FontSize); 
         YadjustBot = YadjustBot + ((vLineLabels_Dist_To_Border * YadjustBot)/20);                  	      	
         level = top - YadjustTop; level = level;                 
         if (!vLineLabels_Chart_Top) {level = bottom + YadjustBot;}       
            
         //Do vlines for current session------------------------------------------------------           
         if (Session_Lines_Shown)
            {
            OpenToday(Session_Lines_Label, 0, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);             
            OpenToday(" "+Session_Lines_Label, 24, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);           
            }               
         if (Sydney_Open_Shown) 
            {
            OpenToday(Sydney_Open_Label, Sydney_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            }   
         if (Tokyo_Open_Shown) 
            {
            OpenToday(Tokyo_Open_Label, Tokyo_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            }
         if (Moscow_Open_Shown) 
            {
            OpenToday(Moscow_Open_Label, Moscow_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            }                 
         if (FrankFurt_Open_Shown) 
            {
            OpenToday(Frankfurt_Open_Label, Frankfurt_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            } 
         if(London_Open_Shown) 
            {
            OpenToday(London_Open_Label, London_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            } 
         if(NewYork_Open_Shown) 
            {
            OpenToday(NewYork_Open_Label, NewYork_Open_Time, vLines_Color, 
            vLines_LineStyle_01234, vLines_SolidLineThickness, level);
            }               

         //Do vlines for previous sessions-----------------------------------------------------   
         if (Prior_Sessions_To_Show >0) 
            {   
            //Calculate bars per session-------------------------------------------------------        
            if (Period()==1) {bps = 1440;}   
            else {if (Period()==5) {bps = 288;}  
            else {if (Period()==15){bps = 96;}    
            else {if (Period()==30){bps = 48;}
            else {if (Period()==60){bps = 24;} }}}}  
      
            //Define bar starting prior sessions display---------------------------------------      
            shift = iBarShift(NULL,NULL,iTime(NULL,PERIOD_D1,0));      

            //Execute loop for bars per session X number of prior sessions to show-------------    
            for (i= shift; i<=(shift+(bps*(Prior_Sessions_To_Show))); i++)       
               {  
               h=TimeHour(Time[i]); 
               m=TimeMinute(Time[i]);   
               if (Session_Lines_Shown && h==0 && m==0)         
                  { 
                  OpenPrior(i, Session_Lines_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);           
                  }                 
               if (Sydney_Open_Shown && h==Sydney_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, Sydney_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  }   
               if (Tokyo_Open_Shown && h==Tokyo_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, Tokyo_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  }
               if (Moscow_Open_Shown && h==Moscow_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, Moscow_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  }                       
               if (FrankFurt_Open_Shown && h==Frankfurt_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, Frankfurt_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  } 
               if(London_Open_Shown && h==London_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, London_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  } 
               if(NewYork_Open_Shown && h==NewYork_Open_Time + vLines_Server_GMToffset && m == 0) 
                  {
                  OpenPrior(i, NewYork_Open_Label, vLines_Color, 
                  vLines_LineStyle_01234, vLines_SolidLineThickness, level);
                  }               
               }
            }//Close prior session loop
         }//Close "do" vLines routine
      }//Close "skip" vLines routine                          
   //End of program computations---------------------------------------------------------------        
   return(0);
   }
    
//+-------------------------------------------------------------------------------------------+
//| Indicator Pivots Subroutine To Create Lines And Labels                                    |                                                                                  |
//+---------------------------------------------------------------------------------------- --+
void Pivots(string text, double level, color Color, int linestyle, int thickness)
   {
   //Lines=====================================================================================  
   //Name lines   
   rangeline  = "[Market Panel]  " + StringTrimLeft(text) + " Line"; 

   //At which bar to start pivot line & where to stop pivot line
   startpivottoday = Time[1];//1st TF of new day, start line at bar previous to current bar.
   if (Time[0] > iTime(NULL, PERIOD_D1, 0)) {startpivottoday = iTime(NULL, PERIOD_D1, 0);} 
   stopline = Time[0]; 
      
   //Determine start position for labels & initiate needed variables                      
   a = linestyle; b = thickness; c =1; if(a==0) c=b;
   F = true; //draw line as ray    
   G = true; //Subordinates margin labels and pivot lines/labels   
   Z= OBJ_TREND; //default set for trend lines, not horizontal lines     
   if (!RangeLabels\Lines_Subordinate) G= false;
   if (StopLines_At_Current_Candle && StartLines_Number != 3) {F = false;}
   if(StartLines_Number == 2) {startline = startpivottoday;}                               
   else {startline  = Time[1];}  
                  
   //Create/move lines 
   if (ObjectFind(rangeline) != 0){
      ObjectCreate(rangeline, Z, 0, startline, level, stopline, level);
      ObjectSet(rangeline, OBJPROP_STYLE, linestyle);
      ObjectSet(rangeline, OBJPROP_COLOR, Color);
      ObjectSet(rangeline, OBJPROP_WIDTH, c);
      ObjectSet(rangeline, OBJPROP_BACK, G); 
      ObjectSet(rangeline, OBJPROP_RAY, F);}
   else{
      ObjectMove(rangeline, 0, startline, level);
      ObjectMove(rangeline, 1, stopline, level);}
      
   //Labels===================================================================================
   //Exit if label not to be shown           
   if (StringSubstr(text,1,2) == "Rg" && !RangeLabels_Shown)return (-1);    
   else {
        //Name label,define price and add price to label if required         
        rangelabel = "[Market Panel]  " + StringTrimLeft(text) + " Label";
        if (RangeLabels_Prices && StrToInteger(text)==0) {
           if (Use_For_Forex) {Price=DoubleToStr(level, fxDigits);}
           else {Price=DoubleToStr(level, Digits);}
           text = text + "   " + Price; } 
        spc = "   "; text = spc + text; //align with PivotsW_v6 labels
               
        //Determine start position for labels & initiate needed variables 
        G= true; if(!RangeLabels\Lines_Subordinate) {G= false;} 
                         
        if (RangeLabels_MaxRight) //start max right
           {
           if(!RangeLabels_Prices) {tab="                                ";} //32
           else {tab="                                              ";}      //46  
           startlabel = Time[0];    
           }    
        else {if(StartLines_Number == 2) //start at day separator
           {
           if(!RangeLabels_Prices) {tab="           ";}                      //11
           else {tab="                         ";}                           //25
           startlabel= iTime(NULL, PERIOD_D1, 0);  
           }         
        else //start at current candle  {if(StartLines_Number==3) 
           {
           if(!RangeLabels_Prices) {tab="           ";}                      //11
           else {tab="                         ";}                           //25   
           startlabel = Time[0];          
           }  }                            

      //Draw/move the labels                   
      if (ObjectFind(rangelabel) != 0){
         ObjectCreate(rangelabel, OBJ_TEXT, 0, startlabel, level);     
         ObjectSetText(rangelabel, tab+text, RangeLabels_FontSize, RangeLabels_FontStyle, RangeLabels_Color);
         ObjectSet(rangelabel, OBJPROP_BACK, G);}        
      else {ObjectMove(rangelabel, 0, startlabel, level);}       
      }
   }
   
//+-------------------------------------------------------------------------------------------+
//| Indicator Subroutine To Compute Average Ranges                                            |                                                 
//+-------------------------------------------------------------------------------------------+ 
void Ranges (int period)
   {
   int ii, iii, x, xx;
   //Add ranges over period.  Count number of Sundays and exclude Sunday ranges.         
   ARg = 0; for(i=1; i<=Days_For_Range_Average; i++)
       {
       if (TimeDayOfWeek(iTime(NULL,PERIOD_D1,i))!=0) {
       ARg = ARg + iHigh(NULL,PERIOD_D1,i)- iLow(NULL,PERIOD_D1,i);}
       else {x=x+1;}
       }
   //For number of Sundays, add additional days of range
   for(ii=i+1; ii<i+x+1; ii++) 
       {
       if (TimeDayOfWeek(iTime(NULL,PERIOD_D1,ii))!=0) {       
       ARg = ARg + iHigh(NULL,PERIOD_D1,ii)- iLow(NULL,PERIOD_D1,ii);}
       else {xx=xx+1;}       
       }      
   //If a Sunday reduced added days above, add additional day of range
   for(iii=ii+1; iii<ii+xx+1; iii++) 
       {
       ARg = ARg + iHigh(NULL,PERIOD_D1,iii)- iLow(NULL,PERIOD_D1,iii);
       }                     
   //Return total of ranges for period (Sundays excluded/additional days subsituted)
   return (ARg);   
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator Subroutine to Create Market Open Lines And Labels For Current Session           |          
//+-------------------------------------------------------------------------------------------+   
void OpenToday(string text, datetime T, color Color, int linestyle, int thickness, double level) 
   {
   vline  = "[Market Panel] " + StringTrimLeft(text) + " Current Session Line";    
   vlabel = "[Market Panel] " + StringTrimLeft(text) + " Current Session Label";   
   
   a = linestyle;
   b = thickness;
   c =1; if (a==0)c=b;  
   t = T;
   
   if (text != Session_Lines_Label && text != " "+Session_Lines_Label) {T = T + vLines_Server_GMToffset;}
   
   dt= TimeYear(iTime(NULL,0,0))+ "." +TimeMonth(iTime(NULL,0,0))+ "." + TimeDay(iTime(NULL,1440,0))+ "." +T+":"+"00";  
   if(T == 24) //Do datetime for end of current session vline         
      {
      dt= TimeYear(iTime(NULL,0,0))+ "." +TimeMonth(iTime(NULL,0,0))+ "." + TimeDay(iTime(NULL,PERIOD_D1,0))+ "." + T+23 + ":" + "60";                     
      }              
   T = StrToTime(dt); 
   if (t == 24) {T=T+60;} //End of current session datetime requires extra tweak here.          
                             
   if (ObjectFind(vline) != 0){ 
      ObjectCreate(vline, OBJ_TREND, 0, T, 0, T, 100);
      ObjectSet(vline, OBJPROP_STYLE, a);    
      ObjectSet(vline, OBJPROP_WIDTH, c);
      ObjectSet(vline, OBJPROP_COLOR, Color);
      ObjectSet(vline, OBJPROP_BACK, true); }
   else{
      ObjectMove(vline, 0, T, 0); 
      ObjectMove(vline, 1, T, 100);} 
                                 
   if (ObjectFind(vlabel) != 0) {
      ObjectCreate (vlabel, OBJ_TEXT, 0, T, level);
      ObjectSetText(vlabel, text, vLineLabels_FontSize, vLineLabels_FontStyle, vLineLabels_Color); 
      ObjectSet(vlabel, OBJPROP_BACK, true);}       
   else{ObjectMove(vlabel, 0, T, level);}  
   }
  
//+-------------------------------------------------------------------------------------------+
//| Indicator Subroutine to Create Market Open Lines And Labels For Prior Sessions            |          
//+-------------------------------------------------------------------------------------------+   
void OpenPrior(int i, string text, color Color, int linestyle, int thickness, double level) 
   {   
   vline  = "[Market Panel] " + StringTrimLeft(text) + " Prior Session  " + (i-1) + " Line";    
   vlabel = "[Market Panel] " + StringTrimLeft(text) + " Prior Session  " + (i-1) + " Label";   
   
   a = linestyle;
   b = thickness;
   c =1; if (a==0)c=b;
                              
   if (ObjectFind(vline) != 0){ 
      ObjectCreate(vline, OBJ_TREND, 0, Time[i], 0, Time[i], 100);
      ObjectSet(vline, OBJPROP_STYLE, a);    
      ObjectSet(vline, OBJPROP_WIDTH, c);
      ObjectSet(vline, OBJPROP_COLOR, Color);
      ObjectSet(vline, OBJPROP_BACK, true); }
   else{
      ObjectMove(vline, 0, Time[i], 0); 
      ObjectMove(vline, 1, Time[i], 100);} 
                                
   if (ObjectFind(vlabel) != 0) {
      ObjectCreate (vlabel, OBJ_TEXT, 0, Time[i], level);
      ObjectSetText(vlabel, text, vLineLabels_FontSize, vLineLabels_FontStyle, vLineLabels_Color); 
      ObjectSet(vlabel, OBJPROP_BACK, true);}       
   else{ObjectMove(vlabel, 0, Time[i], level);}    
   }

//+-------------------------------------------------------------------------------------------+
//| Indicator End                                                                             |                                                        
//+-------------------------------------------------------------------------------------------+      

