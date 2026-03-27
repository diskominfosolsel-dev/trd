#property copyright "Copyright © 2010, SlumDog"
#property link      "http://www.slumdog.planet.ee"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Yellow
#property indicator_color2 Red
#property indicator_color3 Black

extern int MagaPeriod = 80;
extern int Smoothing = 5;
extern int Mode = 2;
extern int Price = 0;
double g_ibuf_92[];
double g_ibuf_96[];
double g_ibuf_100[];
double gda_unused_104[];
double gda_unused_108[];
double gda_unused_112[];
double g_ibuf_116[];
double g_ibuf_120[];
int gi_124;
string gs_dummy_128;
string gs_dummy_136;
int gi_unused_144 = 0;

int init() {
   IndicatorBuffers(8);
   SetIndexBuffer(0, g_ibuf_100);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(1, g_ibuf_96);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(2, g_ibuf_92);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexBuffer(3, g_ibuf_116);
   SetIndexBuffer(4, g_ibuf_120);
   IndicatorShortName("SD_Ma_slow");
   return (0);
}

int start() {
   gi_124 = Bars - IndicatorCounted();
   showMAGA();
   return (0);
}

void showMAGA() {
   for (int li_0 = gi_124; li_0 >= 0; li_0--) g_ibuf_116[li_0] = 2.0 * iMA(NULL, 0, MagaPeriod / 2, 0, Mode, Price, li_0) - iMA(NULL, 0, MagaPeriod, 0, Mode, Price, li_0);
   for (li_0 = gi_124; li_0 >= 0; li_0--) g_ibuf_120[li_0] = iMAOnArray(g_ibuf_116, 0, Smoothing, 0, Mode, li_0);
   for (li_0 = gi_124; li_0 >= 0; li_0--) {
      g_ibuf_92[li_0] = g_ibuf_120[li_0];
      g_ibuf_96[li_0] = g_ibuf_120[li_0];
      g_ibuf_100[li_0] = g_ibuf_120[li_0];
      if (g_ibuf_120[li_0] > g_ibuf_120[li_0 + 1]) g_ibuf_96[li_0] = EMPTY_VALUE;
      else {
         if (g_ibuf_120[li_0] < g_ibuf_120[li_0 + 1]) g_ibuf_92[li_0] = EMPTY_VALUE;
         else {
            g_ibuf_92[li_0] = EMPTY_VALUE;
            g_ibuf_96[li_0] = EMPTY_VALUE;
         }
      }
   }
}