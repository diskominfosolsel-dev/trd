/*------------------------------------------------------------------------------------
   Name: Genesis Matrix
   Derived from: Genesis Matrix 2.20_1

   Change log: 
   2.22 2014-02-05 Update for MT4.5
   2.21_1 2012 07 16 Added T3_BarCount extern 
                     Changed ProcessT3 to send the BarCount parameter
   2.20_1 2012 07 09 Reverted to original ProcessT3 parameters without the iCustom call with price and bars; wrong answers returned.
   2.20   2012 07 09 Swapped the Fisher M11 for the Gann HiLo
                     Corrected the T3 period from 10 to 8
   2.12_1 2012 07 06 Name change for consistency with the secondary matrix. No code changes.
   2.10   2012 06 30 Changed the CCI to use a threshold value to determine red/blue (but then turned it off)
                     Set MaxBars = 500 as extern to replace use of Bars (but then turned it off)
          2012 06 26 Cody Changed Gann to T3_8
                          Changed Fisher Yurik to Fisher M11
                          Name change to Genesis 2.00
        2012-04-25. Xaphod, v1.02
           - Force repaint of all bars if newbars>3 on set TF
        2012-04-23. Xaphod, v1.01
           - Fixed Alerts
        2012-04-20. Xaphod, v1.00
           - First Release 
-------------------------------------------------------------------------------------*/
// Indicator properties
//#property copyright "Copyright © 2012, Xaphod"
#property link      "http://www.forexfactory.com/showthread.php?t=373796"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 C'0,90,255'
#property indicator_color2 Red
#property indicator_color3 C'0,90,255'
#property indicator_color4 Red
#property indicator_color5 C'0,90,255'
#property indicator_color6 Red
#property indicator_color7 C'0,90,255'
#property indicator_color8 Red
#property indicator_minimum 0
#property indicator_maximum 2.3

//#include <xPrint.mqh>

// Constant definitions
#define INDICATOR_NAME "Genesis"
#define INDICATOR_VERSION "2.22"
#define BAR_CHAR 110
#define IND_TVI        "TVI"
#define IND_GANNHILO   "GannHiLo-Histo"
#define IND_T3_8       "T3_2ColorHisto"

#define IDX_TVI       0
#define IDX_CCI       1
#define IDX_T3_8      2
#define IDX_GHL       3

// Indicator parameters
// Timeframe: 0,1,5,15,30,60,240,1440 etc. Current Timeframe=0. 
// Automatically select higher TF. M15 and M30 -> H1. Off=0, 1st HTF=1, 2nd HTF=2
extern string    TimeFrame_Settings="——————————————————————————————";
extern int       TimeFrame_Period=0;        
extern int       TimeFrame_Auto=0;          
extern string    TVI_Settings="——————————————————————————————";
extern int       TVI_r=12;
extern int       TVI_s=12;
extern int       TVI_u=5;
extern string    TVI_Label="TVI";
extern string    CCI_Settings="——————————————————————————————";
extern int       CCI_Period=20;
extern double    CCI_Threshold=60;
extern string    CCI_Label="CCI";
extern string    T3_Settings="——————————————————————————————";
extern int       T3_Period=8;
extern int       T3_BarCount=1500;
extern string    T3_Label="T3..";
extern string    GannHiLo_Settings="——————————————————————————————";
extern int       GannHiLo_Period=10;
extern string    GannHiLo_Label="GHL";
extern string    Alert_Settings="——————————————————————————————";
extern bool      Alert_OnBarClose=True;     // Alert only when an open bar closes
extern bool      Alert_Popup=False;         // Enable popup window & sound on alert
extern bool      Alert_Email=False;         // Enable send email on alert
extern string    Alert_Subject="";          // Email Subject. Null string ("") will result in a preconfigured subject.
extern string    Display_Settings="——————————————————————————————";
extern color     Display_LabelColor=White;  // Color of Histogram Id labels

// Global module varables
// Histogram
double gadTVIUp[];
double gadTVIDn[];
double gadCCIUp[];
double gadCCIDn[];
double gadT3Up[];
double gadT3Dn[];
double gadGHLUp[];
double gadGHLDn[];

// Labels
double gadGap[4];

// Globals
int giRepaintBars;
string gsIndicatorName;
bool gbInit;

//-----------------------------------------------------------------------------
// function: init()
// Description: Custom indicator initialization function.
//-----------------------------------------------------------------------------
int init() {
  // Init indicator buffers
  IndicatorBuffers(8);
  SetIndexStyle(0,DRAW_ARROW);
  SetIndexBuffer(0,gadTVIUp);
  SetIndexStyle(1,DRAW_ARROW);
  SetIndexBuffer(1,gadTVIDn);
  SetIndexStyle(2,DRAW_ARROW);
  SetIndexBuffer(2,gadCCIUp);
  SetIndexStyle(3,DRAW_ARROW);
  SetIndexBuffer(3,gadCCIDn);  
  SetIndexStyle(4,DRAW_ARROW);
  SetIndexBuffer(4,gadT3Up);
  SetIndexStyle(5,DRAW_ARROW);
  SetIndexBuffer(5,gadT3Dn);
  SetIndexStyle(6,DRAW_ARROW);
  SetIndexBuffer(6,gadGHLUp);
  SetIndexStyle(7,DRAW_ARROW);
  SetIndexBuffer(7,gadGHLDn);
  for (int i = 0; i < 8; i++) {
    SetIndexLabel(i,NULL);
    SetIndexEmptyValue(i,0.0);
    SetIndexArrow(i,BAR_CHAR);
  }
  
  // Set Timeframe
  switch(TimeFrame_Auto) {
    case 1: 
      TimeFrame_Period=NextHigherTF(TimeFrame_Period); 
      giRepaintBars=TimeFrame_Period/Period()+2;
    break;
    case 2: 
      TimeFrame_Period=NextHigherTF(NextHigherTF(TimeFrame_Period));
      giRepaintBars=TimeFrame_Period/Period()+2;
    break;
    default: 
      if (TimeFrame_Period<1 || TimeFrame_Period==Period()) {
        TimeFrame_Period=Period();
        giRepaintBars=0;
      }
      else {
        giRepaintBars=TimeFrame_Period/Period()+2;
      }
    break;
  }
  
  // Set histogram positions
  gadGap[IDX_TVI]=1.9;
  gadGap[IDX_CCI]=1.4;
  gadGap[IDX_T3_8]=0.9;
  gadGap[IDX_GHL]=0.4;
  
  // Misc
  gsIndicatorName=INDICATOR_NAME+" "+INDICATOR_VERSION+"("+TF2Str(TimeFrame_Period)+")";
  IndicatorShortName(gsIndicatorName);
  gbInit=True;
  return(0);
}


//-----------------------------------------------------------------------------
// function: deinit()
// Description: Custom indicator deinitialization function.
//-----------------------------------------------------------------------------
int deinit() {
  // Clear text objects
  for(int i=ObjectsTotal()-1; i>-1; i--)
    if (StringFind(ObjectName(i),gsIndicatorName)>=0)  ObjectDelete(ObjectName(i));
  return (0);
}


//-----------------------------------------------------------------------------
// function: start()
// Description: Custom indicator iteration function.
//-----------------------------------------------------------------------------
int start() {
  int iNewBars;
  int iCountedBars; 
  static datetime tCurBar;
  
  // Get unprocessed bars
  iCountedBars=IndicatorCounted();
  if(iCountedBars < 0) return (-1); 
  if(iCountedBars>0) iCountedBars--;
  
  // Set bars to redraw
  if (NewBars(TimeFrame_Period)>3)
    iNewBars=Bars-1;
    //iNewBars=MaxBars-1;
  else
    iNewBars=Bars-iCountedBars;
    //iNewBars=MaxBars-iCountedBars;
  if (iNewBars<giRepaintBars)
    iNewBars=giRepaintBars;

  // Calc indicator data and update matrix
  ProcessTVI(iNewBars, TVI_r, TVI_s, TVI_u, gadTVIUp, gadTVIDn);
  ProcessCCI(iNewBars,CCI_Period, CCI_Threshold, gadCCIUp, gadCCIDn);
  ProcessT3_8(iNewBars,T3_Period, gadT3Up, gadT3Dn);
  ProcessGannHiLo(iNewBars,GannHiLo_Period, gadGHLUp, gadGHLDn);
  
  // Alerts
  CheckAlert();
    
  // Tasks to execute on bar close
  if (tCurBar<Time[0]) {
    tCurBar=Time[0];
    
    // Write/Update bar labels
    Writelabel(TVI_Label,gadGap[IDX_TVI]+0.2);
    Writelabel(CCI_Label,gadGap[IDX_CCI]+0.2);
    Writelabel(T3_Label,gadGap[IDX_T3_8]+0.2);
    Writelabel(GannHiLo_Label,gadGap[IDX_GHL]+0.2);
    
    // Clear the init flag   
    if (gbInit) 
      gbInit=False;
  }
  
  return(0);
}


//-----------------------------------------------------------------------------
// function: NewBars()
// Description: Return nr of new bars on a TF
//-----------------------------------------------------------------------------
int NewBars(int iPeriod) {
  static int iPrevSize=0;
  int iNewSize;
  int iNewBars;
  datetime tTimeArray[];
  
  ArrayCopySeries(tTimeArray,MODE_TIME,Symbol(),iPeriod);
  iNewSize=ArraySize(tTimeArray);
  iNewBars=iNewSize-iPrevSize;
  iPrevSize=iNewSize;
  return(iNewBars);
}


//-----------------------------------------------------------------------------
// function: ProcessTVI()
// Description: Calc TVI data and update matrix
//-----------------------------------------------------------------------------
int ProcessTVI(int iNewBars, int r, int s, int u, double& vdUp[], double& vdDn[]) {
  int i,j;
  double dTVI0=0, dTVI1=0;
  int iHTFBar=-1;
  
  for (i=iNewBars;i>=0;i--) {
    if (i>MathMax(Bars-2,Bars-r))
      continue;
    // Get index for higher timeframe bar
    if (TimeFrame_Period>Period())
      j=iBarShift(Symbol(), TimeFrame_Period, Time[i]);
    else
      j=i;
    // Calc TVI  
    if (iHTFBar!=j) {
      iHTFBar=j;
      dTVI1=iCustom(Symbol(),TimeFrame_Period,IND_TVI,r,s,u,0,j+1);
      dTVI0=iCustom(Symbol(),TimeFrame_Period,IND_TVI,r,s,u,0,j);
    }
    // No data
    if (dTVI0==EMPTY_VALUE) {
      vdUp[i]=0;
      vdDn[i]=0;
    }
    // Bull signal
    if (dTVI0>=dTVI1) {
      vdUp[i]=gadGap[IDX_TVI];
      vdDn[i]=0;
    }
    // Bear signal
    else {
      vdDn[i]=gadGap[IDX_TVI];
      vdUp[i]=0;
    }    
  }
  return(0);
}


//-----------------------------------------------------------------------------
// function: ProcessCCI()
// Description: Calc CCI data and update matrix
//-----------------------------------------------------------------------------
int ProcessCCI(int iNewBars, int iPeriod, double iThreshold, double& vdUp[], double& vdDn[]) {
  int i,j;
  double dSig=0;
  int iHTFBar=-1;
  
  for(i=iNewBars; i>=0; i--) {
    if (i>MathMax(Bars-2,Bars-iPeriod))
      continue;
    // Shift index for higher time-frame
    if (TimeFrame_Period>Period() )
      j=iBarShift(Symbol(), TimeFrame_Period, Time[i]);
    else
      j=i;
    // Calc CCI
    if (iHTFBar!=j) {
      iHTFBar=j;
      dSig=iCCI(NULL, TimeFrame_Period, iPeriod, PRICE_TYPICAL, j);
    }
    // No Data
    if (iClose(NULL,TimeFrame_Period,j)==0) {
      vdUp[i]=EMPTY_VALUE;
      vdDn[i]=EMPTY_VALUE;
    }
    // Bull signal
    //else if (dSig>0 && dSig > iThreshold ) {
    else if (dSig>0 ) {
      vdUp[i]=gadGap[IDX_CCI];
      vdDn[i] = 0;
    }
    // Bwar signal
    //else if (dSig < 0  && dSig < -iThreshold ){
    else if (dSig < 0 ){
      vdDn[i]=gadGap[IDX_CCI];
      vdUp[i] = 0;
    } 
  }
  return(0);
}


//-----------------------------------------------------------------------------
// function: ProcessT3_8()
// Description: Calc T3_8 data and update matrix
//-----------------------------------------------------------------------------
int ProcessT3_8(int iNewBars, int iPeriod, double& vdUp[], double& vdDn[]) {
  int i,j,iUp=0;
  double dSig=0;
  int iHTFBar=-1;
    
  // Draw tape chart
  for(i=iNewBars+TimeFrame_Period/Period(); i>=0; i--) {
    if (i>MathMax(Bars-2,Bars-iPeriod))
      continue;
    // Shift index for higher time-frame
    if (TimeFrame_Period>Period())
      j=iBarShift(Symbol(), TimeFrame_Period, Time[i]);
    else
      j=i;
    // Calc T3_8 data
    if (iHTFBar!=j) {
      iHTFBar=j;
      iUp = (int)iCustom(NULL,TimeFrame_Period,IND_T3_8,T3_Period,PRICE_CLOSE, T3_BarCount, 1,j);
      //iUp = iCustom(NULL,TimeFrame_Period,IND_T3_8,T3_Period,1,j);
    }
    // Bear signal
    if (iUp==1) {
      vdDn[i]=gadGap[IDX_T3_8];
      vdUp[i]=0;
    }
    // Bull signal
    else {
      vdUp[i]=gadGap[IDX_T3_8];
      vdDn[i]=0;
    }
  }
  return(0);
}  

//-----------------------------------------------------------------------------
// function: ProcessGannHiLo()
// Description: Calc GannHiLo data and update matrix
//-----------------------------------------------------------------------------
int ProcessGannHiLo(int iNewBars, int iPeriod, double& vdUp[], double& vdDn[]) {
  int i,j,iUp=0;
  int iHTFBar=-1;
    
  // Draw tape chart
  for(i=iNewBars+TimeFrame_Period/Period(); i>=0; i--) {
    if (i>MathMax(Bars-3,Bars-iPeriod))
      continue;
    // Shift index for higher time-frame
    if (TimeFrame_Period>Period())
      j=iBarShift(Symbol(), TimeFrame_Period, Time[i]);
    else
      j=i;
    // Calc GannHiLo data
    if (iHTFBar!=j) {
      iHTFBar=j;
      iUp = (int)iCustom(NULL,TimeFrame_Period,IND_GANNHILO,GannHiLo_Period,0,j);
    }
    // No Data
    if (iUp==EMPTY_VALUE) {
      vdUp[i]=0;
      vdDn[i]=0;
    }
    // Bull signal
    else if (iUp==1) {
      vdUp[i]=gadGap[IDX_GHL];
      vdDn[i]=0;
    }
    // Bear signal
    else {
      vdDn[i]=gadGap[IDX_GHL];
      vdUp[i]=0;
    }
  }
  return(0);
}  


//-----------------------------------------------------------------------------
// function: CheckAlert()
// Description: Check for new alerts
//-----------------------------------------------------------------------------
void CheckAlert() {
  static datetime tAlertBar;
  static int iPrevAlert=0;
  
  if (Alert_Popup || Alert_Email) {
    
    // Alert on the close of the current bar
    if (Alert_OnBarClose && tAlertBar<Time[iBarShift(Symbol(), TimeFrame_Period, Time[0])] && !gbInit) {
      
      tAlertBar=Time[iBarShift(Symbol(), TimeFrame_Period, Time[0])];
      // Clear alert flag
      if (iPrevAlert==1 && !UpSignal(1))
         iPrevAlert=0;
      else if (iPrevAlert==-1 && !DnSignal(1))
         iPrevAlert=0;
      // Alert and set alert flag
      if (UpSignal(1) && iPrevAlert!=1) {
         AlertNow(Symbol()+", "+TF2Str(Period())+": Genesis Matrix  Buy Signal.");
         iPrevAlert=1;
      }  
      else if (DnSignal(1) && iPrevAlert!=-1) {
         AlertNow(Symbol()+", "+TF2Str(Period())+": Genesis Matrix  Sell Signal.");
         iPrevAlert=-1;
      }
    }
  
    // Alert while the current bar is open
    if (!Alert_OnBarClose && tAlertBar<Time[iBarShift(Symbol(), TimeFrame_Period, Time[0])] && !gbInit) {
      // Clear alert flag
      if (iPrevAlert==1 && !UpSignal(0))
         iPrevAlert=0;
      else if (iPrevAlert==-1 && !DnSignal(0))
         iPrevAlert=0;      
      // Alert and set alert flag
      if (UpSignal(0) && iPrevAlert!=1) {
         AlertNow(Symbol()+", "+TF2Str(Period())+": Genesis Matrix  Buy Signal.");
         iPrevAlert=1;
         tAlertBar=Time[iBarShift(Symbol(), TimeFrame_Period, Time[0])];
      }  
      else if (DnSignal(0) && iPrevAlert!=-1) {
         AlertNow(Symbol()+", "+TF2Str(Period())+": Genesis Matrix Sell Signal.");
         iPrevAlert=-1;
         tAlertBar=Time[iBarShift(Symbol(), TimeFrame_Period, Time[0])];
      }
    }
  }
}


//-----------------------------------------------------------------------------
// function: AlertNow()
// Description: Signal the popup and email alerts
//-----------------------------------------------------------------------------
void AlertNow(string sAlertMsg) {
  //Popup Alert 
  if (Alert_Popup) 
    Alert(INDICATOR_NAME, ", ", sAlertMsg);      
  //Email Alert
  if (Alert_Email) {
    if (Alert_Subject=="")
      SendMail( sAlertMsg, "MT4 Alert!\n"+INDICATOR_NAME+"\n" + TimeToStr(Time[0],TIME_DATE|TIME_SECONDS )+"\n"+sAlertMsg);
    else 
      SendMail( Alert_Subject, "MT4 Alert!\n"+INDICATOR_NAME+"\n" + TimeToStr(Time[0],TIME_DATE|TIME_SECONDS )+"\n"+sAlertMsg);          
  }
}


//-----------------------------------------------------------------------------
// function: UpSignal()
// Description: Return true if there is an up signal
//-----------------------------------------------------------------------------
bool UpSignal(int i) {
  if (gadTVIUp[i]>0 && gadCCIUp[i]>0 && gadGHLUp[i]>0 && gadT3Up[i]>0)
    return(True);
  else
    return(False);
}


//-----------------------------------------------------------------------------
// function: DnSignal()
// Description: eturn true if there is a down signal
//-----------------------------------------------------------------------------
bool DnSignal(int i) {
  if (gadTVIDn[i]>0 && gadCCIDn[i]>0 && gadGHLDn[i]>0 && gadT3Dn[i]>0)
    return(True);
  else
    return(False);
}


//-----------------------------------------------------------------------------
// function: Writelabel()
// Description: Write a label for a bar
//-----------------------------------------------------------------------------
int Writelabel(string sLabel,double dPrice) {
  string sObjId;
  sObjId=gsIndicatorName+"_"+sLabel;
  if(ObjectFind(sObjId) < 0)
    ObjectCreate(sObjId, OBJ_TEXT, WindowFind(gsIndicatorName), Time[0]+Period()*60*2, dPrice);
  ObjectSetText(sObjId, sLabel, 8, "Calibri", Display_LabelColor); //Lucida Console
  ObjectMove(sObjId,0,Time[0]+Period()*60*2, dPrice);
  return(0);
}


//-----------------------------------------------------------------------------
// function: TF2Str()
// Description: Convert time-frame to a string
//-----------------------------------------------------------------------------
string TF2Str(int iPeriod) {
  switch(iPeriod) {
    case PERIOD_M1: return("M1");
    case PERIOD_M5: return("M5");
    case PERIOD_M15: return("M15");
    case PERIOD_M30: return("M30");
    case PERIOD_H1: return("H1");
    case PERIOD_H4: return("H4");
    case PERIOD_D1: return("D1");
    case PERIOD_W1: return("W1");
    case PERIOD_MN1: return("MN1");
    default: return("M"+(string)iPeriod);
  }
  return("M?");
}


//-----------------------------------------------------------------------------
// function: NextHigherTF()
// Description: Select the next higher time-frame. 
//              Note: M15 and M30 both select H1 as next higher TF. 
//-----------------------------------------------------------------------------
int NextHigherTF(int iPeriod) {
  if (iPeriod==0) iPeriod=Period();
  switch(iPeriod) {
    case PERIOD_M1: return(PERIOD_M5);
    case PERIOD_M5: return(PERIOD_M15);
    case PERIOD_M15: return(PERIOD_H1);
    case PERIOD_M30: return(PERIOD_H1);
    case PERIOD_H1: return(PERIOD_H4);
    case PERIOD_H4: return(PERIOD_D1);
    case PERIOD_D1: return(PERIOD_W1);
    case PERIOD_W1: return(PERIOD_MN1);
    case PERIOD_MN1: return(PERIOD_MN1);
    default: return(Period());
  }
  return(Period());
}