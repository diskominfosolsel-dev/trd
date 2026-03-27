

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 White
#property indicator_color2 White

bool gi_76 = TRUE;
int gi_80 = 0;
string gs_84 = "2019.12.31";
extern bool AlertsOn = FALSE;
extern bool Comments = FALSE;
extern bool TrendLine = TRUE;
extern int TrendLineStyle = 0;
extern int TrendLineWidth = 3;
extern color UpperTrendLineColour = LimeGreen;
extern color LowerTrendLineColour = Red;
extern bool ProjectionLines = TRUE;
extern int ProjectionLinesStyle = 2;
extern int ProjectionLinesWidth = 3;
extern color UpperProjectionLineColour = LimeGreen;
extern color LowerProjectionLineColour = Red;
extern bool HorizontLine = FALSE;
bool gi_144 = FALSE;
int gi_148 = 0;
int gi_152 = 1;
bool gi_156 = FALSE;
double gd_160 = -1.0;
bool gi_168 = FALSE;
double gd_172 = -1.0;
bool gi_180 = FALSE;
double g_ibuf_184[];
double g_ibuf_188[];

int init() {
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexArrow(0, 217);
   SetIndexBuffer(0, g_ibuf_184);
   SetIndexEmptyValue(0, 0.0);
   SetIndexStyle(1, DRAW_ARROW);
   SetIndexArrow(1, 218);
   SetIndexBuffer(1, g_ibuf_188);
   SetIndexEmptyValue(1, 0.0);
   for (int li_0 = 1; li_0 <= 10; li_0++) {
      ObjectDelete("HHL_" + li_0);
      ObjectDelete("HL_" + li_0);
      ObjectDelete("HLL_" + li_0);
      ObjectDelete("LL_" + li_0);
      ObjectDelete("HC1_" + li_0);
      ObjectDelete("HC2_" + li_0);
      ObjectDelete("HC3_" + li_0);
      ObjectDelete("LC1_" + li_0);
      ObjectDelete("LC2_" + li_0);
      ObjectDelete("LC3_" + li_0);
   }
   Comment("");
   return (0);
}

int deinit() {
   for (int li_0 = 1; li_0 <= 10; li_0++) {
      ObjectDelete("HHL_" + li_0);
      ObjectDelete("HL_" + li_0);
      ObjectDelete("HLL_" + li_0);
      ObjectDelete("LL_" + li_0);
      ObjectDelete("HC1_" + li_0);
      ObjectDelete("HC2_" + li_0);
      ObjectDelete("HC3_" + li_0);
      ObjectDelete("LC1_" + li_0);
      ObjectDelete("LC2_" + li_0);
      ObjectDelete("LC3_" + li_0);
   }
   Comment("");
   return (0);
}

int SetTDPoint(int ai_0) {
   if (gi_156 == FALSE) {
      for (int li_4 = ai_0; li_4 > 1; li_4--) {
         if (High[li_4 + 2] < High[li_4] && High[li_4 + 1] < High[li_4] && High[li_4 - 1] < High[li_4] && High[li_4 - 2] < High[li_4]) g_ibuf_184[li_4] = High[li_4];
         if (Low[li_4 + 2] > Low[li_4] && Low[li_4 + 1] > Low[li_4] && Low[li_4 - 1] > Low[li_4] && Low[li_4 - 2] > Low[li_4]) g_ibuf_188[li_4] = Low[li_4];
      }
      g_ibuf_184[0] = 0;
      g_ibuf_188[0] = 0;
      g_ibuf_184[1] = 0;
      g_ibuf_188[1] = 0;
   } else {
      for (li_4 = ai_0; li_4 > 3; li_4--) {
         if (High[li_4 + 1] <= High[li_4] && High[li_4 - 1] < High[li_4] && High[li_4 + 2] <= High[li_4] && High[li_4 - 2] < High[li_4]) g_ibuf_184[li_4] = High[li_4];
         else g_ibuf_184[li_4] = 0;
         if (Low[li_4 + 1] >= Low[li_4] && Low[li_4 - 1] > Low[li_4] && Low[li_4 + 2] >= Low[li_4] && Low[li_4 - 2] > Low[li_4]) g_ibuf_188[li_4] = Low[li_4];
         else g_ibuf_188[li_4] = 0;
      }
      g_ibuf_184[0] = 0;
      g_ibuf_188[0] = 0;
      g_ibuf_184[1] = 0;
      g_ibuf_188[1] = 0;
      g_ibuf_184[2] = 0;
      g_ibuf_188[2] = 0;
   }
   return (0);
}

int GetHighTD(int ai_0) {
   int l_index_4 = 0;
   for (int l_count_8 = 0; l_count_8 < ai_0; l_count_8++) {
      l_index_4++;
      while (g_ibuf_184[l_index_4] == 0.0) {
         l_index_4++;
         if (l_index_4 > Bars - 2) return (-1);
      }
   }
   return (l_index_4);
}

int GetNextHighTD(int ai_0) {
   int li_ret_4 = ai_0 + 1;
   while (g_ibuf_184[li_ret_4] <= High[ai_0]) {
      li_ret_4++;
      if (li_ret_4 > Bars - 2) return (-1);
   }
   return (li_ret_4);
}

int GetLowTD(int ai_0) {
   int l_index_4 = 0;
   for (int l_count_8 = 0; l_count_8 < ai_0; l_count_8++) {
      l_index_4++;
      while (g_ibuf_188[l_index_4] == 0.0) {
         l_index_4++;
         if (l_index_4 > Bars - 2) return (-1);
      }
   }
   return (l_index_4);
}

int GetNextLowTD(int ai_0) {
   int li_ret_4 = ai_0 + 1;
   while (g_ibuf_188[li_ret_4] >= Low[ai_0] || g_ibuf_188[li_ret_4] == 0.0) {
      li_ret_4++;
      if (li_ret_4 > Bars - 2) return (-1);
   }
   return (li_ret_4);
}

int TrendLineHighTD(int ai_0, int ai_4, int ai_8, int ai_unused_12) {
   ObjectSet("HL_" + ai_8, OBJPROP_TIME1, Time[ai_4]);
   ObjectSet("HL_" + ai_8, OBJPROP_TIME2, Time[ai_0]);
   ObjectSet("HL_" + ai_8, OBJPROP_PRICE1, High[ai_4]);
   ObjectSet("HL_" + ai_8, OBJPROP_PRICE2, High[ai_0]);
   ObjectSet("HL_" + ai_8, OBJPROP_COLOR, UpperTrendLineColour);
   if (ai_8 == 1) ObjectSet("HL_" + ai_8, OBJPROP_WIDTH, TrendLineWidth);
   else ObjectSet("HL_" + ai_8, OBJPROP_WIDTH, 2);
   return (0);
}

int TrendLineLowTD(int ai_0, int ai_4, int ai_8, int ai_unused_12) {
   ObjectSet("LL_" + ai_8, OBJPROP_TIME1, Time[ai_4]);
   ObjectSet("LL_" + ai_8, OBJPROP_TIME2, Time[ai_0]);
   ObjectSet("LL_" + ai_8, OBJPROP_PRICE1, Low[ai_4]);
   ObjectSet("LL_" + ai_8, OBJPROP_PRICE2, Low[ai_0]);
   ObjectSet("LL_" + ai_8, OBJPROP_COLOR, LowerTrendLineColour);
   if (ai_8 == 1) ObjectSet("LL_" + ai_8, OBJPROP_WIDTH, TrendLineWidth);
   else ObjectSet("LL_" + ai_8, OBJPROP_WIDTH, 2);
   return (0);
}

int HorizontLineHighTD(int ai_0, int ai_4, int ai_8, double a_style_12, color a_color_20) {
   ObjectSet("HHL_" + ai_8, OBJPROP_PRICE1, High[ai_4] - (High[ai_4] - High[ai_0]) / (ai_4 - ai_0) * ai_4);
   ObjectSet("HHL_" + ai_8, OBJPROP_STYLE, a_style_12);
   ObjectSet("HHL_" + ai_8, OBJPROP_COLOR, a_color_20);
   ObjectSet("HHL_" + ai_8, OBJPROP_BACK, TRUE);
   return (0);
}

int HorizontLineLowTD(int ai_0, int ai_4, int ai_8, double a_style_12, color a_color_20) {
   ObjectSet("HLL_" + ai_8, OBJPROP_PRICE1, Low[ai_4] + (Low[ai_0] - Low[ai_4]) / (ai_4 - ai_0) * ai_4);
   ObjectSet("HLL_" + ai_8, OBJPROP_STYLE, a_style_12);
   ObjectSet("HLL_" + ai_8, OBJPROP_COLOR, a_color_20);
   ObjectSet("HLL_" + ai_8, OBJPROP_BACK, TRUE);
   return (0);
}

string TakeProfitHighTD(int ai_0, int ai_4, int ai_8, color a_color_12) {
   int l_lowest_20;
   double ld_44;
   double ld_52;
   double ld_60;
   double l_style_76;
   int l_count_24 = 0;
   string ls_ret_28 = "";
   double ld_36 = (High[ai_4] - High[ai_0]) / (ai_4 - ai_0);
   while (NormalizeDouble(Point, l_count_24) == 0.0) l_count_24++;
   double ld_68 = 0;
   for (int li_16 = ai_0; li_16 > 0; li_16--) {
      if (Close[li_16] > High[ai_4] - ld_36 * (ai_4 - li_16)) {
         ld_68 = High[ai_4] - ld_36 * (ai_4 - li_16);
         break;
      }
   }
   if (ld_68 > 0.0) {
      ls_ret_28 = ls_ret_28 + "UTD_Line (" + DoubleToStr(High[ai_4] - ld_36 * ai_4, l_count_24) + ") broken at " + DoubleToStr(ld_68, l_count_24) + ", uptargets:\n";
      l_lowest_20 = iLowest(NULL, 0, MODE_LOW, ai_4 - li_16, li_16);
      ld_44 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Low[l_lowest_20];
      ld_52 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Close[l_lowest_20];
      l_lowest_20 = iLowest(NULL, 0, MODE_CLOSE, ai_4 - li_16, li_16);
      ld_60 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Close[l_lowest_20];
      l_style_76 = TrendLineStyle;
   } else {
      ld_68 = High[ai_4] - ld_36 * ai_4;
      ls_ret_28 = ls_ret_28 + "UTD_Line (" + DoubleToStr(ld_68, l_count_24) + "), Possible break-up. \n";
      l_lowest_20 = iLowest(NULL, 0, MODE_LOW, ai_4, 0);
      ld_44 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Low[l_lowest_20];
      ld_52 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Close[l_lowest_20];
      l_lowest_20 = iLowest(NULL, 0, MODE_CLOSE, ai_4, 0);
      ld_60 = High[ai_4] - ld_36 * (ai_4 - l_lowest_20) - Close[l_lowest_20];
      l_style_76 = TrendLineStyle;
   }
   ObjectSet("HL_" + ai_8, OBJPROP_STYLE, l_style_76);
   ls_ret_28 = ls_ret_28 + "TP1=" + DoubleToStr(ld_44 + ld_68, l_count_24) + " (" + DoubleToStr(ld_44 / Point, 0) + "pts.)\n";
   ObjectSet("HC1_" + ai_8, OBJPROP_TIME1, Time[ai_0]);
   ObjectSet("HC1_" + ai_8, OBJPROP_TIME2, Time[0]);
   ObjectSet("HC1_" + ai_8, OBJPROP_PRICE1, ld_44 + ld_68);
   ObjectSet("HC1_" + ai_8, OBJPROP_PRICE2, ld_44 + ld_68);
   ObjectSet("HC1_" + ai_8, OBJPROP_COLOR, a_color_12);
   ObjectSet("HC1_" + ai_8, OBJPROP_STYLE, l_style_76);
   if (ai_8 == 1) {
      ObjectSet("HC1_" + ai_8, OBJPROP_WIDTH, ProjectionLinesWidth);
      ObjectSet("HC1_" + ai_8, OBJPROP_STYLE, ProjectionLinesStyle);
   } else ObjectSet("HC1_" + ai_8, OBJPROP_WIDTH, 2);
   return (ls_ret_28);
}

string TakeProfitLowTD(int ai_0, int ai_4, int ai_8, color a_color_12) {
   int l_highest_20;
   double ld_44;
   double ld_52;
   double ld_60;
   double l_style_76;
   int l_count_24 = 0;
   string ls_ret_28 = "";
   double ld_36 = (Low[ai_0] - Low[ai_4]) / (ai_4 - ai_0);
   while (NormalizeDouble(Point, l_count_24) == 0.0) l_count_24++;
   double ld_68 = 0;
   for (int li_16 = ai_0; li_16 > 0; li_16--) {
      if (Close[li_16] < Low[ai_4] + ld_36 * (ai_4 - li_16)) {
         ld_68 = Low[ai_4] + ld_36 * (ai_4 - li_16);
         break;
      }
   }
   if (ld_68 > 0.0) {
      ls_ret_28 = ls_ret_28 + "LTD_Line (" + DoubleToStr(Low[ai_4] + ld_36 * ai_4, l_count_24) + ") broken at " + DoubleToStr(ld_68, l_count_24) + ", downtargets:\n";
      l_highest_20 = iHighest(NULL, 0, MODE_HIGH, ai_4 - li_16, li_16);
      ld_44 = High[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      ld_52 = Close[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      li_16 = iHighest(NULL, 0, MODE_CLOSE, ai_4 - li_16, li_16);
      ld_60 = Close[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      l_style_76 = TrendLineStyle;
   } else {
      ld_68 = Low[ai_4] + ld_36 * ai_4;
      ls_ret_28 = ls_ret_28 + "LTD_Line (" + DoubleToStr(ld_68, l_count_24) + "), Possible downbreak.\n";
      l_highest_20 = iHighest(NULL, 0, MODE_HIGH, ai_4, 0);
      ld_44 = High[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      ld_52 = Close[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      l_highest_20 = iHighest(NULL, 0, MODE_CLOSE, ai_4, 0);
      ld_60 = Close[l_highest_20] - (Low[ai_4] + ld_36 * (ai_4 - l_highest_20));
      l_style_76 = TrendLineStyle;
   }
   ObjectSet("LL_" + ai_8, OBJPROP_STYLE, l_style_76);
   ls_ret_28 = ls_ret_28 + "TP1=" + DoubleToStr(ld_68 - ld_44, l_count_24) + " (" + DoubleToStr(ld_44 / Point, 0) + "pts.)\n";
   ObjectSet("LC1_" + ai_8, OBJPROP_TIME1, Time[ai_0]);
   ObjectSet("LC1_" + ai_8, OBJPROP_TIME2, Time[0]);
   ObjectSet("LC1_" + ai_8, OBJPROP_PRICE1, ld_68 - ld_44);
   ObjectSet("LC1_" + ai_8, OBJPROP_PRICE2, ld_68 - ld_44);
   ObjectSet("LC1_" + ai_8, OBJPROP_COLOR, a_color_12);
   ObjectSet("LC1_" + ai_8, OBJPROP_STYLE, l_style_76);
   if (ai_8 == 1) {
      ObjectSet("LC1_" + ai_8, OBJPROP_WIDTH, ProjectionLinesWidth);
      ObjectSet("LC1_" + ai_8, OBJPROP_STYLE, ProjectionLinesStyle);
   } else ObjectSet("LC1_" + ai_8, OBJPROP_WIDTH, 2);
   return (ls_ret_28);
}

string TDMain(int ai_0) {
   int li_32;
   double ld_36;
   double lda_44[20];
   string ls_ret_20 = "---   step " + ai_0 + "   --------------------\n";
   while (NormalizeDouble(Point, li_32) == 0.0) li_32++;
   lda_44[0] = UpperProjectionLineColour;
   lda_44[2] = 16711935;
   lda_44[4] = 1993170;
   lda_44[6] = 2139610;
   lda_44[8] = 13458026;
   lda_44[1] = LowerProjectionLineColour;
   lda_44[3] = 2237106;
   lda_44[5] = 32768;
   lda_44[7] = 13850042;
   lda_44[9] = 15570276;
   lda_44[10] = 255;
   lda_44[12] = 16711935;
   lda_44[14] = 1993170;
   lda_44[16] = 2139610;
   lda_44[18] = 13458026;
   lda_44[11] = 16711680;
   lda_44[13] = 2237106;
   lda_44[15] = 32768;
   lda_44[17] = 13850042;
   lda_44[19] = 15570276;
   ai_0 += gi_148;
   int li_4 = GetHighTD(ai_0);
   int li_8 = GetNextHighTD(li_4);
   int li_12 = GetLowTD(ai_0);
   int li_16 = GetNextLowTD(li_12);
   gd_160 = High[li_8] - (High[li_8] - High[li_4]) / (li_8 - li_4) * li_8;
   gd_172 = Low[li_16] + (Low[li_12] - Low[li_16]) / (li_16 - li_12) * li_16;
   if (li_4 < 0) ls_ret_20 = ls_ret_20 + "UTD no TD up-point \n";
   else {
      if (li_8 < 0) ls_ret_20 = ls_ret_20 + "UTD no TD point-upper then last one (" + DoubleToStr(High[li_4], li_32) + ")\n";
      else {
         ls_ret_20 = ls_ret_20 + "UTD " + DoubleToStr(High[li_8], li_32) + "  " + DoubleToStr(High[li_4], li_32) 
         + "\n";
      }
   }
   if (li_12 < 0) ls_ret_20 = ls_ret_20 + "LTD no TD down-point \n";
   else {
      if (li_16 < 0) ls_ret_20 = ls_ret_20 + "LTD no TD point-lower then last one (" + DoubleToStr(Low[li_12], li_32) + ")\n";
      else {
         ls_ret_20 = ls_ret_20 + "LTD  " + DoubleToStr(Low[li_16], li_32) + "  " + DoubleToStr(Low[li_12], li_32) 
         + "\n";
      }
   }
   if (ai_0 == 1) ld_36 = 0;
   else ld_36 = 2;
   if (li_4 > 0 && li_8 > 0) {
      if (TrendLine == TRUE) {
         ObjectCreate("HL_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         TrendLineHighTD(li_4, li_8, ai_0, lda_44[ai_0 * 2 - 2]);
      } else ObjectDelete("HL_" + ai_0);
      if (HorizontLine == TRUE && ai_0 == 1) {
         ObjectCreate("HHL_" + ai_0, OBJ_HLINE, 0, 0, 0, 0, 0);
         ObjectSet("HHL_" + ai_0, OBJPROP_BACK, TRUE);
         HorizontLineHighTD(li_4, li_8, ai_0, ld_36, lda_44[ai_0 * 2 - 2]);
      } else ObjectDelete("HHL_" + ai_0);
      if (ProjectionLines == TRUE) {
         ObjectCreate("HC1_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectCreate("HC2_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectCreate("HC3_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ls_ret_20 = ls_ret_20 + TakeProfitHighTD(li_4, li_8, ai_0, lda_44[ai_0 * 2 - 2]);
      } else {
         ObjectDelete("HC1_" + ai_0);
         ObjectDelete("HC2_" + ai_0);
         ObjectDelete("HC3_" + ai_0);
      }
   }
   if (li_12 > 0 && li_16 > 0) {
      if (TrendLine == TRUE) {
         ObjectCreate("LL_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         TrendLineLowTD(li_12, li_16, ai_0, lda_44[ai_0 * 2 - 1]);
      } else ObjectDelete("LL_" + ai_0);
      if (HorizontLine == TRUE && ai_0 == 1) {
         ObjectCreate("HLL_" + ai_0, OBJ_HLINE, 0, 0, 0, 0, 0);
         ObjectSet("HLL_" + ai_0, OBJPROP_BACK, TRUE);
         HorizontLineLowTD(li_12, li_16, ai_0, ld_36, lda_44[ai_0 * 2 - 1]);
      } else ObjectDelete("HLL_" + ai_0);
      if (ProjectionLines == TRUE) {
         ObjectCreate("LC1_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectCreate("LC2_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectCreate("LC3_" + ai_0, OBJ_TREND, 0, 0, 0, 0, 0);
         ls_ret_20 = ls_ret_20 + TakeProfitLowTD(li_12, li_16, ai_0, lda_44[ai_0 * 2 - 1]);
      } else {
         ObjectDelete("LC1_" + ai_0);
         ObjectDelete("LC2_" + ai_0);
         ObjectDelete("LC3_" + ai_0);
      }
   }
   if (AlertsOn) {
      if (Close[0] > gd_160 && gi_168 == FALSE) {
         Alert("UTL Break>", gd_160, " on ", Symbol(), " ", Period(), " @ ", Bid);
         gi_168 = TRUE;
      }
      if (Close[0] < gd_172 && gi_180 == FALSE) {
         Alert("LTL Break<", gd_172, " on ", Symbol(), " ", Period(), " @ ", Bid);
         gi_180 = TRUE;
      }
   }
   return (ls_ret_20);
}

int start() {
   if (ChecarValidadeConta(0, gi_76, gi_80, gs_84)) return (0);
   string ls_0 = "";
   SetTDPoint(Bars - 1);
   if (gi_144 == TRUE) {
      SetIndexArrow(0, 217);
      SetIndexArrow(1, 218);
   } else {
      SetIndexArrow(0, 160);
      SetIndexArrow(1, 160);
   }
   if (gi_152 > 10) {
      Comment("ShowingSteps readings 0 - 10");
      return (0);
   }
   for (int li_8 = 1; li_8 <= gi_152; li_8++) ls_0 = ls_0 + TDMain(li_8);
   ls_0 = ls_0 + "------------------------------------\nShowingSteps=" + gi_152 
   + "\nBackSteps=" + gi_148;
   if (gi_156 == TRUE) {
      ls_0 = ls_0 
      + "\nFractals";
   } else {
      ls_0 = ls_0 
      + "\nTD point";
   }
   if (Comments == TRUE) Comment(ls_0);
   else Comment("");
   return (0);
}

bool ChecarValidadeConta(int ai_0, int ai_4, int ai_8, string as_12) {
   int l_datetime_20 = TimeCurrent();
   int l_str2time_24 = StrToTime(as_12);
   if (l_datetime_20 >= l_str2time_24) {
      Comment("TINY-TRENDLINE HAS BEEN EXPIRED");
      ObjectsDeleteAll();
      return (TRUE);
   }
   if (!ai_4 && IsDemo()) return (TRUE);
   if (!IsDemo() && AccountNumber() != ai_8) return (FALSE);
   if (ai_0 != 0) {
      if (Period() != ai_0) {
         Comment(" -- Periodo Incorreto --");
         return (TRUE);
      }
      Comment(" -- Working --");
   }
   return (FALSE);
}
